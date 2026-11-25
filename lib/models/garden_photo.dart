import 'dart:typed_data';

class GardenPhoto {
  final String id;
  final String title;
  final String category;
  final String? assetPath;
  final Uint8List? imageBytes;
  final String timestamp;
  final String? notes;

  // Diagnóstico de salud de plantas mediante Inteligencia Artificial
  final bool? isHealthy;
  final String? aiDiagnosisStatus;
  final double? aiConfidence;
  final String? aiTreatment;

  GardenPhoto({
    required this.id,
    required this.title,
    required this.category,
    this.assetPath,
    this.imageBytes,
    required this.timestamp,
    this.notes,
    this.isHealthy,
    this.aiDiagnosisStatus,
    this.aiConfidence,
    this.aiTreatment,
  });

  /// Lista vacía por defecto sin imágenes falsas precargadas
  static List<GardenPhoto> samplePhotos() => [];
}
