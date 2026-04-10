import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AllRequest extends StatelessWidget {
  const AllRequest({super.key});

  @override
  Widget build(BuildContext context) {

final String? currentUserEmail = FirebaseAuth.instance.currentUser?.email;

    return Scaffold(
      // Extend body to paint under the AppBar area
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Staff OT Requests",
          style: TextStyle(color: Color.fromARGB(255, 94, 111, 224), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color.fromARGB(255, 0, 0, 0)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF556EFF), Color(0xFF4EE2C0)],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('otrequests')
                .where('supervisorEmail', isEqualTo: currentUserEmail)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }

              if (currentUserEmail == null) {
                 return const Center(child: Text("User not authenticated.", style: TextStyle(color: Colors.white)));

               }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text("No requests.", style: TextStyle(color: Colors.white, fontSize: 18)),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  var data = doc.data() as Map<String, dynamic>;
                  String status = data['status'] ?? 'Pending';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow("Name", data['name']),
                        _buildInfoRow("Start Date/Time", data['startDateTime']),
                        _buildInfoRow("End Date/Time", data['endDateTime']),
                        _buildInfoRow("Reason", data['reason']),
                        const SizedBox(height: 20),
                        
                        // Show buttons only if Pending, else show Status text
                        status == 'Pending'
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  _buildActionButton(
                                    label: "Approve",
                                    color: const Color(0xFF4CAF50),
                                    onPressed: () => doc.reference.update({'status': 'Approved'}),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildActionButton(
                                    label: "Reject",
                                    color: const Color(0xFFC62828),
                                    onPressed: () => doc.reference.update({'status': 'Rejected'}),
                                  ),
                                ],
                              )
                            : Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: status == 'Approved' ? Colors.green : Colors.red,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // Helper for the text labels
  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        "$label: ${value ?? 'N/A'}",
        style: const TextStyle(
          fontSize: 15,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Helper for the action buttons
  Widget _buildActionButton({required String label, required Color color, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}