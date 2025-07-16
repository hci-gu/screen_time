import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart' as html_parser;
import '../api.dart';
import '../widgets/question_widget.dart';

class EntryDetailPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> entry;
  const EntryDetailPage({super.key, required this.entry});

  @override
  ConsumerState<EntryDetailPage> createState() => _EntryDetailPageState();
}

class _EntryDetailPageState extends ConsumerState<EntryDetailPage> {
  bool _editing = false;
  late Map<String, dynamic> _answers;
  final Map<String, dynamic> _editAnswers = {};

  Questionnaire? _questionnaire;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _answers = Map<String, dynamic>.from(widget.entry['data'] ?? {});
    _loadQuestionnaire();
  }

  Future<void> _loadQuestionnaire() async {
    final questionnaireId = widget.entry['questionnaire'];
    if (questionnaireId == null || questionnaireId.isEmpty) {
      setState(() {
        _error = 'Kunde inte hitta formulär-ID i posten.';
        _isLoading = false;
      });
      return;
    }

    try {
      final questionnaire = await fetchQuestionnaireById(questionnaireId);
      if (mounted) {
        setState(() {
          _questionnaire = questionnaire;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Formulärstrukturen kunde inte läsas in.';
          _isLoading = false;
        });
      }
    }
  }

  void _onAnswered(String questionId, dynamic value) {
    setState(() {
      _editAnswers[questionId] = value;

      final question = _findQuestionById(questionId);
      if (question == null) return;

      if (_answers[questionId] == null) {
        final plainText = html_parser.parse(question.text).body?.text ?? '';
        _answers[questionId] = {
          'questionName': question.name,
          'questionText': plainText,
        };
      }

      if (_answers[questionId] is Map<String, dynamic>) {
        final answerMap = _answers[questionId];
        answerMap['value'] = value;

        if ((question.type == 'yesNo' || question.type == 'singleChoice') &&
            value != null) {
          final selectedOption = question.options.firstWhere(
            (opt) => opt.id == value.toString(),
            orElse: () => AnswerOption(id: '', displayText: '', valueText: ''),
          );
          answerMap['valueText'] =
              selectedOption.valueText ?? selectedOption.displayText;
        } else if (question.type == 'slider' && value != null) {
          final int index = (value as num).round() - 1;
          if (index >= 0 && index < question.options.length) {
            answerMap['valueText'] = question.options[index].displayText;
          } else {
            answerMap['valueText'] = value.toString();
          }
        } else {
          answerMap['valueText'] = value?.toString() ?? '';
        }
      }
    });
  }

  Question? _findQuestionById(String questionId) {
    if (_questionnaire == null) return null;

    Question? searchInQuestions(List<Question> questions) {
      for (final question in questions) {
        if (question.id == questionId) return question;
        final found = searchInQuestions(question.subQuestions);
        if (found != null) return found;
      }
      return null;
    }

    return searchInQuestions(_questionnaire!.questions);
  }

  Future<void> _saveChanges() async {
    final answerId = widget.entry['id'];
    if (answerId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fel: Kunde inte hitta svar-ID.')),
        );
      }
      return;
    }

    try {
      bool success = await editAnswer(answerId, _answers);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                success ? 'Ändringar sparade!' : 'Kunde inte spara ändringar.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (success) {
          setState(() {
            _editing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fel vid sparande: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionnaireName = _questionnaire?.name ??
        widget.entry['expand']?['questionnaire']?['name'] ??
        'Formulär';
    final date = (widget.entry['date'] ?? widget.entry['created'])
        ?.toString()
        .replaceFirst('T', ' ')
        .substring(0, 16);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(questionnaireName),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        actions: _editing
            ? [
                IconButton(
                  icon: const Icon(Icons.cancel_outlined),
                  tooltip: 'Avbryt',
                  onPressed: () {
                    setState(() {
                      _editing = false;
                      _answers =
                          Map<String, dynamic>.from(widget.entry['data'] ?? {});
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.save_alt_outlined),
                  tooltip: 'Spara',
                  onPressed: _saveChanges,
                ),
              ]
            : [
                if (!_isLoading && _error == null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Redigera',
                    onPressed: () {
                      setState(() {
                        _editing = true;
                        _editAnswers.clear();
                        _answers.forEach((key, value) {
                          if (value is Map<String, dynamic> &&
                              value.containsKey('value')) {
                            _editAnswers[key] = value['value'];
                          }
                        });
                      });
                    },
                  ),
              ],
      ),
      body: _buildBody(date),
    );
  }

  Widget _buildBody(String? date) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade700, fontSize: 16),
          ),
        ),
      );
    }
    return _editing ? _buildEditView() : _buildDisplayView(date);
  }

  Widget _buildDisplayView(String? date) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      children: [
        Card(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          margin: const EdgeInsets.only(bottom: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: Icon(Icons.calendar_today_outlined,
                color: Theme.of(context).primaryColor),
            title: const Text('Ifyllt datum',
                style: TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(date ?? 'Okänt datum'),
          ),
        ),
        ..._buildRecursiveAnswerDisplay(_questionnaire!.questions),
      ],
    );
  }

  Widget _buildEditView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      children: _questionnaire!.questions.map((question) {
        return QuestionWidget(
          question: question,
          onAnswered: _onAnswered,
          answers: _editAnswers,
        );
      }).toList(),
    );
  }

  List<Widget> _buildRecursiveAnswerDisplay(List<Question> questions,
      {int level = 0}) {
    List<Widget> widgets = [];
    for (final question in questions) {
      final answerData = _answers[question.id];
      final parentAnswerValue = answerData?['value']?.toString();
      final visibleSubQuestions = question.subQuestions.where((sub) {
        return sub.showWhenParentIs == null ||
            sub.showWhenParentIs == parentAnswerValue;
      }).toList();

      final hasVisibleSubAnswers = visibleSubQuestions.any(
          (sub) => _answers.containsKey(sub.id) || sub.type == 'groupHeader');

      if (question.type == 'groupHeader' && hasVisibleSubAnswers) {
        widgets.add(_buildGroupHeader(question, level: level));
      } else {
        final hasAnswer = answerData != null &&
            (answerData['value']?.toString() ?? '').isNotEmpty;
        if (hasAnswer) {
          final questionText = answerData['questionText'] ??
              (html_parser.parse(question.text).body?.text ?? '');
          final answerText = answerData['valueText']?.isNotEmpty == true
              ? answerData['valueText']
              : answerData['value']?.toString() ?? 'Inget svar';
          widgets.add(_buildAnswerCard(questionText, answerText, level: level));
        }
      }

      if (visibleSubQuestions.isNotEmpty) {
        widgets.addAll(_buildRecursiveAnswerDisplay(visibleSubQuestions,
            level: level + 1));
      }
    }
    return widgets;
  }

  Widget _buildGroupHeader(Question question, {required int level}) {
    return Padding(
      padding: EdgeInsets.only(
        left: 12.0 * level,
        top: 24,
        bottom: 8,
        right: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            html_parser.parse(question.text).body?.text ?? '',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const Divider(height: 16, thickness: 1),
        ],
      ),
    );
  }

  Widget _buildAnswerCard(String questionText, String answerText,
      {required int level}) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: EdgeInsets.only(left: 12.0 * level, bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: IntrinsicHeight(
        child: Row(
          children: [
            if (level > 0)
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.2),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      questionText,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      answerText,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
