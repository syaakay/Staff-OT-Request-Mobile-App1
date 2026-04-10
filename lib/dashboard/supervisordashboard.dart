import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_app/services/activeot.dart';
import 'package:test_app/services/allrequest.dart';
import 'package:test_app/services/othistory.dart';
import 'package:test_app/services/otrequest.dart';


class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({super.key});

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  final user = FirebaseAuth.instance.currentUser;
  int _previousPendingCount = 0; // Tracks count to trigger pop-up alert

  @override
  void initState() {
    super.initState();
    _initNotificationListener();
  }

  // --- AUTO-POP ALERT LOGIC ---
  // This listens for any changes in the "Pending" status count
  void _initNotificationListener() {
    _getStaffRequestCount("Pending").listen((currentCount) {
      // Logic: Only pop up if the app is open (mounted), the count increased, 
      // and it's not the first time the app is loading (previousCount != 0)
      if (mounted && currentCount > _previousPendingCount && _previousPendingCount != 0) {
        _showPopupNotification(currentCount);
      }
      _previousPendingCount = currentCount;
    });
  }

  void _showPopupNotification(int count) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Clear old alerts
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text("New OT Request received! ($count Total Pending)")),
          ],
        ),
        backgroundColor: const Color(0xFF5E5CE6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(15),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: "VIEW",
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AllRequest()),
            );
          },
        ),
      ),
    );
  }

  // Real-time Stream for status counts
  Stream<int> _getStaffRequestCount(String status) {
    return FirebaseFirestore.instance
        .collection('otrequests')
        .where('supervisorEmail', isEqualTo: user?.email)
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
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
              // --- TOP BAR ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

              // --- MAIN CONTENT ---
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 25),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          const SizedBox(height: 15),
                          _buildDynamicStatusCard("Approved", const Color(0xFF94C973), isFullWidth: true),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: _buildDynamicStatusCard("Pending", const Color(0xFFF1E5AC))),
                              const SizedBox(width: 15),
                              Expanded(child: _buildDynamicStatusCard("Rejected", const Color(0xFFF89090))),
                            ],
                          ),
                        ],
                      ),
                      
                      // Floating Action Button
                      Positioned(
                        bottom: 0,
                        right: 0,
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
                            const SizedBox(height: 6),
                            const Text(
                              "New Request", 
                              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black54, height: 4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- BOTTOM NAVIGATION WITH RED DOT BADGE ---
              Container(
                margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    // ignore: deprecated_member_use
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(context, Icons.home, "Home", () {}),
                    
                    StreamBuilder<int>(
                      stream: _getStaffRequestCount("Pending"),
                      builder: (context, snapshot) {
                        int pendingCount = snapshot.data ?? 0;
                        return 
                        _buildNavItem(context,   Icons.assignment_outlined, 
                          "All request", 
                          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AllRequest())),
                          badgeCount: pendingCount,
                        );
                      }
                    ),
                    
                    _buildNavItem(context, Icons.history, "History", ()  => Navigator.push(context, MaterialPageRoute(builder: (context) => const OTHistoryPage()) ),
                    ),
                    _buildNavItem(context, Icons.work_history, "ActiveOT", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ActiveOTPage()) ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicStatusCard(String label, Color color, {bool isFullWidth = false}) {
    return StreamBuilder<int>(
      stream: _getStaffRequestCount(label),
      builder: (context, snapshot) {
        String count = snapshot.hasData ? snapshot.data.toString() : "0";
        return Container(
          width: isFullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(vertical: 40),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(25)),
          child: Column(
            children: [
              Text(count, style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, VoidCallback? onTap, {int badgeCount = 0}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF8B80F8), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}