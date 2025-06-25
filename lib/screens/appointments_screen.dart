import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  Future<Map<String, dynamic>?> _fetchDoctor(String doctorId) async {
    final query =
        await FirebaseFirestore.instance
            .collection('doctors')
            .where('id', isEqualTo: doctorId)
            .limit(1)
            .get();
    if (query.docs.isNotEmpty) {
      return query.docs.first.data();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My Appointments')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('appointments')
                  .where('patientDocID', isEqualTo: user.uid)
                  .orderBy('dateTime', descending: false)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No appointments found.'));
            }
            final appointments = snapshot.data!.docs;
            return ListView.separated(
              itemCount: appointments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final data = appointments[index].data() as Map<String, dynamic>;
                final doctorId = data['doctorId'];
                final dateTime =
                    DateTime.tryParse(data['dateTime'] ?? '') ?? DateTime.now();
                return FutureBuilder<Map<String, dynamic>?>(
                  future: _fetchDoctor(doctorId),
                  builder: (context, docSnapshot) {
                    final doctor = docSnapshot.data;
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundImage:
                                  (doctor != null &&
                                          (doctor['image'] ?? '').isNotEmpty)
                                      ? NetworkImage(doctor['image'])
                                      : null,
                              child:
                                  (doctor == null ||
                                          (doctor['image'] ?? '').isEmpty)
                                      ? const Icon(Icons.person, size: 32)
                                      : null,
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doctor != null
                                        ? doctor['name'] ?? 'Doctor'
                                        : 'Doctor',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  if (doctor != null &&
                                      doctor['sector'] != null)
                                    Text(
                                      doctor['sector'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Date: ${DateFormat.yMMMd().format(dateTime)}',
                                  ),
                                  Text(
                                    'Time: ${DateFormat.jm().format(dateTime)}',
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Complaint: ${data['complaint'] ?? ''}'),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Status: ${data['status'] ?? ''}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
