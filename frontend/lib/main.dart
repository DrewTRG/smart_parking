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
      home: const LoginScreen(), // start at login
    );
  }
}

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

      // Navigate to ParkingScreen, pass userId
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
        padding: const EdgeInsets.all(16.0),
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
      Navigator.pop(context); // go back to login
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
        padding: const EdgeInsets.all(16.0),
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
    _loadSpots(showLoader: true); // initial load
    _startAutoRefresh(); // start auto-refresh
  }

  void _startAutoRefresh() {
    // refresh every 5 seconds (you can change this)
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadSpots(); // do not show big loader every time, just refresh silently
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
      // For debugging
      print("Error loading spots: $e");
    }
  }

  Future<void> _reserve(int spotId) async {
    final res = await api.reserveSpot(widget.userId, spotId);
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Reserved')));

    _loadSpots(); // reload spots after reserving
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
                Navigator.pop(context); // close dialog

                // Navigate user back to LoginScreen
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false, // remove all previous screens
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
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadSpots(showLoader: true);
            },
          ),

          // Popup Menu
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "logout") {
                _logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: "logout", child: Text("Logout")),
            ],
          ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadSpots(), // pull-to-refresh
              child: spots.isEmpty
                  ? ListView(
                      // ListView is needed so RefreshIndicator can work even when empty
                      children: [
                        SizedBox(height: 200),
                        Center(child: Text("No parking spots found")),
                      ],
                    )
                  : ListView.builder(
                      itemCount: spots.length,
                      itemBuilder: (context, index) {
                        final s = spots[index];
                        final isAvailable = s['isAvailable'] == 1;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            title: Text("Spot ${s['spot_number']}"),
                            subtitle: Text(
                              isAvailable ? "Available" : "Occupied",
                            ),
                            trailing: isAvailable
                                ? ElevatedButton(
                                    onPressed: () => _reserve(s['id']),
                                    child: const Text("Reserve"),
                                  )
                                : const Text(
                                    "Taken",
                                    style: TextStyle(color: Colors.red),
                                  ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
