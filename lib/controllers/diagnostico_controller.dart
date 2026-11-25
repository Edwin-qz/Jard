import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/diagnostico_planta.dart';
import '../services/diagnostico_service.dart';

class DiagnosticoController extends ChangeNotifier {
  final DiagnosticoService _service = DiagnosticoService();
  final ImagePicker _picker = ImagePicker();

  bool _analizando = false;
  File? _fotoCapturada;
  DiagnosticoPlanta? _diagnostico;

  bool get analizando => _analizando;
  File? get fotoCapturada => _fotoCapturada;
  DiagnosticoPlanta? get diagnostico => _diagnostico;

  Future<void> escanearConCamara({bool usarGaleria = false}) async {
    try {
      final XFile? archivo = await _picker.pickImage(
        source: usarGaleria ? ImageSource.gallery : ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1080,
      );

      if (archivo == null) return; // El usuario canceló la captura

      _fotoCapturada = File(archivo.path);
      _analizando = true;
      _diagnostico = null;
      notifyListeners();

      _diagnostico = await _service.analizarImagen(_fotoCapturada!);
    } catch (e) {
      // Si la cámara nativa no pudo abrirse, analizar archivo si existe o dar mensaje amigable
      if (_fotoCapturada != null && _fotoCapturada!.existsSync()) {
        _diagnostico = await _service.analizarImagen(_fotoCapturada!);
      } else {
        _diagnostico = const DiagnosticoPlanta(
          esPlanta: false,
          estado: 'No válido',
          titulo: 'No se completó la captura',
          recomendacion: 'Abre la cámara nuevamente o selecciona una foto de tu galería.',
        );
      }
    } finally {
      _analizando = false;
      notifyListeners();
    }
  }

  void reiniciar() {
    _fotoCapturada = null;
    _diagnostico = null;
    notifyListeners();
  }
}
