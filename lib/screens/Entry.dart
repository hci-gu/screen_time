import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart' as html_parser;
import '../api.dart';
import '../providers/user_provider.dart';
import '../widgets/question_widget.dart';

class NewEntryPage extends ConsumerStatefulWidget {
  final Questionnaire questionnaire;

  const NewEntryPage({
    super.key,
    required this.questionnaire,
  });

  @override
  ConsumerState<NewEntryPage> createState() => _NewEntryPageState();
}

class _NewEntryPageState extends ConsumerState<NewEntryPage> {
  final Map<String, dynamic> _answers = {};
  bool _showLastDayQuestions = false;

  void _onAnswered(String questionId, dynamic value) {
    setState(() {
      _answers[questionId] = value;
    });
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
    final userId = ref.read(userIdProvider);
    if (userId == null || userId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fel: Kunde inte hitta användar-ID.')),
        );
      }
      return;
    }

    final allAnswers = _collectAllAnswersForSubmit();

    bool success = await answerQuestionnaire(
      userId,
      widget.questionnaire.id,
      allAnswers,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(success ? 'Svar sparade!' : 'Kunde inte spara svar.')),
      );
      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  List<Question> _filterQuestions(List<Question> questions,
      {bool includeLastDay = false}) {
    List<Question> filtered = [];
    for (final q in questions) {
      final isLastDay = (q as dynamic).lastDay == true;
      if (!isLastDay || includeLastDay) {
        final filteredSubs =
            _filterQuestions(q.subQuestions, includeLastDay: includeLastDay);
        filtered.add(
          Question(
            id: q.id,
            name: q.name,
            text: q.text,
            type: q.type,
            showWhenParentIs: q.showWhenParentIs,
            options: q.options,
            subQuestions: filteredSubs,
          ),
        );
      }
    }
    return filtered;
  }

  bool get _hasLastDayQuestions {
    bool found = false;
    void check(List<Question> questions) {
      for (final q in questions) {
        if ((q as dynamic).lastDay == true) {
          found = true;
          return;
        }
        check(q.subQuestions);
      }
    }

    check(widget.questionnaire.questions);
    return found;
  }

  @override
  Widget build(BuildContext context) {
    final visibleQuestions = _showLastDayQuestions
        ? widget.questionnaire.questions
        : _filterQuestions(widget.questionnaire.questions,
            includeLastDay: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nytt dagboksinlägg'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: visibleQuestions.length + (_hasLastDayQuestions ? 3 : 2),
        itemBuilder: (context, index) {
          if (index < visibleQuestions.length) {
            final question = visibleQuestions[index];
            return QuestionWidget(
              question: question,
              onAnswered: _onAnswered,
              answers: _answers,
            );
          } else if (_hasLastDayQuestions && index == visibleQuestions.length) {
            if (_showLastDayQuestions) return const SizedBox(height: 0);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.lock_open),
                label: const Text('Visa frågor för sista dagen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade100,
                  foregroundColor: Colors.orange.shade900,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  setState(() {
                    _showLastDayQuestions = true;
                  });
                },
              ),
            );
          } else if (index ==
              visibleQuestions.length + (_hasLastDayQuestions ? 1 : 0)) {
            return const SizedBox(height: 24);
          } else {
            return ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: const Text('Skicka'),
            );
          }
        },
      ),
    );
  }
}
