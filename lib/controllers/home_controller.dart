import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/appointment.dart';

/// Controlador del Home en arquitectura MVC.
/// Coordina la lista de citas pendientes, cita destacada y servicios GPS / llamada.
class HomeController extends ChangeNotifier {
  List<Appointment> _appointments = [];

  HomeController() {
    _loadAppointments();
  }

  List<Appointment> get appointments => _appointments;

  Appointment get heroAppointment =>
      _appointments.firstWhere((a) => a.isNextHero, orElse: () => _appointments.first);

  List<Appointment> get pendingAppointments =>
      _appointments.where((a) => !a.isNextHero).toList();

  void _loadAppointments() {
    _appointments = Appointment.sampleAppointments();
    notifyListeners();
  }

  Future<bool> makePhoneCall(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    try {
      return await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<bool> openGpsNavigation(String address) async {
    final query = Uri.encodeComponent(address);
    final Uri mapUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$query');
    try {
      return await launchUrl(mapUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

