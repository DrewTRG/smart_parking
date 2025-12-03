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
        MaterialPageRoute(builder: (context) => ParkingScreen(userId: userId)),
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
   PARKING SCREEN WITH PARKING MAP
-------------------------------------------------------- */

class ParkingScreen extends StatefulWidget {
  final int userId;

  const ParkingScreen({super.key, required this.userId});

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
    _loadSpots(showLoader: true);
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadSpots();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSpots({bool showLoader = false}) async {
    if (showLoader) {
      setState(() => loading = true);
    }
    try {
      final data = await api.getSpots();
      if (!mounted) return;
      setState(() {
        spots = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      print("Error loading spots: $e");
    }
  }

  Future<void> _reserve(int spotId) async {
    final res = await api.reserveSpot(widget.userId, spotId);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Reserved')));

    _loadSpots();
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
            onPressed: () => _loadSpots(showLoader: true),
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
              onRefresh: () => _loadSpots(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const _SideLabel(
                      title: "Entrance",
                      icon: Icons.arrow_forward,
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: GridView.builder(
                            shrinkWrap: true, // <<< important
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 5,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 1, // squares
                                ),
                            itemCount: spots.length,
                            itemBuilder: (context, index) {
                              final s = spots[index];
                              final isAvailable = s['isAvailable'] == 1;

                              return GestureDetector(
                                onTap: isAvailable
                                    ? () async {
                                        final reserved = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ConfirmationPage(
                                              slotId: s['id'],
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
                    ),

                    const SizedBox(width: 12),
                    const _SideLabel(title: "Lift", icon: Icons.elevator),
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
        child: Icon(
          icon,
          size: 32,
          color: Colors.black,
        ),
      ),
    );
  }
}


/* -------------------------------------------------------
   CONFIRMATION PAGE
-------------------------------------------------------- */

class ConfirmationPage extends StatelessWidget {
  final int slotId;

  const ConfirmationPage({super.key, required this.slotId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirm Reservation")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Reserve parking slot P$slotId?",
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
