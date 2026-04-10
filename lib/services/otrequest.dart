import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Add this to your pubspec.yaml for date formatting

class OTRequestPage extends StatefulWidget {
  const OTRequestPage({super.key});

  @override
  State<OTRequestPage> createState() => _OTRequestPageState();
}

class _OTRequestPageState extends State<OTRequestPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _startDateTimeController = TextEditingController();
  final _endDateTimeController = TextEditingController();
  final _reasonController = TextEditingController();
  final _supervisorController = TextEditingController();
  final _supervisorEmailController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _startDateTimeController.dispose();
    _endDateTimeController.dispose();
    _reasonController.dispose();
    _supervisorController.dispose();
    _supervisorEmailController.dispose();
    super.dispose();
  }

  // --- DATE & TIME PICKER LOGIC ---
  Future<void> _pickDateTime(TextEditingController controller) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        // ignore: use_build_context_synchronously
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final DateTime fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        
        // Format: 2024-05-20 14:30
        setState(() {
          controller.text = DateFormat('yyyy-MM-dd HH:mm').format(fullDateTime);
        });
      }
    }
  }

  Future<void> _submitRequest() async {
    if (_nameController.text.isEmpty || _reasonController.text.isEmpty || _startDateTimeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in required fields")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('otrequests').add({
        'uid': user?.uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'startDateTime': _startDateTimeController.text.trim(),
        'endDateTime': _endDateTimeController.text.trim(),
        'reason': _reasonController.text.trim(),
        'supervisorName': _supervisorController.text.trim(),
        'supervisorEmail': _supervisorEmailController.text.trim(),
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request Submitted Successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: SingleChildScrollView(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Text(
                  "New OT Request",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    children: [
                      _buildTextField("Name", _nameController),
                      _buildTextField("Email", _emailController),
                      Row(
                        children: [
                          Expanded(child: _buildTextField("Start Date", _startDateTimeController, isDate: true)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildTextField("End Date", _endDateTimeController, isDate: true)),
                        ],
                      ),
                      _buildTextField("Reason", _reasonController),
                      _buildTextField("Supervisor Name", _supervisorController),
                      _buildTextField("Supervisor Email", _supervisorEmailController),
                      const SizedBox(height: 30),
                      _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _submitRequest,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B80F8),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  elevation: 5,
                                ),
                                child: const Text(
                                  "Submit Request",
                                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isDate = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: TextField(
        controller: controller,
        // Make field read-only if it's a date field so user must use the picker
        readOnly: isDate, 
        onTap: isDate ? () => _pickDateTime(controller) : null,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54),
          floatingLabelStyle: const TextStyle(color: Color(0xFF556EFF), fontWeight: FontWeight.bold),
          filled: true,
          fillColor: Colors.white,
          // Calendar icon triggers the picker
          suffixIcon: isDate 
            ? IconButton(
                icon: const Icon(Icons.calendar_month, color: Color(0xFF8B80F8)),
                onPressed: () => _pickDateTime(controller),
              ) 
            : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFF8B80F8), width: 2),
          ),
        ),
      ),
    );
  }
}