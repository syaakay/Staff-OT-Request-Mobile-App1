import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OTHistoryPage extends StatelessWidget {
  const OTHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get current logged-in user
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color.fromARGB(255, 0, 0, 0)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Overtime History",
          style: TextStyle(
            color: Color.fromARGB(255, 60, 103, 219), // Matching your UI text color
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5E5CE6), Color(0xFF48D1CC)],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            // Stream filters for ONLY this user's requests
            stream: FirebaseFirestore.instance
                .collection('otrequests')
                .where('uid', isEqualTo: user?.uid) 
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text("No history found", style: TextStyle(color: Colors.white)),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;

                  return _buildHistoryCard(data);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoText("Start Date/Time", data['startDateTime']),
          _infoText("End Date/Time", data['endDateTime']),
          _infoText("Reason", data['reason']),
          _infoText("Supervisor", data['supervisorName']),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Status", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                data['status'] ?? 'Pending',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(data['status']),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoText(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        "$label : ${value ?? 'N/A'}",
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == 'Approved') return Colors.green;
    if (status == 'Rejected') return Colors.red;
    return Colors.orange; // For Pending
  }
}