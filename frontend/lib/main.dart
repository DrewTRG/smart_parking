import 'dart:async';
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'admin.dart';

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
      final String role = res["role"];
      final String name = res["name"];

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Welcome, $name")));

      if (role == "admin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AdminDashboardScreen(userId: userId),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainMenuScreen(userId: userId)),
        );
      }
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

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ForgotPasswordScreen(),
                  ),
                );
              },
              child: const Text("Forgot password?"),
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

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  static const String hardcodedOtp = "123";

  void _sendOtp() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("OTP sent to email")));
  }

  void _verifyOtp() {
    if (_otpController.text.trim() != hardcodedOtp) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid OTP")));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ResetPasswordScreen(email: _emailController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Forgot Password")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Email row + Send button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: "Email"),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _sendOtp, child: const Text("Send")),
              ],
            ),

            const SizedBox(height: 20),

            // Show hardcoded OTP
            // const Align(
            //   alignment: Alignment.centerLeft,
            //   child: Text(
            //     "OTP: 123",
            //     style: TextStyle(
            //       fontSize: 14,
            //       fontWeight: FontWeight.bold,
            //       color: Colors.grey,
            //     ),
            //   ),
            // ),

            // const SizedBox(height: 10),

            // OTP input
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(labelText: "Enter OTP"),
            ),

            const SizedBox(height: 30),

            ElevatedButton(onPressed: _verifyOtp, child: const Text("Next")),
          ],
        ),
      ),
    );
  }
}

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final ApiService api = ApiService();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool loading = false;

  void _resetPassword() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() => loading = true);
    final res = await api.forgotPassword(widget.email, password);
    setState(() => loading = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(res["message"] ?? "Done")));

    if (res["success"] == true) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "New Password"),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              decoration: const InputDecoration(labelText: "Confirm Password"),
              obscureText: true,
            ),
            const SizedBox(height: 30),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _resetPassword,
                    child: const Text("Reset Password"),
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
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
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
                child: Text("Booking"),
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
                child: Text("My Reservations"),
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

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StatisticScreen(userId: widget.userId),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(14.0),
                child: Text("My Statistic"),
              ),
            ),

            const SizedBox(height: 30),

            const _UserManualCard(),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------
  USER GUIDE
