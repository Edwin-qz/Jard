import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/financial_data.dart';
import '../../theme/app_theme.dart';
import 'movimientos_historial_screen.dart';

class ControlScreen extends StatefulWidget {
  final VoidCallback onOpenNotifications;

  const ControlScreen({
    super.key,
    required this.onOpenNotifications,
  });

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  late List<FinancialMovement> _movements;
  String _selectedPeriod = 'Este mes';
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _movements = FinancialMovement.sampleMovements();
  }

  double get _totalCollected =>
      _movements.where((m) => m.isPaid).fold(0.0, (acc, item) => acc + item.amount);

  double get _totalPending =>
      _movements.where((m) => !m.isPaid).fold(0.0, (acc, item) => acc + item.amount);

  double get _totalRevenue => _totalCollected + _totalPending;

  int get _pendingClientsCount =>
      _movements.where((m) => !m.isPaid).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),

              const SizedBox(height: 22),

              // Main Revenue Card
              _buildMainRevenueCard(),

              const SizedBox(height: 16),

              // Two Metric Cards Side-by-Side
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.account_balance_wallet_outlined,
                      iconBg: AppColors.leafBadgeBg,
                      iconColor: AppColors.mint,
                      label: 'Servicios',
                      value: '18',
                      sublabel: 'Completados',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.monetization_on_outlined,
                      iconBg: const Color(0xFF35250E),
                      iconColor: AppColors.amber,
                      label: 'Por cobrar',
                      value: _currencyFormat.format(_totalPending),
                      sublabel: '$_pendingClientsCount clientes',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              // Section MOVIMIENTOS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MOVIMIENTOS',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Historial de servicios',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // Period dropdown pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPeriod,
                        dropdownColor: AppColors.surfaceCard,
                        icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 18),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        items: ['Este mes', 'Mayo', 'Abril'].map((String val) {
                          return DropdownMenuItem<String>(
                            value: val,
                            child: Text(val),
                          );
                        }).toList(),
                        onChanged: (newVal) {
                          if (newVal != null) {
                            setState(() {
                              _selectedPeriod = newVal;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Movements List
              ListView.separated(
                itemCount: _movements.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _buildMovementTile(_movements[index]);
                },
              ),

              const SizedBox(height: 18),

              // Link: Ver todos los movimientos
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MovimientosHistorialScreen(),
                      ),
                    );
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  icon: const Icon(Icons.receipt_outlined, color: AppColors.mint, size: 16),
                  label: const Text(
                    'Ver todos los movimientos →',
                    style: TextStyle(
                      color: AppColors.mint,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
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
                color: AppColors.leafBadgeBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: const Center(
                child: Icon(
                  Icons.trending_up,
                  color: AppColors.mint,
                  size: 24,
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
                SizedBox(height: 2),
                Text(
                  'Control del mes',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Junio 2025',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
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

  Widget _buildMainRevenueCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B4D2E),
            Color(0xFF143822),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Big Total
          Text(
            _currencyFormat.format(_totalRevenue > 0 ? _totalRevenue : 28450),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),

          // Growth Pill
          Row(
            children: [
              Icon(Icons.arrow_upward_rounded, color: AppColors.mint, size: 15),
              SizedBox(width: 4),
              Text(
                '12%',
                style: TextStyle(
                  color: AppColors.mint,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 6),
              Text(
                'respecto a mayo',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),
          Container(
            height: 1,
            color: AppColors.borderSubtle,
          ),
          const SizedBox(height: 16),

          // Rows: Cobrado & Pendiente
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cobrado',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _currencyFormat.format(_totalCollected > 0 ? _totalCollected : 24000),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pendiente',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _currencyFormat.format(_totalPending > 0 ? _totalPending : 4450),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    required String sublabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementTile(FinancialMovement movement) {
    Color statusBg;
    Color statusTextColor;
    if (movement.paymentStatus == 'Pagado') {
      statusBg = const Color(0xFFD4F9EC);
      statusTextColor = const Color(0xFF047857);
    } else if (movement.paymentStatus == 'Cancelado') {
      statusBg = const Color(0xFFFEE2E2);
      statusTextColor = const Color(0xFFB91C1C);
    } else {
      statusBg = const Color(0xFFFEF3C7);
      statusTextColor = const Color(0xFFB45309);
    }

    return InkWell(
      onTap: () => _showPaymentStatusPicker(context, movement),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            // Initials Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF0F2C24),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle, width: 1),
              ),
              child: Center(
                child: Text(
                  movement.initials,
                  style: const TextStyle(
                    color: AppColors.mint,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Client and Service
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movement.clientName,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${movement.serviceType} • ${movement.dateText}',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),

            // Price & Status Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _currencyFormat.format(movement.amount),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => _showPaymentStatusPicker(context, movement),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          movement.paymentStatus,
                          style: TextStyle(
                            color: statusTextColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(Icons.arrow_drop_down, size: 13, color: statusTextColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentStatusPicker(BuildContext context, FinancialMovement movement) {
    String selectedStatus = movement.paymentStatus;
    String selectedMethod = movement.paymentMethod;
    final notesCtrl = TextEditingController(text: movement.notes);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gestión de Cobro',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${movement.clientName} • ${movement.serviceType}',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _currencyFormat.format(movement.amount),
                        style: const TextStyle(
                          color: AppColors.leafGreen,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  Text(
                    'Selecciona el estado del pago:',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Opciones de Estado: Pagado, Pendiente, Cancelado
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusOption(
                          label: 'Pagado',
                          icon: Icons.check_circle_outline,
                          color: AppColors.leafGreen,
                          isSelected: selectedStatus == 'Pagado',
                          onTap: () => setSheetState(() => selectedStatus = 'Pagado'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatusOption(
                          label: 'Pendiente',
                          icon: Icons.schedule,
                          color: AppColors.amber,
                          isSelected: selectedStatus == 'Pendiente',
                          onTap: () => setSheetState(() => selectedStatus = 'Pendiente'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatusOption(
                          label: 'Cancelado',
                          icon: Icons.cancel_outlined,
                          color: AppColors.coral,
                          isSelected: selectedStatus == 'Cancelado',
                          onTap: () => setSheetState(() => selectedStatus = 'Cancelado'),
                        ),
                      ),
                    ],
                  ),

                  if (selectedStatus == 'Pagado') ...[
                    const SizedBox(height: 16),
                    Text(
                      'Método de cobro recibido:',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['Efectivo', 'Transferencia SPEI', 'Tarjeta'].map((method) {
                        final isSel = selectedMethod == method;
                        return ChoiceChip(
                          label: Text(method),
                          selected: isSel,
                          selectedColor: AppColors.leafGreen.withValues(alpha: 0.25),
                          labelStyle: TextStyle(
                            color: isSel ? AppColors.leafGreen : AppColors.textSecondary,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          onSelected: (_) => setSheetState(() => selectedMethod = method),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 14),
                  TextField(
                    controller: notesCtrl,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Notas / Referencia de cobro (opcional)',
                      hintText: 'Ej. Folio SPEI #92834 o Efectivo recibido en Mérida',
                      prefixIcon: const Icon(Icons.receipt_long_outlined, color: AppColors.leafGreen),
                    ),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          movement.paymentStatus = selectedStatus;
                          movement.paymentMethod = selectedMethod;
                          movement.notes = notesCtrl.text.trim();
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: selectedStatus == 'Pagado'
                                ? AppColors.leafGreen
                                : (selectedStatus == 'Cancelado' ? AppColors.coral : AppColors.amber),
                            content: Text(
                              'Estado guardado: $selectedStatus${selectedStatus == 'Pagado' ? ' ($selectedMethod)' : ''}',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.leafGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Guardar Estado de Cobro', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusOption({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : AppColors.textMuted, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppColors.textSecondary,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
