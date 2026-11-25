import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../widgets/camera_modal.dart';
import '../../models/garden_photo.dart';
import '../../models/quote_item.dart';
import '../../models/appointment.dart';
import '../../services/appointment_manager.dart';
import '../../services/database_service.dart';
import '../../services/pdf_quote_service.dart';
import '../../theme/app_theme.dart';
import '../../controllers/diagnostico_controller.dart';

class CotizadorScreen extends StatefulWidget {
  final VoidCallback onOpenNotifications;

  const CotizadorScreen({
    super.key,
    required this.onOpenNotifications,
  });

  @override
  State<CotizadorScreen> createState() => _CotizadorScreenState();
}

class _CotizadorScreenState extends State<CotizadorScreen> {
  final TextEditingController _clientNameController =
      TextEditingController(text: 'María González');
  final TextEditingController _clientPhoneController =
      TextEditingController(text: '9994192883');
  final TextEditingController _addressController =
      TextEditingController(text: 'Calle 19 #204 x 24 y 26, Col. Altabrisa, Mérida, Yucatán');
  final TextEditingController _appointmentDateController =
      TextEditingController(text: 'Rellenar');
  final DiagnosticoController diagnosticoCtrl = DiagnosticoController();

  String? _clientNameError;
  String? _clientPhoneError;

