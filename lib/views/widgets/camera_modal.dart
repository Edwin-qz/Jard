import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/garden_photo.dart';
import '../../services/camera_permission_service.dart';
import '../../services/plant_ai_service.dart';
import '../../theme/app_theme.dart';

class CameraModal extends StatefulWidget {
  final String initialCategory;
  final bool isFrontCamera;
  final Uint8List? initialImageBytes;
  final String? initialFilePath;

  const CameraModal({
    super.key,
    this.initialCategory = 'Diagnóstico IA',
    this.isFrontCamera = false,
    this.initialImageBytes,
    this.initialFilePath,
  });

  /// Abre la cámara previa verificación y solicitud de permisos del teléfono
  static Future<GardenPhoto?> show(
    BuildContext context, {
    String initialCategory = 'Diagnóstico IA',
    bool isFrontCamera = false,
  }) async {
    // 1. Verificación obligatoria de permisos de cámara
    final bool hasPermission =
        await CameraPermissionService.requestCameraPermission(context);

    if (!hasPermission) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color.fromARGB(255, 212, 74, 74),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: const [
                Icon(Icons.no_photography_outlined, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Permiso denegado: El teléfono no otorgó acceso a la cámara.',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return null;
    }

    if (!context.mounted) return null;

    // 2. Ofrecer opción de captura directa con el sensor del dispositivo o visor
    final selectedOption = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Diagnóstico de Plantas con Cámara e IA',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Selecciona cómo deseas capturar la evidencia para el análisis fitosanitario:',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.leafBadgeBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.leafGreen, width: 1.5),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.leafGreenAccent, size: 22),
                ),
                title: Text(
                  'Cámara del Dispositivo (Sensor Físico)',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Abre la cámara física del teléfono para tomar una foto real con el sensor',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                onTap: () => Navigator.pop(ctx, 'sensor'),
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.leafBadgeBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cyan, width: 1.5),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: AppColors.cyan, size: 22),
                ),
                title: Text(
                  'Elegir de Galería de Fotos',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Selecciona una imagen guardada en tu dispositivo',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.leafBadgeBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.amber, width: 1.5),
                  ),
                  child: const Icon(Icons.center_focus_strong, color: AppColors.amber, size: 22),
                ),
                title: Text(
                  'Visor Botánico Inteligente en Pantalla',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Abre el visor inmersivo con escaneo láser y enfoque',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                onTap: () => Navigator.pop(ctx, 'viewfinder'),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    if (selectedOption == null || !context.mounted) return null;

    if (selectedOption == 'sensor' || selectedOption == 'gallery') {
      try {
        final ImagePicker picker = ImagePicker();
        final XFile? file = await picker.pickImage(
          source: selectedOption == 'sensor' ? ImageSource.camera : ImageSource.gallery,
          preferredCameraDevice: isFrontCamera ? CameraDevice.front : CameraDevice.rear,
          imageQuality: 88,
        );
        if (file == null || !context.mounted) return null;

        final bytes = await file.readAsBytes();
        if (!context.mounted) return null;

        return await showModalBottomSheet<GardenPhoto>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.black,
          enableDrag: false,
          useSafeArea: true,
          builder: (context) => CameraModal(
            initialCategory: initialCategory,
            isFrontCamera: isFrontCamera,
            initialImageBytes: bytes,
            initialFilePath: file.path,
          ),
        );
      } catch (e) {
        debugPrint('Error en captura de imagen con sensor: $e');
        if (!context.mounted) return null;
      }
    }

    // Si eligió el visor o fallback
    return showModalBottomSheet<GardenPhoto>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      enableDrag: false,
      useSafeArea: true,
      builder: (context) => CameraModal(
        initialCategory: initialCategory,
        isFrontCamera: isFrontCamera,
      ),
    );
  }

  @override
  State<CameraModal> createState() => _CameraModalState();
}

class _CameraModalState extends State<CameraModal> with TickerProviderStateMixin {
  late bool _isFrontCamera;
  bool _isFlashOn = false;
  bool _isGridOn = true;
  double _zoomLevel = 1.0;
  Offset? _focusPoint;
  bool _isCapturing = false;
  bool _isAnalyzingAI = false;
  bool _isReviewing = false;