-------------------------------------------------------- */
class _UserManualCard extends StatelessWidget {
  const _UserManualCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "User Guide",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 12),

            _GuideItem(
              icon: Icons.calendar_today,
              text:
                  "Booking: Reserve an available parking spot at your selected mall.",
            ),

            _GuideItem(
              icon: Icons.confirmation_number,
              text:
                  "My Reservations: View, cancel, arrive, or leave your current reservations.",
            ),

            _GuideItem(
              icon: Icons.history,
              text: "History: View your past parking records.",
            ),

            _GuideItem(
              icon: Icons.bar_chart,
              text:
                  "My Statistic: See your parking usage, total hours, and spending over time.",
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _GuideItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------
   MALL SELECTION (WITH AVAILABILITY)
-------------------------------------------------------- */

class MallSelectionScreen extends StatefulWidget {
  final int userId;

  const MallSelectionScreen({super.key, required this.userId});

  @override
  State<MallSelectionScreen> createState() => _MallSelectionScreenState();
}

class _MallSelectionScreenState extends State<MallSelectionScreen> {
  final ApiService api = ApiService();

  int sunwayAvailable = 0;
  int sunwayTotal = 0;

  int pavilionAvailable = 0;
  int pavilionTotal = 0;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    try {
      final sunway = await api.getSpots(1);
      final pavilion = await api.getSpots(2);

      setState(() {
        sunwayTotal = sunway.length;
        sunwayAvailable = sunway.where((s) => s['isAvailable'] == 1).length;

        pavilionTotal = pavilion.length;
        pavilionAvailable = pavilion.where((s) => s['isAvailable'] == 1).length;

        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Mall")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _MallCard(
                    title: "Sunway Pyramid",
                    availability: "Available: $sunwayAvailable / $sunwayTotal",
                    imagePath: "assets/images/sunway.jpg",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ParkingScreen(userId: widget.userId, mallId: 1),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  _MallCard(
                    title: "Pavilion Bukit Jalil",
                    availability:
                        "Available: $pavilionAvailable / $pavilionTotal",
                    imagePath: "assets/images/pavilion.jpg",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ParkingScreen(userId: widget.userId, mallId: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

/* -------------------------------------------------------
   MALL CARD
-------------------------------------------------------- */

class _MallCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;
  final String availability;

  const _MallCard({
    required this.title,
    required this.imagePath,
    required this.onTap,
    required this.availability,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Mall Image ----
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.asset(
                imagePath,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            // ---- Mall Title + Availability ----
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(
                    availability,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),
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
  bool _hasShownInitialRate = false;

  //Parking rate text based on mallId
  String _getRateText() {
    if (widget.mallId == 1) {
      return """
Sunway Pyramid Parking Rates

Weekdays:
- RM 3.00 for the first hour
- RM 1.00 per subsequent hour

Weekends:
- RM 5.00 for the first 2 hours
- RM 2.00 per subsequent hour
""";
    } else if (widget.mallId == 2) {
      return """
Pavilion Bukit Jalil Parking Rates

Weekdays:
- RM 3.00 for the first 2 hours
- RM 1.00 per subsequent hour

Weekends:
- RM 4.00 for the first hour
- RM 2.00 per subsequent hour
""";
    } else {
      return "Parking rate information is not available for this mall.";
    }
  }

  void _showRateDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          // Custom title with X button
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Parking Rates"),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          content: Text(_getRateText(), style: const TextStyle(fontSize: 14)),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadSpots(widget.mallId, showLoader: true);
    _startAutoRefresh();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasShownInitialRate) {
        _hasShownInitialRate = true;
        _showRateDialog();
      }
    });
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
        ],
      ),

      /* -------- PARKING MAP LAYOUT -------- */
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadSpots(widget.mallId),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // --------- Parking Rate button (top-right) ----------
                      Padding(
                        padding: const EdgeInsets.only(
                          right: 8.0,
                          top: 8.0,
                          bottom: 35,
                        ),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: _showRateDialog,
                            icon: const Icon(Icons.info_outline),
                            label: const Text("Parking Rate"),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // --------- Original row with side labels + map ---------
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 30),
                            child: const _SideLabel(
                              title: "Entrance",
                              icon: Icons.arrow_forward,
                            ),
                          ),
                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 12),
                                  child: _TopLabel(
                                    title: "Exit",
                                    icon: Icons.exit_to_app,
                                  ),
                                ),
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
                                      physics:
                                          const NeverScrollableScrollPhysics(),
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
                                        final isAvailable =
                                            s['isAvailable'] == 1;

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
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: Colors.black,
                                              ),
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
                            padding: const EdgeInsets.only(top: 30),
                            child: const _SideLabel(
                              title: "Lift",
                              icon: Icons.elevator,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 10),
                      const ParkingGuide(),
                    ],
                  ),
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
  final String title;
  final IconData icon;

  const _SideLabel({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: title, // text shown in tooltip
      triggerMode: TooltipTriggerMode.tap, // 👈 tap instead of long-press
      waitDuration: Duration.zero,
      showDuration: const Duration(seconds: 2),
      child: Icon(icon, size: 32, color: Colors.black),
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
  USER GUIDE (PARKING)
-------------------------------------------------------- */
class ParkingGuide extends StatelessWidget {
  const ParkingGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 24),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Parking Guide",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),

            // ---- Slot color guide ----
            _GuideRow(
              color: Colors.green,
              text: "Green slot → Available (Can be reserved)",
            ),
            _GuideRow(
              color: Colors.red,
              text: "Red slot → Unavailable (Cannot be reserved)",
            ),
            SizedBox(height: 10),

            _GuideText("Tap a green slot to reserve"),
            _GuideText("Red spot cannot be reserved"),
            SizedBox(height: 16),

            Divider(),

            SizedBox(height: 12),

            // ---- Icon guide ----
            Text(
              "Map Icons",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 10),

            _IconGuideRow(icon: Icons.arrow_forward, text: "Entrance"),
            _IconGuideRow(icon: Icons.exit_to_app, text: "Exit"),
            _IconGuideRow(
              icon: Icons.elevator,
              text: "Lift to Mall/Jaya Grocer",
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideRow extends StatelessWidget {
  final Color color;
  final String text;

  const _GuideRow({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Text(text),
        ],
      ),
    );
  }
}

class _GuideText extends StatelessWidget {
  final String text;
  const _GuideText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text("• $text"),
    );
  }
}

class _IconGuideRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _IconGuideRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.black),
          const SizedBox(width: 10),
          Text(text),
        ],
      ),
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

/* -------------------------------------------------------
   DURATION SELECTION PAGE (After pressing ARRIVE)
-------------------------------------------------------- */

class SelectDurationPage extends StatelessWidget {
  final int reservationId;
  final int mallId;

