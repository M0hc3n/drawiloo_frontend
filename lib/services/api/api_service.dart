// services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'http://127.0.0.1:5000'; // Replace with your API endpoint

  static Future<Map<String, dynamic>> sendDrawing(List<int> imageBytes) async {
    try {
      // Convert image bytes to base64
      String base64Image = base64Encode(imageBytes);

      // Create request body

      final body = jsonEncode({
        'image': base64Image,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Send POST request
      final response = await http.post(
        Uri.parse('$baseUrl/display_image'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
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
}
