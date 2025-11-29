import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // TODO: change this to your PC's IP address
  static const String baseUrl = "http://192.168.0.2:3000";

  Future<List<dynamic>> getSpots() async {
    final response = await http.get(Uri.parse("$baseUrl/spots"));
    final data = jsonDecode(response.body);
    return data["spots"];
  }

  Future<Map<String, dynamic>> reserveSpot(int userId, int spotId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/reserve"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userId": userId, "spotId": spotId}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name, "email": email, "password": password}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );
    return jsonDecode(response.body);
  }
}
