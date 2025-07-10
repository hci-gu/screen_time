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

Future<bool> uploadData(String userId, Map<String, dynamic> usageData) async {
  final response = await http.post(
    Uri.parse("$apiUrl/users/$userId/upload"),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(usageData),
  );

  print('Upload response status: ${response.statusCode}');
  print('Upload response body: ${response.body}');

  if (response.statusCode == 200) {
    return true;
  } else {
    throw Exception('Failed to upload data');
  }
}

Future<bool> answerQuestionnaire(
  String userId,
  String questionnaireId,
  Map<String, dynamic> answers,
) async {
  try {
    await pb.collection('answers').create(body: {
      'user': userId,
      'questionnaire': questionnaireId,
      'data': answers,
    });
    return true;
  } catch (e) {
    print('Error answering questionnaire: $e');
    return false;
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
    print('Error answering questionnaire: $e');
    return false;
  }
}

Future<List<Questionnaire>> fetchQuestionnaires() async {
  final result = await pb.collection('questionnaires').getFullList(
        expand: 'questions',
      );

  if (result.isEmpty) {
    return [];
  }

  return result.map((item) => Questionnaire.fromJson(item.toJson())).toList();
}

class Questionnaire {
  final String id;
  final List<Question> questions;

  Questionnaire({
    required this.id,
    required this.questions,
  });

  factory Questionnaire.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> questions = json['expand']['questions'] ?? [];

    return Questionnaire(
      id: json['id'],
      questions: questions.map((q) => Question.fromJson(q)).toList(),
    );
  }
}

enum QuestionType {
  text,
  number,
  singleChoice,
}

class Question {
  final String id;
  final String text;
  final QuestionType type;
  final List<Map<String, dynamic>> options;

  Question({
    required this.id,
    required this.text,
    required this.type,
    required this.options,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      text: 'json',
      type: QuestionType.values.firstWhere(
        (e) => e.toString() == 'QuestionType.${json['type']}',
        orElse: () => QuestionType.text,
      ),
      options: [],
      // options: List<Map<String, dynamic>>.from(json['options'] ?? []),
    );
  }
}
