import 'package:flutter/foundation.dart';
import '../models/appointment.dart';

class AppointmentManager extends ChangeNotifier {
  static final AppointmentManager instance = AppointmentManager._();
  AppointmentManager._() {
    _appointments = Appointment.sampleAppointments();
  }

  List<Appointment> _appointments = [];
  List<Appointment> get appointments => List.unmodifiable(_appointments);

  Appointment get heroAppointment {
    final hero = _appointments.where((a) => a.isNextHero).firstOrNull;
    if (hero != null) return hero;
    if (_appointments.isNotEmpty) return _appointments.first;
    return Appointment(
      id: 'default',
      title: 'Sin citas agendadas',
      clientName: 'N/A',
      propertyType: 'N/A',
      address: 'Mérida, Yucatán',
      time: '09:00 AM',
      dateDay: '01',
      dateMonth: 'ENE',
      status: 'Por confirmar',
    );
  }

  List<Appointment> get pendingAppointments {
    final hero = heroAppointment;
    return _appointments.where((a) => a.id != hero.id).toList();
  }

  void addAppointment(Appointment appt, {bool setAsNextHero = false}) {
    if (setAsNextHero) {
      _appointments = _appointments.map((a) => a.copyWith(isNextHero: false)).toList();
      _appointments.insert(0, appt.copyWith(isNextHero: true));
    } else {
      _appointments.insert(0, appt);
    }
    notifyListeners();
  }

  void updateStatus(String id, String newStatus) {
    final index = _appointments.indexWhere((a) => a.id == id);
    if (index != -1) {
      _appointments[index] = _appointments[index].copyWith(status: newStatus);
      notifyListeners();
    }
  }

  void removeAppointment(String id) {
    _appointments.removeWhere((a) => a.id == id);
    notifyListeners();
  }
}