  const SelectDurationPage({
    super.key,
    required this.reservationId,
    required this.mallId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Parking Duration")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            for (int hours = 1; hours <= 5; hours++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton(
                  onPressed: () async {
                    // ✅ make it async
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentSummaryPage(
                          reservationId: reservationId,
                          mallId: mallId,
                          hours: hours,
                        ),
                      ),
                    );

                    if (result == true) {
                      // send success back to ReservationListScreen
                      Navigator.pop(context, true);
                    }
                  },
                  child: Text("$hours Hour${hours > 1 ? 's' : ''}"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------
   PRICE CALCULATION LOGIC
-------------------------------------------------------- */

double calculateParkingFee(int mallId, int hours) {
  final weekday = DateTime.now().weekday;
  final isWeekend = (weekday == 6 || weekday == 7);

  double total = 0;

  if (mallId == 1) {
    // Sunway Pyramid
    if (!isWeekend) {
      // Weekdays
      total = 3 + (hours - 1) * 1;
    } else {
      // Weekends
      if (hours <= 2) {
        total = 5;
      } else {
        total = 5 + (hours - 2) * 2;
      }
    }
  } else if (mallId == 2) {
    // Pavilion Bukit Jalil
    if (!isWeekend) {
      // Weekdays
      if (hours <= 2) {
        total = 3;
      } else {
        total = 3 + (hours - 2) * 1;
      }
    } else {
      // Weekends
      total = 4 + (hours - 1) * 2;
    }
  }

  return total;
}

/* -------------------------------------------------------
   PAYMENT SUMMARY PAGE
-------------------------------------------------------- */

class PaymentSummaryPage extends StatefulWidget {
  final int reservationId;
  final int mallId;
  final int hours;

  const PaymentSummaryPage({
    super.key,
    required this.reservationId,
    required this.mallId,
    required this.hours,
  });

  @override
  State<PaymentSummaryPage> createState() => _PaymentSummaryPageState();
}

class _PaymentSummaryPageState extends State<PaymentSummaryPage> {
  String paymentMethod = "Online Banking";

  Future<void> _openPaymentApp() async {
    Uri uri;

    if (paymentMethod == "Online Banking") {
      uri = Uri.parse("https://www.cimbclicks.com.my");
    } else if (paymentMethod == "Touch N Go") {
      uri = Uri.parse("https://prod.tngdigital.com.my/pay");
    } else {
      uri = Uri.parse("https://visa.com");
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final fee = calculateParkingFee(widget.mallId, widget.hours);

    return Scaffold(
      appBar: AppBar(title: const Text("Payment Summary")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Parking Duration: ${widget.hours} hour(s)",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              "Total Fee: RM${fee.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            const Text("Payment Method"),
            const SizedBox(height: 8),

            DropdownButton<String>(
              value: paymentMethod,
              items: const [
                DropdownMenuItem(
                  value: "Online Banking",
                  child: Text("Online Banking"),
                ),
                DropdownMenuItem(
                  value: "Credit Card",
                  child: Text("Credit Card"),
                ),
                DropdownMenuItem(
                  value: "Touch N Go",
                  child: Text("Touch 'n Go"),
                ),
              ],
              onChanged: (value) {
                setState(() => paymentMethod = value!);
              },
            ),

            const Spacer(),

            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final fee = calculateParkingFee(widget.mallId, widget.hours);

                  // 1. Open payment app / website
                  await _openPaymentApp();

                  // 2. Treat this as "payment successful" and mark reservation as occupied
                  final api = ApiService();
                  final res = await api.arrive(
                    widget.reservationId,
                    widget.hours,
                  );

                  if (!mounted) return;

                  // 3. Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res["message"] ?? "Payment successful!"),
                    ),
                  );

                  // 4. Go back to Reservation list
                  Navigator.pop(
                    context,
                    true,
                  ); // return success to SelectDuration
                },

                child: const Text("Proceed to Pay"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------
   RESERVATIONS PAGE
-------------------------------------------------------- */
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
  Timer? _timer;
  Set<int> warned15Min = {};
  Set<int> warnedExpired = {};

  String formatDateTime(dynamic value) {
    if (value == null) return "N/A";
    return value.toString().replaceAll("T", " ").replaceAll(".000Z", "");
  }

  @override
  void initState() {
    super.initState();
    _loadReservations();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      final now = DateTime.now();

      for (final r in reservations) {
        if (r['status'] != 'occupied' || r['end_time'] == null) continue;

        final end = DateTime.parse(r['end_time']);
        final diff = end.difference(now).inMinutes;
        final id = r['id'];

        // 🔔 EXPIRY WARNING
        if (diff <= 15 && diff > 0 && !warned15Min.contains(id)) {
          warned15Min.add(id);

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: const Text("Parking Expiry Warning"),
              content: Text(
                "⏰ Your parking will expire in $diff minute${diff == 1 ? '' : 's'}.\n\n"
                "Please extend your parking time to avoid penalty.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }

        // ⛔ EXPIRED POP-UP
        if (diff <= 0 && !warnedExpired.contains(id)) {
          warnedExpired.add(id);

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: const Text("Parking Time Expired"),
              content: const Text(
                "❗ Your parking time has expired.\n\n"
                "Please pay the penalty before leaving.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
      }
    });
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
                  final end = r['end_time'] != null
                      ? DateTime.parse(r['end_time'])
                      : null;

                  final bool expired =
                      end != null && DateTime.now().isAfter(end);

                  final bool penaltyPaid = r['penalty_paid'] == 1;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      title: Text("Spot P${r['spot_number']}"),
                      subtitle: Text(
                        "Mall: ${r['mall_id'] == 1 ? 'Sunway Pyramid' : 'Pavilion Bukit Jalil'}\n"
                        "Status: ${r['status']}\n"
                        "Expires At: ${formatDateTime(r['end_time'])}",
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
                                final success = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SelectDurationPage(
                                      reservationId: r['id'],
                                      mallId: r['mall_id'],
                                    ),
                                  ),
                                );

                                if (success == true) {
                                  _loadReservations(); // auto refresh UI
                                }
                              },

                              child: const Text("Arrive"),
                            ),
                          ],

                          // ---------- OCCUPIED ----------
                          if (r['status'] == 'occupied') ...[
                            // ➕ ADD TIME (only if NOT expired)
                            if (!expired)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                ),
                                onPressed: () async {
                                  final success = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddTimePage(
                                        reservationId: r['id'],
                                        mallId: r['mall_id'],
                                      ),
                                    ),
                                  );

                                  if (success == true) {
                                    _loadReservations();
                                  }
                                },
                                child: const Text("Add Time"),
                              ),

                            const SizedBox(width: 8),

                            // 🚪 LEAVE (if not expired OR penalty already paid)
                            if (!expired || penaltyPaid)
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
                              )
                            // 💰 PAY PENALTY (expired AND not paid)
                            else
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () async {
                                  final paid = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PenaltyPaymentPage(
                                        reservationId: r['id'],
                                      ),
                                    ),
                                  );

                                  if (paid == true) {
                                    _loadReservations(); // 🔥 THIS IS KEY
                                  }
                                },
                                child: const Text("Pay Penalty"),
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

