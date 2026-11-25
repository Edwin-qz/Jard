import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Servicio de autenticación biométrica nativa del teléfono (Huella Digital / Biometría del SO).
/// Utiliza el hardware real del dispositivo mediante local_auth.
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Comprueba si el teléfono cuenta con hardware biométrico disponible y configurado
  static Future<bool> isBiometricAvailable() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Retorna los tipos de biometría disponibles en el dispositivo (Huella, Rostro, etc.)
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return <BiometricType>[];
    }
  }

  /// Solicita la huella digital o biometría nativa del propio teléfono.
  /// Lanza el diálogo nativo de Android / iOS (BiometricPrompt / Touch ID / Face ID).
  static Future<BiometricResult> authenticateWithPhoneBiometrics({
    String reason = 'Coloca tu huella en el sensor del teléfono para autenticar tu identidad.',
  }) async {
    try {
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return BiometricResult(
          success: false,
          errorMessage: 'El teléfono no cuenta con sensor biométrico o no está habilitado en los ajustes del sistema.',
          hasHardware: false,
        );
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );

      return BiometricResult(
        success: didAuthenticate,
        errorMessage: didAuthenticate ? null : 'Huella no reconocida o autenticación cancelada por el usuario.',
        hasHardware: true,
      );
    } on PlatformException catch (e) {
      return BiometricResult(
        success: false,
        errorMessage: 'Error del sensor biométrico: ${e.message ?? e.code}',
        hasHardware: true,
      );
    } catch (e) {
      return BiometricResult(
        success: false,
        errorMessage: 'Ocurrió un error inesperado al leer la huella: $e',
        hasHardware: false,
      );
    }
  }
}

class BiometricResult {
  final bool success;
  final String? errorMessage;
  final bool hasHardware;

  BiometricResult({
    required this.success,
    this.errorMessage,
    required this.hasHardware,
  });
}
