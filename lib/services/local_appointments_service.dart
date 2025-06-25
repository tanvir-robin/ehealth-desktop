import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocalAppointmentsService {
  static const String boxName = 'pending_appointments';

  static Future<void> savePendingAppointment(
    Map<String, dynamic> appointment,
  ) async {
    final box = await Hive.openBox(boxName);
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

  static Future<void> syncPendingAppointments() async {
    final box = await Hive.openBox(boxName);
    final keysToRemove = <int>[];
    for (var entry in box.toMap().entries) {
      final key = entry.key as int;
      final appointment = entry.value as Map<String, dynamic>;
      try {
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
