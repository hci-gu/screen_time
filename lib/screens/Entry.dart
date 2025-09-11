import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_time/theme/app_theme.dart';
import 'package:html/parser.dart' as html_parser;
import '../api.dart';
import '../providers/user_provider.dart';
import '../utils/network_utils.dart';
import '../widgets/question_widget.dart';

class NewEntryPage extends ConsumerStatefulWidget {
  final Questionnaire questionnaire;
  final DateTime? initialDate;

  const NewEntryPage({
    super.key,
    required this.questionnaire,
    this.initialDate,
  });

  @override
  ConsumerState<NewEntryPage> createState() => _NewEntryPageState();
}

class _NewEntryPageState extends ConsumerState<NewEntryPage> {
  final Map<String, dynamic> _answers = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      final dateQuestion = widget.questionnaire.questions.firstWhere(
        (q) => q.type == 'date' || q.name.toLowerCase().contains('date'),
        orElse: () => Question(
          id: '',
          name: '',
          text: '',
          type: '',
          showWhenParentIs: null,
          options: [],
          subQuestions: [],
        ),
      );
      if (dateQuestion.id.isNotEmpty) {
        _answers[dateQuestion.id] = widget.initialDate!.toIso8601String();
      }
    }
  }

  void _onAnswered(String questionId, dynamic value) {
    setState(() {
      _answers[questionId] = value;
    });
  }

  List<Question> _getRegularQuestions() {
    return widget.questionnaire.questions;
  }

  Map<String, dynamic> _collectAllAnswersForSubmit() {
    final Map<String, dynamic> allAnswers = {};
    void collect(Question question) {
      if (_answers.containsKey(question.id)) {
        final answer = _answers[question.id];
        final plainText = html_parser.parse(question.text).body?.text ?? '';
        final Map<String, dynamic> answerMap = {
          'questionName': question.name,
          'questionText': plainText,
        };
        if ((question.type == 'yesNo' || question.type == 'singleChoice') &&
            answer != null) {
          final selectedOption = question.options.firstWhere(
            (opt) => opt.id == answer.toString(),
            orElse: () => AnswerOption(id: '', displayText: '', valueText: ''),
          );
          answerMap['value'] = answer;
          answerMap['valueText'] = selectedOption.valueText ?? '';
        } else if (question.type == 'slider' && answer != null) {
          final selectedOption = question.options.firstWhere(
            (opt) =>
                opt.valueNumber != null &&
                opt.valueNumber.toString() == answer.toString(),
            orElse: () => AnswerOption(
                id: '', displayText: '', valueText: '', valueNumber: null),
          );
          answerMap['value'] = answer;
          answerMap['valueText'] =
              selectedOption.valueText ?? answer.toString();
        } else {
          answerMap['value'] = answer;
        }
        allAnswers[question.id] = answerMap;
      }
      for (final sub in question.subQuestions) {
        collect(sub);
      }
    }

    for (final q in widget.questionnaire.questions) {
      collect(q);
    }
    return allAnswers;
  }

  Future<void> _submitForm() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final hasNetwork = await NetworkUtils.hasNetworkConnection();
      if (!hasNetwork) {
        setState(() {
          _isSubmitting = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ingen internetanslutning. Internetanslutning krävs för att skicka dina svar.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Color.fromARGB(255, 255, 152, 0),
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      final userState = ref.read(userIdProvider);
      final userId = userState.userId;
      if (userId == null || userId.isEmpty) {
        setState(() {
          _isSubmitting = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.person_off, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Fel: Kunde inte hitta användar-ID.'),
                ],
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final allAnswers = _collectAllAnswersForSubmit();

      bool success = await answerQuestionnaire(
        userId,
        widget.questionnaire.id,
        allAnswers,
        customDate: widget.initialDate,
      );

      setState(() {
        _isSubmitting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check : Icons.error_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(success ? 'Svar sparade!' : 'Kunde inte spara svar.'),
              ],
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        final isNetworkError = NetworkUtils.isNetworkError(e);
        final errorMessage = NetworkUtils.getErrorMessage(e,
            customNetworkMessage:
                'Internetanslutningen bröts under skickandet. Kontrollera din anslutning och försök igen.');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isNetworkError ? Icons.wifi_off : Icons.error_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: isNetworkError
                ? const Color.fromARGB(255, 255, 152, 0)
                : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final regularQuestions = _getRegularQuestions();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Nytt dagboksinlägg',
            style: TextStyle(color: AppTheme.primary)),
        backgroundColor: AppTheme.background,
        surfaceTintColor: AppTheme.background,
        elevation: 1,
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: _buildQuestionsList(regularQuestions),
        ),
      ),
    );
  }

  Widget _buildQuestionsList(List<Question> questions) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: questions.length + 1,
      itemBuilder: (context, index) {
        if (index < questions.length) {
          final question = questions[index];
          return QuestionWidget(
            question: question,
            onAnswered: _onAnswered,
            answers: _answers,
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.background,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle:
                    const TextStyle(fontSize: 16, color: AppTheme.background),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: AppTheme.background,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Skicka'),
            ),
          );
        }
      },
    );
  }
}
