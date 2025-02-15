// services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

class ApiService {
  static const String baseUrl =
      'http://127.0.0.1:5000'; // Replace with your API endpoint

  static Future<Map<String, dynamic>> sendDrawing(
      List<int> imageBytes, String prompt) async {
    try {
      // Convert image bytes to base64
      FormData formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(imageBytes, filename: 'drawing.png'),
        'prompt': prompt,
        'timestamp': DateTime.now().toIso8601String(),
      });

      final response = await Dio().post(
        '$baseUrl/predict_drawing',
        data: formData,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.data);
      } else {
        throw Exception('Failed to process drawing: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending drawing: $e');
    }
  }

  static Future<String> fetchRecommendedLabel() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/recommend_label'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['recommended_label'];
      } else {
        return "Failed to fetch";
      }
    } catch (e) {
      return "Error fetching data";
    }
  }

  static Future<int> getProficiencyPoint(
      int time, String confidence, int currPoint) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update_proficiency'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'time': time,
          'confidence': confidence,
          'current_level': currPoint,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        return responseData['action'] as int;
      } else {
        throw Exception(
            'Failed to get proficiency points: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error calculating proficiency points: $e');
    }
  }

  static Future<int> getProficiencyPointForMulitPlayerSetting(
      int time, int currPoint) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update_proficiency_for_multiplayer'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'time': time,
          'currPoint': currPoint,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        return responseData['action'] as int;
      } else {
        throw Exception(
            'Failed to get proficiency points: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error calculating proficiency points: $e');
    }
  }
}
