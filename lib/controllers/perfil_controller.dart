import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Controlador de Perfil y Negocio en arquitectura MVC.
/// Administra datos personales (protegidos por sensor de huella), información comercial y fotos.
class PerfilController extends ChangeNotifier {
  String _name = 'Saul Cruz';
  String _phone = '+52 999 782 1096';
  String _email = 'saul.cruz@jardineros.mx';
  String _city = 'Mérida, Yucatán';
  String? _profileImagePath = 'assets/images/avatar_saul.jpg';
  Uint8List? _profileImageBytes;

  // Información del negocio personalizable por el usuario
  String _businessName = 'Jardineros Al Rescate S.A.P.I.';
  String _businessDescription =
      'Especialistas en diseño paisajístico, instalación de pasto en rollo, nivelación y mantenimiento integral de áreas verdes residenciales y comerciales en Mérida, Yucatán.';
  String _businessRfc = 'JAL210915AB3';
  String _businessPhone = '999 782 1096';
  String _businessAddress = 'Calle 60 #320 x 35 y 37, Centro / Altabrisa, Mérida, Yucatán';
  String _businessHours = 'Lun - Sáb: 7:00 AM - 6:00 PM';

  // Getters
  String get name => _name;
  String get phone => _phone;
  String get email => _email;
  String get city => _city;
  String? get profileImagePath => _profileImagePath;
  Uint8List? get profileImageBytes => _profileImageBytes;

  String get businessName => _businessName;
  String get businessDescription => _businessDescription;
  String get businessRfc => _businessRfc;
  String get businessPhone => _businessPhone;
  String get businessAddress => _businessAddress;
  String get businessHours => _businessHours;

  void updateProfileData({
    required String name,
    required String phone,
    required String email,
    required String city,
  }) {
    _name = name;
    _phone = phone;
    _email = email;
    _city = city;
    notifyListeners();
  }

  void updateProfilePhoto({Uint8List? bytes, String? path}) {
    _profileImageBytes = bytes;
    _profileImagePath = path;
    notifyListeners();
  }

  void clearProfilePhoto() {
    _profileImageBytes = null;
    _profileImagePath = null;
    notifyListeners();
  }

  void updateBusinessData({
    required String businessName,
    required String businessDescription,
    required String businessRfc,
    required String businessPhone,
    required String businessAddress,
    required String businessHours,
  }) {
    _businessName = businessName;
    _businessDescription = businessDescription;
    _businessRfc = businessRfc;
    _businessPhone = businessPhone;
    _businessAddress = businessAddress;
    _businessHours = businessHours;
    notifyListeners();
  }
}

