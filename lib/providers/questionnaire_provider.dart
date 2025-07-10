import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screen_time/api.dart';

final questionnaireProvider =
    FutureProvider<List<Questionnaire>>((ref) => fetchQuestionnaires());
