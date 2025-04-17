import 'dart:convert';

import 'package:http/http.dart' as http;

const apiUrl = 'https://screentime-api.prod.appadem.in';
// const apiUrl = 'http://192.168.0.23:8090';

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

  if (response.statusCode == 200) {
    return true;
  } else {
    throw Exception('Failed to upload data');
  }
}
