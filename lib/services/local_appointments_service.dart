import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class LocalAppointmentsService {
  static const String boxName = 'pending_appointments';

  static Future<void> savePendingAppointment(
    Map<String, dynamic> appointment,
  ) async {
    final box = await Hive.openBox(boxName);
    // Add a unique localId if not present
    appointment['localId'] ??= const Uuid().v4();
    await box.add(appointment);
  }

  static Future<List<Map<String, dynamic>>> getPendingAppointments() async {
    final box = await Hive.openBox(boxName);
    return box.values.cast<Map<String, dynamic>>().toList();
  }

  static Future<void> removePendingAppointment(int key) async {
    final box = await Hive.openBox(boxName);
    await box.delete(key);
  }

  static Future<bool> _appointmentExistsInFirestore(String localId) async {
    final query =
        await FirebaseFirestore.instance
            .collection('appointments')
            .where('localId', isEqualTo: localId)
            .limit(1)
            .get();
    return query.docs.isNotEmpty;
  }

  static dynamic _toTimestamp(dynamic value) {
    if (value is Timestamp) return value;
    if (value is DateTime) return Timestamp.fromDate(value);
    if (value is String) {
      try {
        final dt = DateTime.parse(value);
        return Timestamp.fromDate(dt);
      } catch (_) {
        return value;
      }
    }
    return value;
  }

  static Future<void> syncPendingAppointments() async {
    final box = await Hive.openBox(boxName);
    final keysToRemove = <int>[];
    for (var entry in box.toMap().entries) {
      final key = entry.key as int;
      final appointment = Map<String, dynamic>.from(entry.value as Map);
      try {
        // Ensure localId exists
        appointment['localId'] ??= const Uuid().v4();
        // Prevent duplicate posting
        final exists = await _appointmentExistsInFirestore(
          appointment['localId'],
        );
        if (exists) {
          keysToRemove.add(key);
          continue;
        }
        // Convert date fields to Timestamp
        if (appointment.containsKey('createdAt')) {
          appointment['createdAt'] = _toTimestamp(appointment['createdAt']);
        }
        if (appointment.containsKey('dateTime')) {
          appointment['dateTime'] = _toTimestamp(appointment['dateTime']);
        }
        await FirebaseFirestore.instance
            .collection('appointments')
            .add(appointment);
        keysToRemove.add(key);
      } catch (_) {
        // If sync fails, keep it for next time
      }
    }
    for (final key in keysToRemove) {
      await box.delete(key);
    }
  }
}
