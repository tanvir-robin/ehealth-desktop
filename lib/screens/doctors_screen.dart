import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/local_appointments_service.dart';
import 'package:uuid/uuid.dart';

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFf7fafc), Color(0xFFedf2f7)],
          ),
        ),
        child: Column(
          children: [
            // Desktop Header
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  const Text(
                    'Available Doctors',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF667eea)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_hospital,
                          size: 20,
                          color: Color(0xFF667eea),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Medical Specialists',
                          style: TextStyle(
                            color: Color(0xFF667eea),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Search Bar
                  Container(
                    width: 300,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search doctors...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('doctors')
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(80),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.medical_services_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No doctors available',
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Check back later for available specialists',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    final doctors = snapshot.data!.docs;
                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5, // More columns for desktop
                            childAspectRatio: 0.9,
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
                          onBook:
                              () => _showBookingDialog(context, data, doc.id),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Doctor Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF667eea), width: 2),
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
                backgroundColor: Colors.grey[100],
                child:
                    image.isEmpty
                        ? const Icon(Icons.person, size: 32, color: Colors.grey)
                        : null,
              ),
            ),
            const SizedBox(height: 12),

            // Doctor Name
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Sector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF667eea).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                sector,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF667eea),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),

            // Doctor Details
            Expanded(
              child: Column(
                children: [
                  if (degrees.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.school, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            degrees,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  Row(
                    children: [
                      Icon(Icons.work, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Text(
                        '$experience years',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Text(
                        '$patients patients',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.attach_money,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'BDT $fees',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            // Book Button
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton(
                onPressed: onBook,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'Book Appointment',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _error = 'Not logged in';
        _loading = false;
      });
      print('Booking failed: Not logged in');
      return;
    }
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
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'dateTime': Timestamp.fromDate(dateTime),
      'doctorId': doctorId,
      'patientDocID': patientDocID,
      'status': 'pending',
    };
    // Always add a localId for offline sync/duplicate prevention
    appointmentData['localId'] =
        appointmentData['localId'] ?? const Uuid().v4();
    bool success = false;
    try {
      final online = await _isOnline();
      print('Booking appointment. Online: $online');
      if (online) {
        try {
          await FirebaseFirestore.instance
              .collection('appointments')
              .add(appointmentData);
          print('Appointment booked online.');
          // Try to sync any pending appointments
          await LocalAppointmentsService.syncPendingAppointments();
          print('Synced pending appointments.');
          success = true;
        } catch (e) {
          print('Online booking failed: $e');
          // Online booking failed, fall back to offline
        }
      }
      if (!success) {
        try {
          // Convert Timestamp fields to ISO strings for Hive
          final offlineData = Map<String, dynamic>.from(appointmentData);
          if (offlineData['createdAt'] is Timestamp) {
            offlineData['createdAt'] =
                (offlineData['createdAt'] as Timestamp)
                    .toDate()
                    .toIso8601String();
          }
          if (offlineData['dateTime'] is Timestamp) {
            offlineData['dateTime'] =
                (offlineData['dateTime'] as Timestamp)
                    .toDate()
                    .toIso8601String();
          }
          await LocalAppointmentsService.savePendingAppointment(offlineData);
          print('Appointment saved offline to Hive.');
          success = true;
        } catch (e) {
          print('Offline booking (Hive) failed: $e');
          setState(() => _error = 'Failed to save offline: $e');
        }
      }
      if (success && mounted) Navigator.of(context).pop();
      if (!success) {
        setState(() => _error = 'Failed to book appointment.');
      }
    } catch (e) {
      print('Booking failed: $e');
      setState(() => _error = 'Failed to book appointment: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage:
                      (widget.doctorData['image'] ?? '').isNotEmpty
                          ? NetworkImage(widget.doctorData['image'])
                          : null,
                  backgroundColor: Colors.grey[100],
                  child:
                      (widget.doctorData['image'] ?? '').isEmpty
                          ? const Icon(
                            Icons.person,
                            size: 25,
                            color: Colors.grey,
                          )
                          : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Book Appointment',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      Text(
                        'with ${widget.doctorData['name'] ?? ''}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Complaint Field
            TextField(
              controller: _complaintController,
              decoration: InputDecoration(
                labelText: 'Describe your symptoms/complaint',
                hintText: 'Enter your medical concern...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF667eea),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              minLines: 3,
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // Date and Time Selection
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  _selectedDate == null
                                      ? 'Select date'
                                      : DateFormat.yMMMd().format(
                                        _selectedDate!,
                                      ),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        _selectedDate == null
                                            ? Colors.grey[500]
                                            : const Color(0xFF2D3748),
                                    fontWeight: FontWeight.w500,
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
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Time',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  _selectedTime == null
                                      ? 'Select time'
                                      : _selectedTime!.format(context),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        _selectedTime == null
                                            ? Colors.grey[500]
                                            : const Color(0xFF2D3748),
                                    fontWeight: FontWeight.w500,
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
              ],
            ),

            // Error Message
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red[700], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _loading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _bookAppointment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child:
                        _loading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text(
                              'Book Appointment',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
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