  Uint8List? _capturedImageBytes;
  String? _capturedFilePath;

  late final AnimationController _focusAnimController;
  late final AnimationController _scanAnimController;
  late final TextEditingController _photoNoteController;

  // Resultado del diagnóstico fitosanitario con IA
  bool _aiIsHealthy = true;
  String _aiDiagnosis = 'Planta Sana • Follaje Saludable';
  double _aiConfidence = 0.97;
  String _aiTreatment = 'Planta en óptimo estado. Mantener programa de riego habitual.';
  String _plantSpecimenName = 'Césped San Agustín / Ficus benjamina';

  // Validación botánica de IA (Filtro inteligente que distingue Plantas de Humanos, Perros y Objetos)
  bool _isPlantDetected = true;
  String? _nonPlantReason;
  String _detectedSubjectName = 'Planta';
  AiSubjectType _targetSimulation = AiSubjectType.plant;

  @override
  void initState() {
    super.initState();
    _isFrontCamera = widget.isFrontCamera;
    _photoNoteController = TextEditingController();

    _focusAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    if (widget.initialImageBytes != null) {
      _capturedImageBytes = widget.initialImageBytes;
      _capturedFilePath = widget.initialFilePath;
      _isAnalyzingAI = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _processAiDiagnosis();
      });
    }
  }

  @override
  void dispose() {
    _focusAnimController.dispose();
    _scanAnimController.dispose();
    _photoNoteController.dispose();
    super.dispose();
  }

  void _onTapViewfinder(TapDownDetails details) {
    setState(() {
      _focusPoint = details.localPosition;
    });
    _focusAnimController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _focusPoint = null;
        });
      }
    });
  }

  Future<void> _processAiDiagnosis() async {
    setState(() => _isAnalyzingAI = true);

    // Evaluación del motor de Inteligencia Artificial para distinguir Plantas vs Humanos vs Perros
    await Future.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;

    final result = await PlantAiService.classifyImage(
      imageBytes: _capturedImageBytes,
      filePath: _capturedFilePath,
      isFrontCamera: _isFrontCamera && widget.initialCategory != 'Perfil',
      forcedSimulationType: _targetSimulation,
    );

    _isPlantDetected = result.isPlant;
    _detectedSubjectName = result.label;
    _nonPlantReason = result.reason;

    if (result.isPlant) {
      _aiIsHealthy = result.isHealthy ?? true;
      _aiDiagnosis = result.diagnosisTitle ?? 'Planta Sana • Follaje Óptimo';
      _aiConfidence = result.confidence;
      _aiTreatment = result.treatment ?? 'Riego habitual recomendado.';
      _plantSpecimenName = result.specimenName ?? 'Muestra Vegetal / Follaje Verde';
    }

    setState(() {
      _isAnalyzingAI = false;
      _isReviewing = true;
    });
  }

  Future<void> _takePhotoAndDiagnose() async {
    // 1. Intentar activar el sensor de hardware del teléfono / navegador
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice:
            _isFrontCamera ? CameraDevice.front : CameraDevice.rear,
        imageQuality: 88,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        if (!mounted) return;
        setState(() {
          _capturedImageBytes = bytes;
          _capturedFilePath = file.path;
        });
        await _processAiDiagnosis();
        return;
      } else {
        return;
      }
    } catch (e) {
      debugPrint('Aviso cámara de dispositivo: $e');
    }

    // 2. Si no hay sensor físico disponible, fallback a captura del visor
    setState(() => _isCapturing = true);
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() => _isCapturing = false);
    await _processAiDiagnosis();
  }

  Future<void> _pickFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        if (!mounted) return;
        setState(() {
          _capturedImageBytes = bytes;
          _capturedFilePath = file.path;
        });
        await _processAiDiagnosis();
      }
    } catch (e) {
      debugPrint('Aviso galería: $e');
    }
  }

  void _confirmPhoto() {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final photo = GardenPhoto(
      id: 'photo_${now.millisecondsSinceEpoch}',
      title: _plantSpecimenName,
      category: widget.initialCategory,
      imageBytes: _capturedImageBytes,
      assetPath: _capturedFilePath,
      timestamp: timeStr,
      notes: _photoNoteController.text.trim().isEmpty
          ? _aiTreatment
          : '${_photoNoteController.text.trim()} | $_aiTreatment',
      isHealthy: _aiIsHealthy,
      aiDiagnosisStatus: _aiDiagnosis,
      aiConfidence: _aiConfidence,
      aiTreatment: _aiTreatment,
    );

    Navigator.pop(context, photo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isReviewing
            ? _buildReviewScreen()
            : (_isAnalyzingAI ? _buildAnalyzingScreen() : _buildCameraScreen()),
      ),
    );
  }

  Widget _buildCameraScreen() {
    return Column(
      children: [
        // Barra Superior de Controles
        _buildTopBar(),

        // Visor de Cámara para Diagnóstico de Plantas
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Fondo de sensor de cámara digital con textura óptica
                  GestureDetector(
                    onTapDown: _onTapViewfinder,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.1,
                          colors: [
                            Color(0xFF16241D),
                            Color(0xFF0D1712),
                            Color(0xFF050806),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isFrontCamera
                                  ? Icons.person_outline_rounded
                                  : Icons.energy_savings_leaf_rounded,
                              color: AppColors.leafGreen.withValues(alpha: 0.35),
                              size: 110,
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.leafGreen.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                _isFrontCamera
                                    ? 'CÁMARA FRONTAL • MODO PERFIL'
                                    : 'ENFOCA LA PLANTA, HOJA O CÉSPED A EVALUAR',
                                style: const TextStyle(
                                  color: AppColors.leafGreenAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Haz de escaneo botánico de IA animado
                  if (!_isFrontCamera)
                    AnimatedBuilder(
                      animation: _scanAnimController,
                      builder: (context, child) {
                        return Positioned(
                          top: _scanAnimController.value * 320,
                          left: 20,
                          right: 20,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  AppColors.leafGreenAccent.withValues(alpha: 0.9),
                                  Colors.transparent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.leafGreenAccent.withValues(alpha: 0.6),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  // Cuadrícula de tercios
                  if (_isGridOn) _buildGridOverlay(),

                  // Corchetes de enfoque botánico en las 4 esquinas
                  _buildViewfinderCorners(),

                  // Anillo de enfoque táctil
                  if (_focusPoint != null)
                    Positioned(
                      left: _focusPoint!.dx - 28,
                      top: _focusPoint!.dy - 28,
                      child: AnimatedBuilder(
                        animation: _focusAnimController,
                        builder: (context, child) {
                          final scale = 1.0 - (_focusAnimController.value * 0.2);
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.leafGreenAccent,
                                  width: 2,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.filter_center_focus,
                                  color: AppColors.leafGreenAccent,
                                  size: 18,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // Destello de obturador
                  if (_isCapturing)
                    Container(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),

                  // Indicador de modo de escaneo IA
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.leafGreen.withValues(alpha: 0.7),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.leafGreenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'IA FITOSANITARIA ACTIVA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Zoom Pill
                  Positioned(
                    bottom: 14,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [0.5, 1.0, 2.0].map((zoom) {
                            final isSel = _zoomLevel == zoom;
                            return GestureDetector(
                              onTap: () => setState(() => _zoomLevel = zoom),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSel ? AppColors.leafGreen : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${zoom}x',
                                  style: TextStyle(
                                    color: isSel ? Colors.white : Colors.white70,
                                    fontSize: 11.5,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Barra Inferior de Disparo
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 26),
            onPressed: () => Navigator.pop(context),
          ),
          // Selector interactivo para probar IA: Distingue Plantas vs Humanos vs Perros vs Objetos
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSimulationChip(AiSubjectType.plant, '🌱 Planta', AppColors.leafGreen),
                const SizedBox(width: 4),
                _buildSimulationChip(AiSubjectType.human, '👤 Humano', AppColors.amber),
                const SizedBox(width: 4),
                _buildSimulationChip(AiSubjectType.pet, '🐕 Perro', AppColors.coral),
                const SizedBox(width: 4),
                _buildSimulationChip(AiSubjectType.inanimate, '🧱 Objeto', Colors.grey),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color: _isFlashOn ? AppColors.amber : Colors.white,
                  size: 22,
                ),
                onPressed: () => setState(() => _isFlashOn = !_isFlashOn),
              ),
              IconButton(
                icon: Icon(
                  _isGridOn ? Icons.grid_on : Icons.grid_off,
                  color: _isGridOn ? AppColors.leafGreenAccent : Colors.white70,
                  size: 22,
                ),
                onPressed: () => setState(() => _isGridOn = !_isGridOn),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador del sensor de hardware
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            margin: const EdgeInsets.only(bottom: 12, right: 0),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.leafGreenAccent.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.sensors, color: AppColors.leafGreenAccent, size: 15),
                SizedBox(width: 6),
                Text(
                  'SENSOR DE CÁMARA ACTIVO',
                  style: TextStyle(
                    color: AppColors.leafGreenAccent,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Botón de Galería
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 20),
                ),
                tooltip: 'Elegir de galería',
                onPressed: _pickFromGallery,
              ),

              // Botón Central de Disparo: Activa el sensor de hardware
              GestureDetector(
                onTap: _takePhotoAndDiagnose,
                child: Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.leafGreen,
                    ),
                    child: const Center(
                      child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 32),
                    ),
                  ),
                ),
              ),

              // Botón para cambiar cámara (trasera / frontal)
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 20),
                ),
                tooltip: 'Cambiar cámara',
                onPressed: () => setState(() => _isFrontCamera = !_isFrontCamera),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.leafBadgeBg,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.leafGreen, width: 2),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.leafGreenAccent,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Analizando espécimen vegetal con IA...',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Evaluando clorofila, hongos y estado de salud foliar',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewScreen() {
    if (!_isPlantDetected) {
      return _buildNonPlantRejectionScreen();
    }

    final statusColor = _aiIsHealthy ? AppColors.leafGreen : AppColors.amber;
    final statusBadgeBg = _aiIsHealthy ? AppColors.leafBadgeBg : AppColors.amberBg;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Diagnóstico de IA',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBadgeBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  _aiIsHealthy ? 'PLANTA SANA' : 'REQUIERE TRATAMIENTO',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Foto Real Capturada con el Sensor de la Cámara
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFF16241D),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: statusColor.withValues(alpha: 0.6), width: 1.5),
                ),
                child: _capturedImageBytes != null
                    ? Image.memory(
                        _capturedImageBytes!,
                        fit: BoxFit.cover,
                      )
                    : Icon(
                        _aiIsHealthy
                            ? Icons.energy_savings_leaf_rounded
                            : Icons.warning_amber_rounded,
                        color: statusColor,
                        size: 70,
                      ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Tarjeta de Diagnóstico de Salud de la Planta
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF2D333B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.6), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _aiIsHealthy ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                      color: statusColor,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _aiDiagnosis,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Confianza del modelo IA: ${(_aiConfidence * 100).toStringAsFixed(1)}%',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 22, color: Color(0xFF444C56)),
                Text(
                  'Recomendación agronómica del jardinero:',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  _aiTreatment,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.3),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Nota adicional del jardinero
          TextField(
            controller: _photoNoteController,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Añadir nota adicional sobre la planta o el jardín...',
              labelText: 'Notas del Jardinero',
              prefixIcon: const Icon(Icons.notes, color: AppColors.leafGreen),
            ),
            maxLines: 2,
          ),

          const SizedBox(height: 24),

          // Botones de Acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _isReviewing = false),
                  icon: const Icon(Icons.refresh, color: AppColors.coral),
                  label: const Text('Repetir foto', style: TextStyle(color: AppColors.coral)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.coral),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _confirmPhoto,
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.leafGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationChip(AiSubjectType type, String label, Color color) {
    final isSelected = _targetSimulation == type;
    return InkWell(
      onTap: () {
        setState(() {
          _targetSimulation = type;
        });
        String message = '';
        switch (type) {
          case AiSubjectType.plant:
            message = 'Objetivo: Vegetación / Planta -> La IA emitirá diagnóstico fitosanitario completo.';
            break;
          case AiSubjectType.human:
            message = 'Objetivo: Humano / Persona -> La IA denegará el diagnóstico botánico.';
            break;
          case AiSubjectType.pet:
            message = 'Objetivo: Perro / Mascota -> La IA denegará el diagnóstico botánico.';
            break;
          case AiSubjectType.inanimate:
            message = 'Objetivo: Objeto inanimado -> La IA denegará el diagnóstico.';
            break;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            backgroundColor: isSelected ? color : AppColors.surfaceElevated,
            content: Text(message),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.35) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.white24,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildNonPlantRejectionScreen() {
    IconData rejectionIcon = Icons.category_rounded;
    if (_detectedSubjectName.toLowerCase().contains('humano') ||
        _detectedSubjectName.toLowerCase().contains('persona')) {
      rejectionIcon = Icons.person_off_rounded;
    } else if (_detectedSubjectName.toLowerCase().contains('perro') ||
        _detectedSubjectName.toLowerCase().contains('mascota')) {
      rejectionIcon = Icons.pets_rounded;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Diagnóstico de IA',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.coralBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.coral),
                ),
                child: Text(
                  'NO ES UNA PLANTA (${_detectedSubjectName.toUpperCase()})',
                  style: const TextStyle(
                    color: AppColors.coral,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Foto rechazada con indicador del sujeto detectado (humano, perro u objeto)
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1414),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.coral.withValues(alpha: 0.8), width: 2),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_capturedImageBytes != null)
                      Image.memory(
                        _capturedImageBytes!,
                        fit: BoxFit.cover,
                      )
                    else
                      Center(
                        child: Icon(rejectionIcon, color: AppColors.coral, size: 70),
                      ),
                    Container(
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.coralBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.coral),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(rejectionIcon, color: AppColors.coral, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'DETECTADO: ${_detectedSubjectName.toUpperCase()}',
                              style: const TextStyle(
                                color: AppColors.coral,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Tarjeta de Alerta de Rechazo Fitosanitario
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF2D1E1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.coral.withValues(alpha: 0.7), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(rejectionIcon, color: AppColors.coral, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Diagnóstico Botánico Denegado: $_detectedSubjectName',
                            style: const TextStyle(
                              color: AppColors.coral,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _nonPlantReason ??
                                'La IA identificó a $_detectedSubjectName. El diagnóstico fitosanitario es exclusivo para vegetación.',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, color: Color(0xFF552E2E)),
                Text(
                  '¿Por qué solo se diagnostican plantas?',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'El motor de IA está entrenado exclusivamente para calcular índices de clorofila, plagas foliares y déficit de nutrientes en plantas y pasto. Cuando detecta personas, perros u objetos inanimados, el diagnóstico se deniega para evitar tratamientos erróneos.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Botón principal: Reintentar con una planta real
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isReviewing = false;
                  _isPlantDetected = true;
                  _targetSimulation = AiSubjectType.plant;
                });
              },
              icon: const Icon(Icons.eco_rounded, color: Colors.white),
              label: const Text(
                'Reintentar: Enfocar una planta o césped',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.leafGreen,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickFromGallery,
              icon: const Icon(Icons.photo_library_outlined, color: Colors.white70),
              label: const Text(
                'Elegir otra imagen de la galería',
                style: TextStyle(color: Colors.white70),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridOverlay() {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GridPainter(),
      ),
    );
  }

  Widget _buildViewfinderCorners() {
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: _cornerBracket(top: true, left: true),
            ),
            Align(
              alignment: Alignment.topRight,
              child: _cornerBracket(top: true, left: false),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: _cornerBracket(top: false, left: true),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: _cornerBracket(top: false, left: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cornerBracket({required bool top, required bool left}) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: Colors.white70, width: 2) : BorderSide.none,
          bottom: !top ? const BorderSide(color: Colors.white70, width: 2) : BorderSide.none,
          left: left ? const BorderSide(color: Colors.white70, width: 2) : BorderSide.none,
          right: !left ? const BorderSide(color: Colors.white70, width: 2) : BorderSide.none,
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1;

    final x1 = size.width / 3;
    final x2 = size.width * 2 / 3;
    final y1 = size.height / 3;
    final y2 = size.height * 2 / 3;

    canvas.drawLine(Offset(x1, 0), Offset(x1, size.height), paint);
    canvas.drawLine(Offset(x2, 0), Offset(x2, size.height), paint);
    canvas.drawLine(Offset(0, y1), Offset(size.width, y1), paint);
    canvas.drawLine(Offset(0, y2), Offset(size.width, y2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
