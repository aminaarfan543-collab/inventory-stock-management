import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Api {
  // Chrome (web) ke liye localhost use karein
  // Android emulator ke liye 10.0.2.2 use karein
  // Real phone ke liye apne computer ka LAN IP use karein (jaise 192.168.1.50)
  static const baseUrl = 'http://192.168.100.10/inventory-api/';

  static String? token;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
  }

  static Future<void> saveToken(String value) async {
    token = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', value);
  }

  static Future<void> logout() async {
    token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<Map<String, dynamic>> request(
    String action, {
    String method = 'GET',
    Map<String, dynamic>? data,
    Map<String, String>? query,
    bool publicRequest = false,
  }) async {
    final uri = Uri.parse(
      baseUrl,
    ).replace(queryParameters: {'action': action, ...?query});

    final headers = {
      'Content-Type': 'application/json',
      if (!publicRequest && token != null) 'Authorization': 'Bearer $token',
    };

    late http.Response response;

    try {
      if (method == 'GET') {
        response = await http.get(uri, headers: headers);
      } else if (method == 'PUT') {
        response = await http.put(
          uri,
          headers: headers,
          body: jsonEncode(data ?? {}),
        );
      } else if (method == 'DELETE') {
        response = await http.delete(uri, headers: headers);
      } else {
        response = await http.post(
          uri,
          headers: headers,
          body: jsonEncode(data ?? {}),
        );
      }
    } catch (e) {
      // Network error ko readable message mein convert karein
      throw Exception('Failed to connect: $e');
    }

    final result = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 400 || result['success'] != true) {
      throw Exception(result['message'] ?? 'API error');
    }

    return result;
  }
}
