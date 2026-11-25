import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class CameraPermissionService {
  static const MethodChannel _channel =
      MethodChannel('com.jardineros.al_rescate/camera_permission');

  static bool _hasPermission = false;

  /// Retorna si el permiso ya fue concedido previamente
  static bool get hasPermission => _hasPermission;

  /// Solicita el permiso de la cámara al sistema telefónico.
  /// Si el sistema o el usuario lo aprueba, retorna true; de lo contrario false.
  static Future<bool> requestCameraPermission(BuildContext context) async {
    if (_hasPermission) {
      return true;
    }

    bool isGranted = false;

    // 1. Intentar solicitar permiso nativo vía MethodChannel (Android/iOS)
    try {
      final bool? nativeResult =
          await _channel.invokeMethod<bool>('requestCameraPermission');
      if (nativeResult != null && nativeResult) {
        _hasPermission = true;
        return true;
      }
    } catch (_) {
      // Si la plataforma no soporta MethodChannel nativo (ej. Web o Desktop),
      // procedemos con el diálogo de solicitud de permiso del sistema.
    }

    // 2. Diálogo modal estilo sistema operativo (Android/iOS) para confirmación de permiso
    if (context.mounted) {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: AppColors.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: AppColors.border, width: 1.5),
            ),
            icon: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.leafBadgeBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.leafGreen, width: 1.5),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: AppColors.leafGreenAccent,
                size: 32,
              ),
            ),
            title: Text(
              '¿Permitir que "Jardineros Al Rescate" tome fotos y grabe videos?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Esta app requiere acceso a la cámara de tu teléfono para capturar fotos de las plantas y realizar diagnósticos de salud foliar con Inteligencia Artificial (detectar plantas sanas, plagas o enfermedades).',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actionsOverflowButtonSpacing: 8,
            actions: [
              // Opción 1: Mientras la app está en uso
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.leafGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Mientras la app está en uso',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // Opción 2: Solo esta vez
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.leafGreen),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Solo esta vez',
                    style: TextStyle(
                      color: AppColors.leafGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Opción 3: No permitir
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    'No permitir',
                    style: TextStyle(
                      color: AppColors.coral,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );

      isGranted = result ?? false;
    }

    if (isGranted) {
      _hasPermission = true;
    } else {
      _hasPermission = false;
    }

    return _hasPermission;
  }
}

