import 'dart:async';
import 'package:flutter/material.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Parking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
    );
  }
}

/* -------------------------------------------------------
   LOGIN SCREEN
-------------------------------------------------------- */

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ApiService api = ApiService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool loading = false;

  void _doLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    setState(() => loading = true);

    final res = await api.login(email, password);

    setState(() => loading = false);

    if (res["success"] == true) {
      final int userId = res["userId"];
      final String name = res["name"];

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Welcome, $name")));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainMenuScreen(userId: userId)),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res["message"] ?? "Login failed")));
    }
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _doLogin,
                    child: const Text("Login"),
                  ),
            TextButton(
              onPressed: _goToRegister,
              child: const Text("No account? Register here"),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------
   REGISTER SCREEN
-------------------------------------------------------- */

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final ApiService api = ApiService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool loading = false;

  void _doRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => loading = true);

    final res = await api.register(name, email, password);

    setState(() => loading = false);

    if (res["success"] == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res["message"] ?? "Registered")));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["message"] ?? "Registration failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _doRegister,
                    child: const Text("Register"),
                  ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------
   MAIN MENU
-------------------------------------------------------- */
class MainMenuScreen extends StatefulWidget {
  final int userId;

  const MainMenuScreen({super.key, required this.userId});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Main Menu"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "logout") _logout();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: "logout", child: Text("Logout")),
            ],
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MallSelectionScreen(userId: widget.userId),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(14.0),
                child: Text("Reserve"),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ReservationListScreen(userId: widget.userId),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(14.0),
                child: Text("Reservations"),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HistoryScreen(userId: widget.userId),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(14.0),
                child: Text("History"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------
   MALL SELECTION
-------------------------------------------------------- */
class MallSelectionScreen extends StatelessWidget {
  final int userId;

  const MallSelectionScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Mall")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ParkingScreen(userId: userId, mallId: 1),
                  ),
                );
              },
              child: Text("Mall A"),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ParkingScreen(userId: userId, mallId: 2),
                  ),
                );
              },
              child: Text("Mall B"),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------
   PARKING SCREEN WITH PARKING MAP
-------------------------------------------------------- */

class ParkingScreen extends StatefulWidget {
  final int userId;
  final int mallId;

  const ParkingScreen({super.key, required this.userId, required this.mallId});

  @override
  State<ParkingScreen> createState() => _ParkingScreenState();
}

