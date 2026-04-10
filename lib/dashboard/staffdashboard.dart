import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_app/services/activeot.dart';
import 'package:test_app/services//othistory.dart';
import 'package:test_app/services/otrequest.dart';


class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  final user = FirebaseAuth.instance.currentUser;

  // Function to handle logout
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // ignore: use_build_context_synchronously
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  // Real-time stream to count documents by status for the current user
  Stream<int> _getStatusCount(String status) {
    return FirebaseFirestore.instance
        .collection('otrequests')
        .where('uid', isEqualTo: user?.uid)
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5E5CE6), Color(0xFF48D1CC)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white, size: 30),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: () => _logout(context),
                    ),
                  ],
                ),
              ),

              // Main Content Area
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 25),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F6F9),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          // Approved Counter (Dynamic)
                          _buildStreamCard("Approved", const Color(0xFF90C184), isFullWidth: true),
                          
                          const SizedBox(height: 15),
                          
                          Row(
                            children: [
                              // Pending Counter (Dynamic)
                              Expanded(child: _buildStreamCard("Pending", const Color(0xFFE9E69B))),
                              const SizedBox(width: 20),
                              // Rejected Counter (Dynamic)
                              Expanded(child: _buildStreamCard("Rejected", const Color(0xFFF6918E))),
                            ],
                          ),
                        ],
                      ),

                      // Floating Action Button Area
                      Positioned(
                        bottom: 20,
                        right: 10,
                        child: Column(
                          children: [
                            Material(
                              color: const Color(0xFF7B78FF),
                              borderRadius: BorderRadius.circular(12),
                              elevation: 4,
                              child: IconButton(
                                iconSize: 30,
                                icon: const Icon(Icons.add, color: Colors.white),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const OTRequestPage()),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "New Request",
                              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const CustomBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget to handle the Stream logic
  Widget _buildStreamCard(String status, Color color, {bool isFullWidth = false}) {
    return StreamBuilder<int>(
      stream: _getStatusCount(status),
      builder: (context, snapshot) {
        String value = "0";
        if (snapshot.hasData) {
          value = snapshot.data.toString();
        }
        return _buildStatusCard(
          label: status,
          value: value,
          color: color,
          isFullWidth: isFullWidth,
        );
      },
    );
  }

  Widget _buildStatusCard({
    required String label,
    required String value,
    required Color color,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home, "Home", const Color(0xFF7B78FF), () {
            // Logic for Home
          }),
          _navItem(Icons.history, "History", const Color(0xFF7B78FF), () {
            // Navigate to History Page
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OTHistoryPage()),
            );
          }),
          _navItem(Icons.business_center, "ActiveOT", const Color(0xFF7B78FF), () {
            // Navigate to ActiveOT Page
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ActiveOTPage()),
            );
          }),
        ],
      ),
    );
  }

  // UPDATED: Added VoidCallback and wrapped with GestureDetector
  Widget _navItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap, // This triggers the function passed above
      behavior: HitTestBehavior.opaque, // Makes the entire area clickable
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.black)),
        ],
      ),
    );
  }
}