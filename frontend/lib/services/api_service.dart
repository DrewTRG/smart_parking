import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://192.168.0.2:3000";

  /* --------------------------------------------------------------
     PARKING SPOTS
  -------------------------------------------------------------- */

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

  /* --------------------------------------------------------------
     USERS: REGISTER + LOGIN
  -------------------------------------------------------------- */

  Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
      }),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );
    return jsonDecode(response.body);
  }

  /* --------------------------------------------------------------
     RESERVATIONS (ACTIVE)
  -------------------------------------------------------------- */

  Future<List<dynamic>> getUserReservations(int userId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/reservations/$userId"),
    );

    final data = jsonDecode(response.body);
    return data["reservations"] ?? [];
  }

  /* --------------------------------------------------------------
     CANCEL RESERVATION
  -------------------------------------------------------------- */

  Future<Map<String, dynamic>> cancelReservation(int reservationId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/cancel"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"reservationId": reservationId}),
    );

    return jsonDecode(response.body);
  }

  /* --------------------------------------------------------------
     COMPLETED HISTORY
  -------------------------------------------------------------- */

  Future<List<dynamic>> getHistory(int userId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/history/$userId"),
    );

    final data = jsonDecode(response.body);
    return data["history"] ?? [];
  }

  /* --------------------------------------------------------------
     MARK RESERVATION COMPLETED
  -------------------------------------------------------------- */

  Future<Map<String, dynamic>> completeReservation(int reservationId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/complete"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"reservationId": reservationId}),
    );

    return jsonDecode(response.body);
  }
}
