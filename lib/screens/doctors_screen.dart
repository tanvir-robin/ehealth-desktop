import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/local_appointments_service.dart';

class DoctorsScreen extends StatelessWidget {
  const DoctorsScreen({super.key});

  void _showBookingDialog(
    BuildContext context,
    Map<String, dynamic> doctorData,
    String doctorDocId,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => BookAppointmentDialog(
            doctorData: doctorData,
            doctorDocId: doctorDocId,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doctors')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No doctors found.'));
            }
            final doctors = snapshot.data!.docs;
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.6,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
              ),
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                final doc = doctors[index];
                final data = doc.data() as Map<String, dynamic>;
                return DoctorCard(
                  name: data['name'] ?? '',
                  image: data['image'] ?? '',
                  degrees: data['degrees'] ?? '',
                  sector: data['sector'] ?? '',
                  experience: data['experience']?.toString() ?? '',
                  fees: data['fees']?.toString() ?? '',
                  patients: data['patients']?.toString() ?? '',
                  onBook: () => _showBookingDialog(context, data, doc.id),
                );
              },
            );
          },
        ),
      ),
      backgroundColor: Colors.grey[100],
    );
  }
}

class DoctorCard extends StatelessWidget {
  final String name;
  final String image;
  final String degrees;
  final String sector;
  final String experience;
  final String fees;
  final String patients;
  final VoidCallback onBook;

  const DoctorCard({
    required this.name,
    required this.image,
    required this.degrees,
    required this.sector,
    required this.experience,
    required this.fees,
    required this.patients,
    required this.onBook,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
              child: image.isEmpty ? const Icon(Icons.person, size: 40) : null,
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    sector,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Degrees: $degrees',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text('Experience: $experience years'),
                  Text('Patients: $patients'),
                  Text('Fees: $fees'),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      onPressed: onBook,
                      child: const Text('Book Appointment'),
                    ),
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

class BookAppointmentDialog extends StatefulWidget {
  final Map<String, dynamic> doctorData;
  final String doctorDocId;
  const BookAppointmentDialog({
    required this.doctorData,
    required this.doctorDocId,
    super.key,
  });

  @override
  State<BookAppointmentDialog> createState() => _BookAppointmentDialogState();
}

class _BookAppointmentDialogState extends State<BookAppointmentDialog> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _complaintController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<bool> _isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _bookAppointment() async {
    if (_selectedDate == null ||
        _selectedTime == null ||
        _complaintController.text.isEmpty) {
      setState(() => _error = 'Please fill all fields.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');
      final patientDocID = user.uid;
      final doctorId = widget.doctorData['id'] ?? 0;
      final dateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      final appointmentData = {
        'complaint': _complaintController.text.trim(),
        'createdAt': DateTime.now().toIso8601String(),
        'dateTime': dateTime.toIso8601String(),
        'doctorId': doctorId,
        'patientDocID': patientDocID,
        'status': 'pending',
      };
      final online = await _isOnline();
      if (online) {
        await FirebaseFirestore.instance
            .collection('appointments')
            .add(appointmentData);
        // Try to sync any pending appointments
        await LocalAppointmentsService.syncPendingAppointments();
      } else {
        await LocalAppointmentsService.savePendingAppointment(appointmentData);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Failed to book appointment.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Book Appointment with ${widget.doctorData['name'] ?? ''}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _complaintController,
                decoration: const InputDecoration(labelText: 'Complaint'),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickDate,
                      child: Text(
                        _selectedDate == null
                            ? 'Pick Date'
                            : DateFormat.yMMMd().format(_selectedDate!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickTime,
                      child: Text(
                        _selectedTime == null
                            ? 'Pick Time'
                            : _selectedTime!.format(context),
                      ),
                    ),
                  ),
                ],
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _bookAppointment,
                  child:
                      _loading
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Book'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