  DateTime _selectedDate = DateTime(2026, 10, 31);
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 30);
  bool _isFrequentClient = false;
  int _recurrenceDays = 15;
  late List<QuoteServiceItem> _services;
  bool _isGeneratingPdf = false;
  final List<GardenPhoto> _capturedPhotos = GardenPhoto.samplePhotos();

  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _services = QuoteServiceItem.defaultServices();
    _updateAppointmentDateText();
    diagnosticoCtrl.addListener(_onDiagnosticoUpdated);
  }

  void _onDiagnosticoUpdated() {
    if (!mounted) return;
    if (!diagnosticoCtrl.analizando &&
        diagnosticoCtrl.diagnostico != null &&
        diagnosticoCtrl.fotoCapturada != null) {
      final diag = diagnosticoCtrl.diagnostico!;
      final file = diagnosticoCtrl.fotoCapturada!;
      final alreadyAdded = _capturedPhotos.any(
        (p) => p.title == diag.titulo && p.notes == diag.recomendacion,
      );
      if (!alreadyAdded) {
        final isHealthy = diag.esPlanta &&
            (diag.estado.toLowerCase().contains('saludable') ||
                diag.estado.toLowerCase().contains('óptimo'));
        _capturedPhotos.add(
          GardenPhoto(
            id: 'ia_${DateTime.now().millisecondsSinceEpoch}',
            title: diag.titulo,
            category: 'Diagnóstico IA',
            timestamp: DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
            isHealthy: isHealthy,
            aiDiagnosisStatus: '${diag.estado}: ${diag.recomendacion}',
            notes: diag.recomendacion,
            imageBytes: file.existsSync() ? file.readAsBytesSync() : null,
          ),
        );
      }
    }
    setState(() {});
  }

  void _updateAppointmentDateText() {
    final dayName = _getDayName(_selectedDate.weekday);
    final monthName = _getMonthName(_selectedDate.month);
    final formattedTime = _formatTimeOfDay(_selectedTime);
    _appointmentDateController.text =
        '$dayName, ${_selectedDate.day} de $monthName ${_selectedDate.year} • $formattedTime';
  }

  String _getMonthAbbr(int month) {
    const months = ['ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN', 'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return 'MES';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _formatRecurrenceNextDate() {
    final next = _selectedDate.add(Duration(days: _recurrenceDays));
    final dayName = _getDayName(next.weekday);
    final monthName = _getMonthName(next.month);
    return '$dayName, ${next.day} de $monthName ${next.year}';
  }

  void _showEditRecurrenceDialog() {
    int tempDays = _recurrenceDays;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: const [
                  Icon(Icons.repeat_rounded, color: AppColors.leafGreen, size: 24),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Frecuencia de Citas',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'A los clientes frecuentes se les agenda automáticamente cita cada 15 días o el intervalo que elijas:',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [7, 14, 15, 21, 30].map((days) {
                      final isSelected = tempDays == days;
                      return ChoiceChip(
                        label: Text(
                          days == 15 ? 'Cada 15 días (Recomendado)' : 'Cada $days días',
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.leafGreen,
                        backgroundColor: AppColors.surfaceElevated,
                        onSelected: (val) {
                          if (val) setDlgState(() => tempDays = days);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _recurrenceDays = tempDays;
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.leafGreen),
                  child: const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _pickAppointmentTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: 'Hora de la cita',
      confirmText: 'Seleccionar',
      cancelText: 'Cancelar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.mint,
              onPrimary: Colors.white,
              surface: AppColors.surfaceCard,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _updateAppointmentDateText();
      });
    }
  }

  void _confirmAppointmentAndSendToHome() {
    final rawName = _clientNameController.text.trim();
    final rawPhone = _clientPhoneController.text.trim();
    if (rawName.isEmpty) {
      setState(() => _clientNameError = 'Ingresa el nombre del cliente');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa el nombre del cliente.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (rawPhone.isEmpty) {
      setState(() => _clientPhoneError = 'Ingresa el teléfono del cliente');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa el teléfono celular del cliente.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final selectedServicesList = _services.where((s) => s.isSelected).toList();
    final serviceSummary = selectedServicesList.isNotEmpty
        ? selectedServicesList.map((s) => s.name).join(', ')
        : 'Servicio general de jardinería';

    final monthAbbr = _getMonthAbbr(_selectedDate.month);
    final timeStr = _formatTimeOfDay(_selectedTime);

    final mainAppt = Appointment(
      id: 'appt_${DateTime.now().millisecondsSinceEpoch}',
      title: serviceSummary,
      clientName: rawName,
      clientPhone: rawPhone,
      propertyType: _isFrequentClient ? 'Cliente Frecuente (Recurrente)' : 'Residencial',
      address: _addressController.text.trim().isEmpty
          ? 'Mérida, Yucatán'
          : _addressController.text.trim(),
      time: timeStr,
      dateDay: _selectedDate.day.toString().padLeft(2, '0'),
      dateMonth: monthAbbr,
      status: 'Confirmada',
      isNextHero: true,
    );

    AppointmentManager.instance.addAppointment(mainAppt, setAsNextHero: true);

    if (_isFrequentClient) {
      final nextDate = _selectedDate.add(Duration(days: _recurrenceDays));
      final nextMonthAbbr = _getMonthAbbr(nextDate.month);
      final recurringAppt = Appointment(
        id: 'appt_${DateTime.now().millisecondsSinceEpoch}_rec',
        title: 'Mantenimiento recurrente: $serviceSummary',
        clientName: rawName,
        clientPhone: rawPhone,
        propertyType: 'Cliente Frecuente (Cada $_recurrenceDays días)',
        address: _addressController.text.trim().isEmpty
            ? 'Mérida, Yucatán'
            : _addressController.text.trim(),
        time: timeStr,
        dateDay: nextDate.day.toString().padLeft(2, '0'),
        dateMonth: nextMonthAbbr,
        status: 'Confirmada',
        isNextHero: false,
      );
      AppointmentManager.instance.addAppointment(recurringAppt, setAsNextHero: false);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.leafGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _isFrequentClient
                    ? '✅ ¡Cita confirmada! Agendada en Inicio y programada recurrente cada $_recurrenceDays días.'
                    : '✅ ¡Cita confirmada con éxito! Ya puedes verla en la pantalla de Inicio.',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Lunes';
      case 2:
        return 'Martes';
      case 3:
        return 'Miércoles';
      case 4:
        return 'Jueves';
      case 5:
        return 'Viernes';
      case 6:
        return 'Sábado';
      case 7:
        return 'Domingo';
      default:
        return '';
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Enero';
      case 2:
        return 'Febrero';
      case 3:
        return 'Marzo';
      case 4:
        return 'Abril';
      case 5:
        return 'Mayo';
      case 6:
        return 'Junio';
      case 7:
        return 'Julio';
      case 8:
        return 'Agosto';
      case 9:
        return 'Septiembre';
      case 10:
        return 'Octubre';
      case 11:
        return 'Noviembre';
      case 12:
        return 'Diciembre';
      default:
        return '';
    }
  }

  @override
  void dispose() {
    diagnosticoCtrl.removeListener(_onDiagnosticoUpdated);
    diagnosticoCtrl.dispose();
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _addressController.dispose();
    _appointmentDateController.dispose();
    super.dispose();
  }

  double get _totalPrice {
    double total = 0.0;
    for (final service in _services) {
      if (service.isSelected) {
        total += service.subtotal;
      }
    }
    return total;
  }

  double get _totalSquareMeters {
    double total = 0.0;
    for (final service in _services) {
      if (service.isSelected && !service.isFixedPrice) {
        total += service.quantity;
      }
    }
    return total;
  }

  String _formatM2(double value) {
    if (value % 1 == 0) {
      return '${value.toInt()} m²';
    }
    return '${value.toStringAsFixed(1)} m²';
  }

  Future<void> _pickAppointmentDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      helpText: 'Día de confirmación de la cita',
      confirmText: 'Seleccionar',
      cancelText: 'Cancelar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.mint,
              onPrimary: Colors.white,
              surface: AppColors.surfaceCard,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _updateAppointmentDateText();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top App Header
                    _buildHeader(),

                    const SizedBox(height: 20),

                    // Step 01: Datos del cliente y confirmación de cita
                    _buildStepSection(
                      stepNumber: '01',
                      title: 'Datos del cliente y cita',
                      subtitle: 'Información que se incluirá en el PDF y mensaje de WhatsApp',
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Selector de Tipo de Cliente (Frecuente vs No Frecuente / Ocasional)
                          Text(
                            'Tipo de cliente',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border, width: 1),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setState(() => _isFrequentClient = false),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: !_isFrequentClient ? AppColors.surfaceCard : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: !_isFrequentClient
                                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.person_outline,
                                            size: 16,
                                            color: !_isFrequentClient ? AppColors.leafGreen : AppColors.textMuted,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Cliente Ocasional',
                                            style: TextStyle(
                                              color: !_isFrequentClient ? AppColors.textPrimary : AppColors.textMuted,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setState(() => _isFrequentClient = true),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _isFrequentClient ? AppColors.leafGreen : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: _isFrequentClient
                                            ? [BoxShadow(color: AppColors.leafGreen.withValues(alpha: 0.3), blurRadius: 6)]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.autorenew_rounded,
                                            size: 16,
                                            color: _isFrequentClient ? Colors.white : AppColors.textMuted,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Cliente Frecuente',
                                            style: TextStyle(
                                              color: _isFrequentClient ? Colors.white : AppColors.textMuted,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Banner configurable para cliente frecuente (Cada 15 días por defecto)
                          if (_isFrequentClient)
                            Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.leafBadgeBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.leafGreen.withValues(alpha: 0.6), width: 1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.repeat_rounded, color: AppColors.leafGreenAccent, size: 18),
                                          SizedBox(width: 8),
                                          Text(
                                            'Cita periódica automática',
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                      InkWell(
                                        onTap: _showEditRecurrenceDialog,
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.leafGreen.withValues(alpha: 0.3),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppColors.leafGreenAccent.withValues(alpha: 0.5)),
                                          ),
                                          child: Text(
                                            'Cada $_recurrenceDays días (Tocar)',
                                            style: const TextStyle(
                                              color: AppColors.leafGreenAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'A clientes frecuentes se les agenda automáticamente cita cada $_recurrenceDays días según su tipo de servicio (modificable).',
                                    style: const TextStyle(color: AppColors.leafGreenLight, fontSize: 11.5),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Próxima fecha recurrente: ${_formatRecurrenceNextDate()}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Nombre del cliente (Solo letras)
                          Text(
                            'Nombre del cliente (solo letras)',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 7),
                          TextField(
                            controller: _clientNameController,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                            ],
                            decoration: InputDecoration(
                              hintText: 'Ej. María González',
                              errorText: _clientNameError,
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: AppColors.textMuted,
                                size: 20,
                              ),
                            ),
                            onChanged: (_) {
                              if (_clientNameError != null) setState(() => _clientNameError = null);
                            },
                          ),

                          const SizedBox(height: 14),

                          // Número de cliente / Teléfono WhatsApp (Solo números)
                          Text(
                            'Número de cliente / WhatsApp (solo números celular)',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 7),
                          TextField(
                            controller: _clientPhoneController,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: InputDecoration(
                              hintText: 'Ej. 5541928831 (10 dígitos sin letras)',
                              errorText: _clientPhoneError,
                              prefixIcon: const Icon(
                                Icons.phone_android_rounded,
                                color: AppColors.leafGreen,
                                size: 20,
                              ),
                            ),
                            onChanged: (_) {
                              if (_clientPhoneError != null) setState(() => _clientPhoneError = null);
                            },
                          ),

                          const SizedBox(height: 14),

                          // Dirección del servicio
                          Text(
                            'Dirección del servicio',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 7),
                          TextField(
                            controller: _addressController,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Calle, número y colonia',
                              prefixIcon: Icon(
                                Icons.location_on_outlined,
                                color: AppColors.textMuted,
                                size: 20,
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Fecha y Hora de la cita (Cuadros táctiles directos, sin lápiz)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Fecha y Hora de la Cita',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Tocar para agendar',
                                style: TextStyle(
                                  color: AppColors.mint,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              // Cuadrito táctil: FECHA
                              Expanded(
                                flex: 3,
                                child: InkWell(
                                  onTap: _pickAppointmentDate,
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceElevated,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppColors.mint.withValues(alpha: 0.5), width: 1.2),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_month_outlined, color: AppColors.mint, size: 16),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Fecha de cita',
                                              style: TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          '${_selectedDate.day} ${_getMonthAbbr(_selectedDate.month)} ${_selectedDate.year}',
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          _getDayName(_selectedDate.weekday),
                                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Cuadrito táctil: HORA
                              Expanded(
                                flex: 2,
                                child: InkWell(
                                  onTap: _pickAppointmentTime,
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceElevated,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppColors.mint.withValues(alpha: 0.5), width: 1.2),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.access_time_rounded, color: AppColors.mint, size: 16),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Hora cita',
                                              style: TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          _formatTimeOfDay(_selectedTime),
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Text(
                                          'Toca cambiar',
                                          style: TextStyle(color: AppColors.mint, fontSize: 11.5, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Botón para confirmar y registrar la cita en Inicio
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _confirmAppointmentAndSendToHome,
                              icon: const Icon(Icons.event_available_rounded, size: 19, color: Colors.white),
                              label: Text(
                                _isFrequentClient
                                    ? 'Confirmar Cita y Agendar en Inicio (Cada $_recurrenceDays días)'
                                    : 'Confirmar Cita y Agendar en Inicio',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.leafGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Step 02: Servicios requeridos (Todo por metros cuadrados m²)
                    _buildStepSection(
                      stepNumber: '02',
                      title: 'Servicios por metro cuadrado (m²)',
                      subtitle: 'Todo presupuestado por m² con cálculo automático',
                      content: Column(
                        children: [
                          // Badge informativo de metros cuadrados
                          Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.mint.withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.square_foot_rounded,
                                  color: AppColors.mint,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Servicios por m² o de precio fijo (poda, árboles, perfilado). Puedes añadir tus propios servicios al catálogo.',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          ..._services.asMap().entries.map((entry) {
                            final index = entry.key;
                            final service = entry.value;
                            return _buildServiceCard(service, index);
                          }),

                          const SizedBox(height: 8),

                          // Botón para que el usuario añada servicios personalizados
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _showAddCustomServiceDialog,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppColors.leafGreen.withValues(alpha: 0.6), width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                backgroundColor: AppColors.leafBadgeBg.withValues(alpha: 0.3),
                              ),
                              child: const Text(
                                '+ Añadir servicio personalizado (m² o precio fijo)',
                                style: TextStyle(
                                  color: AppColors.leafGreenAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Step 03: Diagnóstico de plantas con IA
                    _buildStepSection(
                      stepNumber: '03',
                      title: 'Diagnóstico de plantas con IA',
                      subtitle: 'Escanea plantas para evaluar su salud mediante IA',
                      content: _buildDiagnosisSection(),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Bottom Sticky Total Bar
            _buildBottomTotalBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: const Center(
                child: Icon(
                  Icons.receipt_long,
                  color: AppColors.mint,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JARDINEROS AL RESCATE',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9.5,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cotizador por m²',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Presupuesto oficial y confirmación de cita',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        InkWell(
          onTap: widget.onOpenNotifications,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
                Positioned(
                  top: 10,
                  right: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF7A00),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showScanSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(22),
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
                'Diagnóstico Botánico con IA',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Elige el método para capturar la evidencia de las plantas o el jardín:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.leafBadgeBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.leafGreenAccent),
                ),
                title: Text(
                  'Tomar foto con la cámara',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Enfoca hojas, tallo o césped directamente con tu teléfono',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  diagnosticoCtrl.escanearConCamara(usarGaleria: false);
                },
              ),
              const SizedBox(height: 6),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.leafBadgeBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: AppColors.cyan),
                ),
                title: Text(
                  'Seleccionar de la galería',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Elige una foto existente de tu dispositivo',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  diagnosticoCtrl.escanearConCamara(usarGaleria: true);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDiagnosisSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: diagnosticoCtrl.analizando
                ? null
                : _showScanSourceOptions,
            icon: diagnosticoCtrl.analizando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.camera_alt),
            label: Text(
              diagnosticoCtrl.analizando
                  ? 'Analizando planta con IA...'
                  : 'Escanear planta con IA',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.leafGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Contador de diagnósticos registrados
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_capturedPhotos.length} análisis de plantas registrados',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_capturedPhotos.isNotEmpty)
              InkWell(
                onTap: () {
                  setState(() {
                    _capturedPhotos.clear();
                  });
                },
                child: const Text(
                  'Borrar todas',
                  style: TextStyle(
                    color: AppColors.coral,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 10),

        if (_capturedPhotos.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              children: [
                Icon(Icons.psychology_outlined, size: 40, color: AppColors.leafGreen.withValues(alpha: 0.6)),
                const SizedBox(height: 10),
                Text(
                  'Sin diagnósticos de plantas',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Toca "Escanear planta" para obtener un diagnóstico con IA sobre si las plantas están sanas o enfermas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _capturedPhotos.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final photo = _capturedPhotos[index];
              return _buildPhotoCard(photo, index);
            },
          ),
      ],
    );
  }

  Widget _buildPhotoCard(GardenPhoto photo, int index) {
    final bool isHealthy = photo.isHealthy ?? true;
    final Color badgeColor = isHealthy ? AppColors.leafGreen : AppColors.amber;
    final Color badgeBg = isHealthy ? AppColors.leafBadgeBg : AppColors.amberBg;
    final String? assetPath = photo.assetPath;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Visual de la foto o escaneo IA
          GestureDetector(
            onTap: () => _previewPhotoFullscreen(photo),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 72,
                height: 72,
                color: const Color(0xFF16241D),
                child: photo.imageBytes != null
                    ? Image.memory(photo.imageBytes!, fit: BoxFit.cover)
                    : (assetPath != null
                        ? Image.asset(
                            assetPath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          )
                        : Center(
                            child: Icon(
                              isHealthy
                                  ? Icons.energy_savings_leaf_rounded
                                  : Icons.warning_amber_rounded,
                              color: badgeColor,
                              size: 34,
                            ),
                          )),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Detalles de diagnóstico
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        isHealthy ? 'PLANTA SANA' : 'ENFERMA / ATENCIÓN',
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      photo.timestamp,
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  photo.aiDiagnosisStatus ?? photo.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (photo.aiTreatment != null || photo.notes != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    photo.aiTreatment ?? photo.notes!,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Botón borrar
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coral, size: 20),
            onPressed: () {
              setState(() {
                _capturedPhotos.removeAt(index);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Diagnóstico eliminado de la cotización.'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _previewPhotoFullscreen(GardenPhoto photo) {
    final bool isHealthy = photo.isHealthy ?? true;
    final Color badgeColor = isHealthy ? AppColors.leafGreen : AppColors.amber;
    final Color badgeBg = isHealthy ? AppColors.leafBadgeBg : AppColors.amberBg;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Diagnóstico Fitosanitario IA',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: badgeColor),
                      ),
                      child: Text(
                        isHealthy ? 'SANA' : 'ENFERMA',
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (photo.imageBytes != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      photo.imageBytes!,
                      width: double.infinity,
                      height: 190,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 14),
                ] else if (photo.assetPath != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      photo.assetPath!,
                      width: double.infinity,
                      height: 190,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox(
                        height: 190,
                        child: Center(
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        photo.aiDiagnosisStatus ?? photo.title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (photo.aiConfidence != null)
                        Text(
                          'Precisión IA: ${(photo.aiConfidence! * 100).toStringAsFixed(1)}%',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      const SizedBox(height: 10),
                      Text(
                        'Recomendación del Jardinero:',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        photo.aiTreatment ?? photo.notes ?? 'Sin observaciones.',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.leafGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cerrar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepSection({
    required String stepNumber,
    required String title,
    required String subtitle,
    required Widget content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.leafBadgeBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.leafGreen.withValues(alpha: 0.5), width: 1),
              ),
              child: Center(
                child: Text(
                  stepNumber,
                  style: const TextStyle(
                    color: AppColors.leafGreenAccent,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        content,
      ],
    );
  }

  void _showEditUnitPriceDialog(QuoteServiceItem service) {
    final priceCtrl = TextEditingController(
        text: service.unitPrice.toStringAsFixed(service.unitPrice % 1 == 0 ? 0 : 2));
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.edit_note_rounded, color: AppColors.mint, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Editar Precio Unitario',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: service.isFixedPrice
                          ? 'Precio Fijo del Servicio (MXN)'
                          : 'Precio por m² (MXN)',
                      prefixText: '\$ ',
                      errorText: errorText,
                    ),
                    onChanged: (_) {
                      if (errorText != null) setDlgState(() => errorText = null);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final val = double.tryParse(priceCtrl.text.trim());
                    if (val == null || val <= 0) {
                      setDlgState(() => errorText = 'Ingresa un precio mayor a 0');
                      return;
                    }
                    setState(() {
                      service.unitPrice = val;
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.leafGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Actualizar Precio', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddCustomServiceDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    bool isFixed = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: BorderSide(color: AppColors.border),
              ),
              title: const Text(
                'Añadir Servicio Personalizado',
                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nombre del servicio',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Ej. Retiro de árbol o tocón, Deshierbe...',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Tipo de cobro del servicio',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(() => isFixed = false),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              decoration: BoxDecoration(
                                color: !isFixed ? AppColors.leafBadgeBg : AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: !isFixed ? AppColors.leafGreen : AppColors.border,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Por m² (\$/m²)',
                                  style: TextStyle(
                                    color: !isFixed ? AppColors.leafGreenAccent : AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(() => isFixed = true),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              decoration: BoxDecoration(
                                color: isFixed ? AppColors.leafBadgeBg : AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isFixed ? AppColors.leafGreen : AppColors.border,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Precio Fijo (Sin m²)',
                                  style: TextStyle(
                                    color: isFixed ? AppColors.leafGreenAccent : AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isFixed ? 'Precio fijo total (\$ MXN)' : 'Precio unitario por m² (\$ MXN)',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        prefixText: '\$ ',
                        hintText: isFixed ? '1200' : '95',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor ingresa el nombre del servicio.')),
                      );
                      return;
                    }
                    if (price <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor ingresa un precio válido mayor a 0.')),
                      );
                      return;
                    }

                    setState(() {
                      _services.add(
                        QuoteServiceItem(
                          id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          unitPrice: price,
                          unitLabel: isFixed ? 'Precio fijo' : '/ m²',
                          icon: Icons.design_services_outlined,
                          isSelected: true,
                          quantity: isFixed ? 1.0 : 25.0,
                          isFixedPrice: isFixed,
                        ),
                      );
                    });

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.leafGreen,
                        content: Text('Servicio "$name" añadido exitosamente.'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.leafGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Añadir Servicio', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditM2Dialog(QuoteServiceItem service) {
    final m2Ctrl = TextEditingController(
        text: service.quantity.toStringAsFixed(service.quantity % 1 == 0 ? 0 : 2));
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.square_foot_rounded, color: AppColors.mint, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Editar Superficie en m²',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${service.name} (admite decimales ej. 5.5 m²)',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: m2Ctrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Metros cuadrados (m²)',
                      suffixText: 'm²',
                      errorText: errorText,
                    ),
                    onChanged: (_) {
                      if (errorText != null) setDlgState(() => errorText = null);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final val = double.tryParse(m2Ctrl.text.trim());
                    if (val == null || val <= 0) {
                      setDlgState(() => errorText = 'Ingresa un valor mayor a 0 m²');
                      return;
                    }
                    setState(() {
                      service.quantity = val;
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.leafGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Guardar m²', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildServiceCard(QuoteServiceItem service, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: service.isSelected
              ? AppColors.mint.withValues(alpha: 0.6)
              : AppColors.border,
          width: service.isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header row with Icon, Title, Price per m², Checkbox
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle, width: 1),
                  ),
                  child: Icon(
                    service.icon,
                    color: AppColors.mint,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          InkWell(
                            onTap: () => _showEditUnitPriceDialog(service),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.leafBadgeBg.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.mint.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                service.isFixedPrice
                                    ? '${_currencyFormat.format(service.unitPrice)} (fijo)'
                                    : '${_currencyFormat.format(service.unitPrice)} / m²',
                                style: const TextStyle(
                                  color: AppColors.mint,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          if (service.isSelected) ...[
                            const SizedBox(width: 8),
                            Text(
                              '• Subtotal: ${_currencyFormat.format(service.subtotal)}',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Checkbox(
                  value: service.isSelected,
                  activeColor: AppColors.mint,
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  side: BorderSide(color: AppColors.border, width: 1.5),
                  onChanged: (val) {
                    setState(() {
                      service.isSelected = val ?? false;
                    });
                  },
                ),
              ],
            ),
          ),

          // Si está seleccionado, mostrar controles correspondientes al tipo de servicio
          if (service.isSelected) ...[
            Container(
              height: 1,
              color: AppColors.borderSubtle,
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: service.isFixedPrice
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Precio del servicio fijo
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Precio del servicio (Precio fijo)',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () => _showEditUnitPriceDialog(service),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceElevated,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.mint.withValues(alpha: 0.5), width: 1.2),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _currencyFormat.format(service.unitPrice),
                                          style: const TextStyle(
                                            color: AppColors.mint,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Cantidad de servicios/piezas
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cantidad / Pz',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceElevated,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.border, width: 1),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove, size: 16, color: AppColors.mint),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            if (service.quantity > 1) {
                                              setState(() {
                                                service.quantity -= 1;
                                              });
                                            }
                                          },
                                        ),
                                        Text(
                                          '${service.quantity.toInt()}',
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add, size: 16, color: AppColors.mint),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            setState(() {
                                              service.quantity += 1;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 14, color: AppColors.cyan),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Servicio cotizado por precio directo fijo (no requiere medición de m²).',
                                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Row(
                          children: [
                            // Precio Unitario editable por m²
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Precio por m² (editable)',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () => _showEditUnitPriceDialog(service),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceElevated,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.mint.withValues(alpha: 0.5), width: 1.2),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${_currencyFormat.format(service.unitPrice)} / m²',
                                          style: const TextStyle(
                                            color: AppColors.mint,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Stepper y entrada decimal de Metros Cuadrados (m²)
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Superficie (editable)',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceElevated,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.border, width: 1),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove, size: 16, color: AppColors.mint),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            if (service.quantity > 0.5) {
                                              setState(() {
                                                service.quantity = (service.quantity - 0.5).clamp(0.5, 99999.0);
                                              });
                                            }
                                          },
                                        ),
                                        InkWell(
                                          onTap: () => _showEditM2Dialog(service),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.leafBadgeBg.withValues(alpha: 0.4),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _formatM2(service.quantity),
                                              style: TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add, size: 16, color: AppColors.mint),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            setState(() {
                                              service.quantity = (service.quantity + 0.5);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Chips rápidos para sumar / ajustar m² decimales
                        Row(
                          children: [
                            Text(
                              'Ajuste:',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 10.5),
                            ),
                            const SizedBox(width: 6),
                            _buildQuickM2Chip(service, 5.5),
                            const SizedBox(width: 5),
                            _buildQuickM2Chip(service, 10.0),
                            const SizedBox(width: 5),
                            _buildQuickM2Chip(service, 25.0),
                            const SizedBox(width: 5),
                            _buildQuickM2Chip(service, 50.0),
                            const SizedBox(width: 5),
                            _buildQuickM2Chip(service, 100.0),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickM2Chip(QuoteServiceItem service, double m2Value) {
    final isCurrent = service.quantity == m2Value;
    final label = m2Value % 1 == 0 ? '${m2Value.toInt()} m²' : '$m2Value m²';
    return InkWell(
      onTap: () {
        setState(() {
          service.quantity = m2Value;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppColors.mint.withValues(alpha: 0.2)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCurrent ? AppColors.mint : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isCurrent ? AppColors.mint : AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomTotalBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_formatM2(_totalSquareMeters)} • ${_capturedPhotos.length} fotos adjuntas',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _currencyFormat.format(_totalPrice),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _isGeneratingPdf ? null : () => _showShareAndConfirmModal(context),
            icon: const Icon(Icons.share_rounded, size: 18, color: Colors.white),
            label: const Text(
              'Compartir PDF',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mint,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  void _showShareAndConfirmModal(BuildContext context) {
    final rawName = _clientNameController.text.trim();
    final nameRegex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]{2,60}$');

    // CONDICIÓN IF / ELSE: Nombre del cliente (solo letras)
    if (rawName.isEmpty) {
      setState(() => _clientNameError = 'Ingresa el nombre del cliente');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa el nombre del cliente (solo letras).'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    } else if (!nameRegex.hasMatch(rawName)) {
      setState(() => _clientNameError = 'El nombre solo permite letras (sin números ni símbolos)');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error en nombre: Solo se permiten letras (nada de números ni símbolos).'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    } else {
      setState(() => _clientNameError = null);
    }

    final rawPhone = _clientPhoneController.text.trim();
    final phoneRegex = RegExp(r'^[0-9]{10}$');

    // CONDICIÓN IF / ELSE: Teléfono celular (solo números de 10 dígitos)
    if (rawPhone.isEmpty) {
      setState(() => _clientPhoneError = 'Ingresa el número celular');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa el número celular del cliente.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    } else if (!phoneRegex.hasMatch(rawPhone)) {
      setState(() => _clientPhoneError = 'El número celular debe tener 10 dígitos (sin letras)');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error en teléfono: Solo se permiten 10 números celular (sin letras).'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    } else {
      setState(() => _clientPhoneError = null);
    }

    final clientName = rawName;
    final clientPhone = '+52 $rawPhone';
    final address = _addressController.text.trim().isEmpty
        ? 'Calle 19 #204 x 24 y 26, Col. Altabrisa, Mérida, Yucatán'
        : _addressController.text.trim();
    final appointmentDay = _appointmentDateController.text;
    final quoteDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
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

              // Título del Modal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cotización Lista',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.mint.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_formatM2(_totalSquareMeters)} totales',
                      style: const TextStyle(
                        color: AppColors.mint,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Resumen de datos que irán en el PDF
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildModalSummaryRow(
                      icon: Icons.person_outline,
                      label: 'Cliente:',
                      value: clientName,
                    ),
                    const SizedBox(height: 6),
                    _buildModalSummaryRow(
                      icon: Icons.phone_android_rounded,
                      label: 'Número de cliente:',
                      value: clientPhone,
                    ),
                    const SizedBox(height: 6),
                    _buildModalSummaryRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Día de confirmación:',
                      value: appointmentDay,
                      valueColor: AppColors.mint,
                    ),
                    const SizedBox(height: 6),
                    _buildModalSummaryRow(
                      icon: Icons.location_on_outlined,
                      label: 'Dirección:',
                      value: address,
                    ),
                    const SizedBox(height: 6),
                    _buildModalSummaryRow(
                      icon: Icons.psychology_outlined,
                      label: 'Diagnósticos IA:',
                      value: '${_capturedPhotos.length} análisis adjuntos',
                      valueColor: AppColors.leafGreen,
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Presupuesto (m²):',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _currencyFormat.format(_totalPrice),
                          style: const TextStyle(
                            color: AppColors.mint,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              Text(
                'Nota: El documento PDF se generará con el logotipo oficial de Jardineros Al Rescate, desglose por m² y datos de confirmación.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),

              const SizedBox(height: 18),

              // Botón 0: CONFIRMAR Y AGENDAR CITA EN INICIO
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmAppointmentAndSendToHome();
                  },
                  icon: const Icon(Icons.event_available_rounded, color: Colors.white, size: 21),
                  label: Text(
                    _isFrequentClient
                        ? 'Confirmar Cita y Guardar en Inicio (Recurrente)'
                        : 'Confirmar Cita y Guardar en Inicio',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Botón 1: COMPARTIR PDF POR WHATSAPP (share_plus con archivo PDF adjunto + texto)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    _syncQuoteToPostgreSQL(
                      clientName: clientName,
                      clientPhone: clientPhone,
                      address: address,
                    );
                    setState(() => _isGeneratingPdf = true);
                    try {
                      await PdfQuoteService.sharePdfViaWhatsApp(
                        clientName: clientName,
                        clientPhone: clientPhone,
                        address: address,
                        appointmentConfirmationDate: appointmentDay,
                        quoteDate: quoteDate,
                        services: _services,
                        totalPrice: _totalPrice,
                        photosCount: _capturedPhotos.length,
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al compartir PDF: $e')),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isGeneratingPdf = false);
                    }
                  },
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  label: const Text(
                    'Compartir PDF por WhatsApp',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.leafGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Botón 2: ABRIR CHAT DIRECTO WHATSAPP API (wa.me)
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    final message = PdfQuoteService.buildWhatsAppMessage(
                      clientName: clientName,
                      clientPhone: clientPhone,
                      address: address,
                      appointmentConfirmationDate: appointmentDay,
                      quoteDate: quoteDate,
                      services: _services,
                      totalPrice: _totalPrice,
                      photosCount: _capturedPhotos.length,
                    );
                    final launched = await PdfQuoteService.openWhatsAppDirectMessage(
                      clientPhone: clientPhone,
                      message: message,
                    );
                    if (!launched && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No se pudo abrir WhatsApp automáticamente.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.chat_outlined, color: AppColors.mint, size: 18),
                  label: const Text(
                    'Abrir chat en WhatsApp API',
                    style: TextStyle(
                      color: AppColors.mint,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.mint, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Botón 3: PREVISUALIZAR / IMPRIMIR PDF
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    _syncQuoteToPostgreSQL(
                      clientName: clientName,
                      clientPhone: clientPhone,
                      address: address,
                    );
                    await PdfQuoteService.previewPdf(
                      clientName: clientName,
                      clientPhone: clientPhone,
                      address: address,
                      appointmentConfirmationDate: appointmentDay,
                      quoteDate: quoteDate,
                      services: _services,
                      totalPrice: _totalPrice,
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.cyan, size: 18),
                  label: const Text(
                    'Ver / Imprimir PDF con Logo',
                    style: TextStyle(
                      color: AppColors.cyan,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Botón 4: GUARDAR DIRECTO EN BASE DE DATOS POSTGRESQL
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _syncQuoteToPostgreSQL(
                      clientName: clientName,
                      clientPhone: clientPhone,
                      address: address,
                    );
                  },
                  icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 19),
                  label: const Text(
                    'Guardar directo en PostgreSQL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _syncQuoteToPostgreSQL({
    required String clientName,
    required String clientPhone,
    required String address,
  }) async {
    try {
      final res = await DatabaseService.instance.guardarCotizacionCompleta(
        clientName: clientName,
        clientPhone: clientPhone,
        address: address,
        appointmentDate: _selectedDate,
        services: _services,
        totalPrice: _totalPrice,
        totalSquareMeters: _totalSquareMeters,
        photos: _capturedPhotos,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('✅ Guardado en PostgreSQL (Folio: ${res['folio']})'),
                ),
              ],
            ),
            backgroundColor: AppColors.leafGreen,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ No se pudo guardar en PostgreSQL: $e'),
            backgroundColor: const Color(0xFFDC2626),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Widget _buildModalSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
