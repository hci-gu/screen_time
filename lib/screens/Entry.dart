import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  void _onAnswered(String questionId, dynamic value) {
    setState(() {
      _answers[questionId] = value;
    });
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

    bool success = await answerQuestionnaire(
      userId,
      widget.questionnaire.id,
      _answers,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formulär'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ...widget.questionnaire.questions
              .map((question) => QuestionWidget(
                    question: question,
                    onAnswered: _onAnswered,
                    answers: _answers,
                  ))
              .toList(),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submitForm,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16),
            ),
            child: const Text('Skicka'),
          ),
        ],
      ),
    );
  }
}
