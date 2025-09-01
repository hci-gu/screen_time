import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';

const apiUrl = 'https://screentime-api.prod.appadem.in';
// const apiUrl = 'http://192.168.0.23:8090';

final pb = PocketBase(apiUrl);

Future checkUserId(String userId) async {
  final response = await http.get(
    Uri.parse("$apiUrl/users/$userId"),
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode == 200) {
    return true;
  } else if (response.statusCode == 404) {
    return false;
  } else {
    throw Exception('Failed to check user ID');
  }
}

Future<void> setUserStartDateIfMissing(String userId) async {
  try {
    final user = await pb.collection('users').getOne(userId);
    if (user.data['startDate'] == null ||
        user.data['startDate'].toString().isEmpty) {
      await pb.collection('users').update(userId, body: {
        'startDate': DateTime.now().toIso8601String(),
      });
    }
  } catch (e) {
    throw Exception('Error setting user start date: $e');
  }
}

Future<DateTime?> fetchUserStartDate(String userId) async {
  try {
    final user = await pb.collection('users').getOne(userId);
    final startDateStr = user.data['startDate']?.toString();
    if (startDateStr != null && startDateStr.isNotEmpty) {
      return DateTime.tryParse(startDateStr);
    }
  } catch (e) {
    // ignorera error
  }
  return null;
}

Future<bool> uploadData(String userId, Map<String, dynamic> usageData) async {
  final response = await http.post(
    Uri.parse("$apiUrl/users/$userId/upload"),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(usageData),
  );

  if (response.statusCode == 200) {
    return true;
  } else {
    throw Exception('Failed to upload data');
  }
}

Future<bool> answerQuestionnaire(
    String userId, String questionnaireId, Map<String, dynamic> answers,
    {DateTime? customDate}) async {
  try {
    final body = {
      'user': userId,
      'questionnaire': questionnaireId,
      'data': answers,
      'date': (customDate ?? DateTime.now()).toIso8601String(),
    };
    print('answerQuestionnaire: body to send:');
    print(body);
    await pb.collection('answers').create(body: body);
    print('answerQuestionnaire: sent successfully');
    return true;
  } catch (e) {
    print('answerQuestionnaire: error: $e');
    throw Exception('Error answering questionnaire: $e');
  }
}

Future<List<Map<String, dynamic>>> fetchUserAnswers(String userId) async {
  try {
    final result = await pb.collection('answers').getFullList(
          filter: "user = '$userId'",
          sort: '-created',
          expand: 'questionnaire',
        );

    return result.map((item) => item.toJson()).toList();
  } catch (e) {
    return [];
  }
}

Future<bool> editAnswer(
  String answerId,
  Map<String, dynamic> answers,
) async {
  try {
    await pb.collection('answers').update(answerId, body: {
      'data': answers,
    });
    return true;
  } catch (e) {
    throw Exception('Error answering questionnaire: $e');
  }
}

Future<List<Questionnaire>> fetchQuestionnaires() async {
  final result = await pb.collection('questionnaires').getFullList(
        sort: '-created',
        expand: 'questions,'
            'questions.options,'
            'questions.subQuestions,'
            'questions.subQuestions.options,'
            'questions.subQuestions.subQuestions,'
            'questions.subQuestions.subQuestions.options',
      );

  if (result.isEmpty) {
    return [];
  }

  return result.map((item) => Questionnaire.fromJson(item.toJson())).toList();
}

Future<Questionnaire> fetchQuestionnaireById(String questionnaireId) async {
  try {
    final record = await pb.collection('questionnaires').getOne(
          questionnaireId,
          expand: 'questions,'
              'questions.options,'
              'questions.subQuestions,'
              'questions.subQuestions.options,'
              'questions.subQuestions.subQuestions,'
              'questions.subQuestions.subQuestions.options',
        );
    return Questionnaire.fromJson(record.toJson());
  } catch (e) {
    throw Exception('Could not fetch questionnaire structure.');
  }
}

class AnswerOption {
  final String id;
  final String displayText;
  final num? valueNumber;
  final String? valueText;

  AnswerOption({
    required this.id,
    required this.displayText,
    this.valueNumber,
    this.valueText,
  });

  factory AnswerOption.fromJson(Map<String, dynamic> json) {
    return AnswerOption(
      id: json['id'],
      displayText: json['displayText'] ?? 'Namnlöst alternativ',
      valueNumber: json['valueNumber'],
      valueText: json['valueText'],
    );
  }
}

class Question {
  final String id;
  final String name;
  final String text;
  final String type;
  final String? showWhenParentIs;
  final List<AnswerOption> options;
  final List<Question> subQuestions;
  final bool lastDay;

  Question({
    required this.id,
    required this.name,
    required this.text,
    required this.type,
    this.showWhenParentIs,
    this.options = const [],
    this.subQuestions = const [],
    this.lastDay = false,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final expand = json['expand'] as Map<String, dynamic>? ?? {};

    final optionsData = expand['options'] as List<dynamic>? ?? [];
    final options =
        optionsData.map((data) => AnswerOption.fromJson(data)).toList();

    final subQuestionsData = expand['subQuestions'] as List<dynamic>? ?? [];
    final subQuestions =
        subQuestionsData.map((data) => Question.fromJson(data)).toList();

    return Question(
      id: json['id'],
      name: json['name'] ?? '',
      text: json['text'] ?? '',
      type: json['type'] ?? 'freeText',
      showWhenParentIs:
          json['showWhenParentIs'] == '' ? null : json['showWhenParentIs'],
      options: options,
      subQuestions: subQuestions,
      lastDay: json['lastDay'] == true,
    );
  }
}

class Questionnaire {
  final String id;
  final String name;
  final List<Question> questions;

  Questionnaire({
    required this.id,
    required this.name,
    required this.questions,
  });

  factory Questionnaire.fromJson(Map<String, dynamic> json) {
    final expand = json['expand'] as Map<String, dynamic>? ?? {};
    final questionsData = expand['questions'] as List<dynamic>? ?? [];

    final allQuestions =
        questionsData.map((q) => Question.fromJson(q)).toList();

    final Set<String> subQuestionIds = {};
    void collectSubQuestionIds(List<Question> questions) {
      for (final q in questions) {
        for (final sub in q.subQuestions) {
          subQuestionIds.add(sub.id);

          if (sub.subQuestions.isNotEmpty) {
            collectSubQuestionIds(sub.subQuestions);
          }
        }
      }
    }

    collectSubQuestionIds(allQuestions);

    final topLevelQuestions =
        allQuestions.where((q) => !subQuestionIds.contains(q.id)).toList();

    topLevelQuestions.sort((a, b) {
      final aNum = int.tryParse(a.name);
      final bNum = int.tryParse(b.name);
      if (aNum != null && bNum != null) {
        return aNum.compareTo(bNum);
      }
      return a.name.compareTo(b.name);
    });

    return Questionnaire(
      id: json['id'],
      name: json['name'] ?? 'Okänt formulär',
      questions: topLevelQuestions,
    );
  }
}