class PenaltyPaymentPage extends StatefulWidget {
  final int reservationId;

  const PenaltyPaymentPage({super.key, required this.reservationId});

  @override
  State<PenaltyPaymentPage> createState() => _PenaltyPaymentPageState();
}

class _PenaltyPaymentPageState extends State<PenaltyPaymentPage> {
  final ApiService api = ApiService();
  String paymentMethod = "Online Banking";

  final double penaltyAmount = 10.0;

  Future<void> _openPaymentApp() async {
    Uri uri;

    if (paymentMethod == "Online Banking") {
      uri = Uri.parse("https://www.cimbclicks.com.my");
    } else if (paymentMethod == "Touch N Go") {
      uri = Uri.parse("https://prod.tngdigital.com.my/pay");
    } else {
      uri = Uri.parse("https://visa.com");
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Penalty Payment")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Parking Time Exceeded",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Text(
              "Penalty Amount: RM${penaltyAmount.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),

            const SizedBox(height: 20),

            const Text("Payment Method"),
            const SizedBox(height: 8),

            DropdownButton<String>(
              value: paymentMethod,
              items: const [
                DropdownMenuItem(
                  value: "Online Banking",
                  child: Text("Online Banking"),
                ),
                DropdownMenuItem(
                  value: "Credit Card",
                  child: Text("Credit Card"),
                ),
                DropdownMenuItem(
                  value: "Touch N Go",
                  child: Text("Touch 'n Go"),
                ),
              ],
              onChanged: (value) {
                setState(() => paymentMethod = value!);
              },
            ),

            const Spacer(),

            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  await _openPaymentApp();

                  final res = await api.payPenalty(widget.reservationId);

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        res['message'] ?? "Penalty paid successfully",
                      ),
                    ),
                  );

