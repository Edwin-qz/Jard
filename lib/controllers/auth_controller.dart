import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Controlador de Autenticación y Sesión en arquitectura MVC.
/// Gestiona credenciales, demo login y tema de la aplicación.
class AuthController extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isDarkMode = true;
  String _currentUserName = 'Saul Cruz';
  String _currentUserRole = 'Jardinero profesional';

  bool get isLoggedIn => _isLoggedIn;
  bool get isDarkMode => _isDarkMode;
  String get currentUserName => _currentUserName;
  String get currentUserRole => _currentUserRole;

  void toggleTheme(bool isDark) {
    _isDarkMode = isDark;
    AppColors.isDarkMode = isDark;
    notifyListeners();
  }

  bool login(String email, String password) {
    if (email.isNotEmpty && password.isNotEmpty) {
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void loginDemoSaulCruz() {
    _isLoggedIn = true;
    _currentUserName = 'Saul Cruz';
    _currentUserRole = 'Jardinero profesional';
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }
}