class _ParkingScreenState extends State<ParkingScreen> {
  final ApiService api = ApiService();
  List spots = [];
  bool loading = true;

  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadSpots(widget.mallId, showLoader: true);
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadSpots(widget.mallId);
      ;
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSpots(int mallId, {bool showLoader = false}) async {
    if (showLoader) {
      setState(() => loading = true);
    }

    try {
      final data = await api.getSpots(mallId);
      if (!mounted) return;

      setState(() {
        spots = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      print("Error loading spots: $e");
      setState(() => loading = false);
    }
  }

  Future<void> _reserve(int spotId) async {
    final res = await api.reserveSpot(widget.userId, spotId, widget.mallId);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Reserved')));

    _loadSpots(widget.mallId);
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Parking Spots"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadSpots(widget.mallId, showLoader: true),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "logout") {
                _logout();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: "logout", child: Text("Logout")),
            ],
          ),
        ],
      ),

      /* -------- PARKING MAP LAYOUT -------- */
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadSpots(widget.mallId),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // ----------- ENTRANCE (LEFT) -----------
                    Padding(
                      padding: const EdgeInsets.only(top: 30), // move it down
                      child: const _SideLabel(
                        title: "Entrance",
                        icon: Icons.arrow_forward,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // ----------- CENTER COLUMN: EXIT + GRID -----------
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // EXIT ICON AT TOP
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: _TopLabel(
                              title: "Exit",
                              icon: Icons.exit_to_app,
                            ),
                          ),

                          // PARKING GRID
                          Center(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.black,
                                  width: 2,
                                ),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 5,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      childAspectRatio: 1,
                                    ),
                                itemCount: spots.length,
                                itemBuilder: (context, index) {
                                  final s = spots[index];
                                  final isAvailable = s['isAvailable'] == 1;

                                  return GestureDetector(
                                    onTap: isAvailable
                                        ? () async {
                                            final reserved =
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        ConfirmationPage(
                                                          spotId: s['id'],
                                                          spotNumber:
                                                              s['spot_number'],
                                                        ),
                                                  ),
                                                );
                                            if (reserved == true) {
                                              _reserve(s['id']);
                                            }
                                          }
                                        : null,
                                    child: Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isAvailable
                                            ? Colors.green
                                            : Colors.red,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.black),
                                      ),
                                      child: Text(
                                        "P${s['spot_number']}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(top: 30), // same offset
                      child: const _SideLabel(
                        title: "Lift",
                        icon: Icons.elevator,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/* -------------------------------------------------------
   SIDE LABEL (Entrance / Lift)
-------------------------------------------------------- */

class _SideLabel extends StatelessWidget {
  final String title; // no longer used, but can keep for compatibility
  final IconData icon;

  const _SideLabel({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RotatedBox(
        quarterTurns: 0, // rotate icon clockwise 90 degrees
        child: Icon(icon, size: 32, color: Colors.black),
      ),
    );
  }
}

/* -------------------------------------------------------
   TOP LABEL (Exit)
-------------------------------------------------------- */
class _TopLabel extends StatelessWidget {
  final String title;
  final IconData icon;

  const _TopLabel({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 28, color: Colors.black),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/* -------------------------------------------------------
   CONFIRMATION PAGE
-------------------------------------------------------- */

class ConfirmationPage extends StatelessWidget {
  final int spotId;
  final int spotNumber;

  const ConfirmationPage({
    super.key,
    required this.spotId,
    required this.spotNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirm Reservation")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Reserve parking slot P$spotNumber?",
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Reserve"),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
          ],
        ),
      ),
    );
  }
}

class ReservationListScreen extends StatefulWidget {
  final int userId;
  const ReservationListScreen({super.key, required this.userId});

  @override
  State<ReservationListScreen> createState() => _ReservationListScreenState();
}

class _ReservationListScreenState extends State<ReservationListScreen> {
  final ApiService api = ApiService();
  List reservations = [];
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final data = await api.getUserReservations(widget.userId);
      if (!mounted) return;
      setState(() {
        reservations = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = "Failed to load reservations";
      });
      print("Error loading reservations: $e");
    } finally {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _cancel(int reservationId) async {
    try {
      final res = await api.cancelReservation(reservationId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["message"] ?? "Reservation cancelled")),
      );

      _loadReservations();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to cancel reservation")));
      print("Error cancelling reservation: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Reservations")),
      body: RefreshIndicator(
        onRefresh: _loadReservations,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? ListView(
                children: [
                  const SizedBox(height: 100),
                  Center(child: Text(errorMessage!)),
                ],
              )
            : reservations.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 100),
                  Center(
                    child: Text(
                      "No reservations found",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                itemCount: reservations.length,
                itemBuilder: (context, index) {
                  final r = reservations[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      title: Text("Spot P${r['spot_number']}"),
                      subtitle: Text(
                        "Mall: ${r['mall_id'] == 1 ? 'Mall A' : 'Mall B'}\nStatus: ${r['status']}",
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ---------- RESERVED ----------
                          if (r['status'] == 'reserved') ...[
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () => _cancel(r['id']),
                              child: const Text("Cancel"),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () async {
                                final res = await api.arrive(r['id']);

                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(res['message'] ?? "Arrived"),
                                  ),
                                );

                                _loadReservations();
                              },
                              child: const Text("Arrive"),
                            ),
                          ],

                          // ---------- OCCUPIED ----------
                          if (r['status'] == 'occupied') ...[
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              onPressed: () async {
                                final res = await api.leave(r['id']);

                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(res['message'] ?? "Left"),
                                  ),
                                );

                                _loadReservations();
                              },
                              child: const Text("Leave"),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  final int userId;
  const HistoryScreen({super.key, required this.userId});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService api = ApiService();
  List history = [];
  bool loading = true;
  String? errorMessage;

  String cleanDate(String iso) {
    if (iso == null) return "";
    return iso.replaceFirst("T", " ").replaceFirst(".000Z", "");
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final data = await api.getHistory(widget.userId);
      if (!mounted) return;
      setState(() {
        history = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = "Failed to load history";
      });
      print("Error loading history: $e");
    } finally {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Parking History")),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? ListView(
                children: [
                  const SizedBox(height: 100),
                  Center(child: Text(errorMessage!)),
                ],
              )
            : history.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 100),
                  Center(
                    child: Text(
                      "No history found",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final h = history[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      title: Text("Spot P${h['spot_number']}"),
                      subtitle: Text(
                        "Mall: ${h['mall_id'] == 1 ? 'Mall A' : 'Mall B'}\n"
                        "Status: ${h['status']}\n"
                        "Date: ${cleanDate(h['created_at'])}",
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final res = await api.deleteHistory(h['id']);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res['message'] ?? "Deleted"),
                            ),
                          );

                          _loadHistory(); // refresh UI
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
