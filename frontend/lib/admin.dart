import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'main.dart'; // for LoginScreen

class AdminDashboardScreen extends StatelessWidget {
  final int userId;

  const AdminDashboardScreen({super.key, required this.userId});

  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
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
                    builder: (_) => const AdminEditParkingScreen(),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Text("Edit Parking Availability"),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminEditUsersScreen(),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Text("Edit User's Details"),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminEditReservationsScreen(),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Text("Edit User's Reservations"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//Edit Parking (Failsafe method)
class AdminEditParkingScreen extends StatefulWidget {
  const AdminEditParkingScreen({super.key});

  @override
  State<AdminEditParkingScreen> createState() => _AdminEditParkingScreenState();
}

class _AdminEditParkingScreenState extends State<AdminEditParkingScreen> {
  final ApiService api = ApiService();
  List spots = [];
  bool loading = true;
  int selectedMallId = 1;

  @override
  void initState() {
    super.initState();
    _loadParking();
  }

  Future<void> _loadParking() async {
    setState(() => loading = true);
    final data = await api.getSpots(selectedMallId); // Mall A default
    setState(() {
      spots = data;
      loading = false;
    });
  }

  Future<void> _toggleAvailability(int spotId, bool current) async {
    await api.updateParking(spotId, current ? 0 : 1);
    _loadParking();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Parking")),
      body: Column(
        children: [
          // ---- Mall selector ----
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButton<int>(
              value: selectedMallId,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 1, child: Text("Sunway Pyramid")),
                DropdownMenuItem(value: 2, child: Text("Pavilion Bukit Jalil")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedMallId = value!;
                });
                _loadParking(); // reload spots for selected mall
              },
            ),
          ),

          // ---- Parking list ----
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: spots.length,
                    itemBuilder: (context, index) {
                      final s = spots[index];
                      final available = s['isAvailable'] == 1;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          title: Text("Spot P${s['spot_number']}"),
                          subtitle: Text(
                            available ? "Available" : "Unavailable",
                            style: TextStyle(
                              color: available ? Colors.green : Colors.red,
                            ),
                          ),
                          trailing: Switch(
                            value: available,
                            onChanged: (_) =>
                                _toggleAvailability(s['id'], available),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Edit User Details
class AdminEditUsersScreen extends StatefulWidget {
  const AdminEditUsersScreen({super.key});

  @override
  State<AdminEditUsersScreen> createState() => _AdminEditUsersScreenState();
}

class _AdminEditUsersScreenState extends State<AdminEditUsersScreen> {
  final ApiService api = ApiService();
  List users = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => loading = true);
    users = await api.getUsers();
    setState(() => loading = false);
  }

  void _editUser(Map user) {
    final nameCtrl = TextEditingController(text: user["name"]);
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit User"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(
                labelText: "New Password (optional)",
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await api.updateUser(user["id"], nameCtrl.text, passCtrl.text);
              Navigator.pop(context);
              _loadUsers();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Users")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final u = users[index];
                return ListTile(
                  title: Text(u["name"]),
                  subtitle: Text(u["email"]),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editUser(u),
                  ),
                );
              },
            ),
    );
  }
}

class AdminEditReservationsScreen extends StatefulWidget {
  const AdminEditReservationsScreen({super.key});

  @override
  State<AdminEditReservationsScreen> createState() =>
      _AdminEditReservationsScreenState();
}

class _AdminEditReservationsScreenState
    extends State<AdminEditReservationsScreen> {
  final ApiService api = ApiService();
  List reservations = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() => loading = true);
    reservations = await api.getAllReservations();
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Reservations")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: reservations.length,
              itemBuilder: (context, index) {
                final r = reservations[index];

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text("P${r['spot_number']} — ${r['user_name']}"),
                    subtitle: Text(
                      "Mall ${r['mall_id']} | Status: ${r['status']}",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (r['status'] == 'reserved')
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () async {
                              await api.adminCancelReservation(r['id']);
                              _loadReservations();
                            },
                            child: const Text("Cancel"),
                          ),

                        if (r['status'] == 'occupied') ...[
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed: () async {
                              await api.adminCompleteReservation(r['id']);
                              _loadReservations();
                            },
                            child: const Text("Complete"),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