                  Navigator.pop(context, true);
                },
                child: const Text("Proceed to Pay"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddTimePage extends StatelessWidget {
  final int reservationId;
  final int mallId;

  const AddTimePage({
    super.key,
    required this.reservationId,
    required this.mallId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Parking Time")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            for (int hours = 1; hours <= 3; hours++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton(
                  onPressed: () async {
                    final paid = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddTimePaymentPage(
                          reservationId: reservationId,
                          mallId: mallId,
                          extraHours: hours,
                        ),
                      ),
                    );

                    if (paid == true) {
                      Navigator.pop(context, true);
                    }
                  },
                  child: Text("Add $hours Hour${hours > 1 ? 's' : ''}"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AddTimePaymentPage extends StatefulWidget {
  final int reservationId;
  final int mallId;
  final int extraHours;

  const AddTimePaymentPage({
    super.key,
    required this.reservationId,
    required this.mallId,
    required this.extraHours,
  });

  @override
  State<AddTimePaymentPage> createState() => _AddTimePaymentPageState();
}

class _AddTimePaymentPageState extends State<AddTimePaymentPage> {
  String paymentMethod = "Online Banking";
  final ApiService api = ApiService();

  Future<void> _openPaymentApp() async {
    Uri uri;

    if (paymentMethod == "Online Banking") {
      uri = Uri.parse("https://www.cimbclicks.com.my");
    } else if (paymentMethod == "Touch N Go") {
      uri = Uri.parse("https://prod.tngdigital.com.my/pay");
    } else {
      uri = Uri.parse("https://visa.com");
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final fee = calculateParkingFee(widget.mallId, widget.extraHours);

    return Scaffold(
      appBar: AppBar(title: const Text("Add Time Payment")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Additional Duration: ${widget.extraHours} hour(s)",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),

            Text(
              "Additional Fee: RM${fee.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            const Text("Payment Method"),
            const SizedBox(height: 8),

            DropdownButton<String>(
              value: paymentMethod,
              items: const [
                DropdownMenuItem(
                  value: "Online Banking",
                  child: Text("Online Banking"),
                ),
                DropdownMenuItem(
                  value: "Credit Card",
                  child: Text("Credit Card"),
                ),
                DropdownMenuItem(
                  value: "Touch N Go",
                  child: Text("Touch 'n Go"),
                ),
              ],
              onChanged: (value) {
                setState(() => paymentMethod = value!);
              },
            ),

            const Spacer(),

            Center(
              child: ElevatedButton(
                onPressed: () async {
                  // 1️⃣ Redirect to payment app / website
                  await _openPaymentApp();

                  // 2️⃣ Treat payment as successful → extend time
                  final res = await api.extendTime(
                    widget.reservationId,
                    widget.extraHours,
                  );

                  if (!context.mounted) return;

                  // 3️⃣ Show confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res["message"] ?? "Time extended")),
                  );

                  // 4️⃣ Return success to AddTimePage
                  Navigator.pop(context, true);
                },
                child: const Text("Proceed to Pay"),
              ),
            ),
          ],
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
                        "Mall: ${h['mall_id'] == 1 ? 'Sunway Pyramid' : 'Pavilion Bukit Jalil'}\n"
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

/* -------------------------------------------------------
   STATS
-------------------------------------------------------- */
class StatisticScreen extends StatefulWidget {
  final int userId;
  const StatisticScreen({super.key, required this.userId});

  @override
  State<StatisticScreen> createState() => _StatisticScreenState();
}

class _StatisticScreenState extends State<StatisticScreen> {
  String selectedRange = "7 days";

  final Map<String, Map<String, dynamic>> statsData = {
    "7 days": {"visits": 3, "hours": 6, "spent": 18.00},
    "1 month": {"visits": 12, "hours": 28, "spent": 82.00},
    "3 months": {"visits": 30, "hours": 75, "spent": 210.00},
    "6 months": {"visits": 58, "hours": 140, "spent": 395.00},
  };

  @override
  Widget build(BuildContext context) {
    final data = statsData[selectedRange]!;

    return Scaffold(
      appBar: AppBar(title: const Text("My Statistics")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Time range selector ----
            DropdownButton<String>(
              value: selectedRange,
              items: statsData.keys
                  .map(
                    (range) =>
                        DropdownMenuItem(value: range, child: Text(range)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => selectedRange = value!);
              },
            ),

            const SizedBox(height: 24),

            // ---- Statistic cards ----
            _StatCard(
              title: "Total Visits",
              value: data["visits"].toString(),
              icon: Icons.local_parking,
            ),

            _StatCard(
              title: "Total Hours Parked",
              value: "${data["hours"]} hrs",
              icon: Icons.access_time,
            ),

            _StatCard(
              title: "Total Spent",
              value: "RM ${data["spent"].toStringAsFixed(2)}",
              icon: Icons.payments,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 36, color: Colors.blue),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
