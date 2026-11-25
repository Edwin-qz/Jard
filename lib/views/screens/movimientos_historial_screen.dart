import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/financial_data.dart';
import '../../theme/app_theme.dart';

/// Pantalla de Historial Completo de Servicios (En proceso y Realizados)
class MovimientosHistorialScreen extends StatefulWidget {
  const MovimientosHistorialScreen({super.key});

  @override
  State<MovimientosHistorialScreen> createState() => _MovimientosHistorialScreenState();
}

class _MovimientosHistorialScreenState extends State<MovimientosHistorialScreen> {
  late List<FinancialMovement> _allMovements;
  String _selectedFilter = 'Todos'; // 'Todos', 'En proceso', 'Realizados', 'Cancelados'
  String _selectedPeriod = 'Todos'; // 'Todos', 'Junio', 'Mayo', 'Abril'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _allMovements = FinancialMovement.sampleFullHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FinancialMovement> get _filteredMovements {
    return _allMovements.where((item) {
      // 1. Filtro por estado
      if (_selectedFilter == 'En proceso' && item.paymentStatus != 'Pendiente') {
        return false;
      }
      if (_selectedFilter == 'Realizados' && item.paymentStatus != 'Pagado') {
        return false;
      }
      if (_selectedFilter == 'Cancelados' && item.paymentStatus != 'Cancelado') {
        return false;
      }

      // 2. Filtro por periodo
      if (_selectedPeriod != 'Todos') {
        if (!item.dateText.toLowerCase().contains(_selectedPeriod.toLowerCase())) {
          return false;
        }
      }

      // 3. Filtro por búsqueda
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchClient = item.clientName.toLowerCase().contains(query);
        final matchService = item.serviceType.toLowerCase().contains(query);
        final matchNotes = item.notes.toLowerCase().contains(query);
        if (!matchClient && !matchService && !matchNotes) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  double get _totalCollected => _allMovements
      .where((m) => m.paymentStatus == 'Pagado')
      .fold(0.0, (acc, item) => acc + item.amount);

  double get _totalPending => _allMovements
      .where((m) => m.paymentStatus == 'Pendiente')
      .fold(0.0, (acc, item) => acc + item.amount);

  int get _pendingCount =>
      _allMovements.where((m) => m.paymentStatus == 'Pendiente').length;

  int get _paidCount =>
      _allMovements.where((m) => m.paymentStatus == 'Pagado').length;

  @override
  Widget build(BuildContext context) {
    final list = _filteredMovements;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Historial de Servicios',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
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
                items: ['Todos', 'Junio', 'Mayo', 'Abril'].map((val) {
                  return DropdownMenuItem<String>(
                    value: val,
                    child: Text(val == 'Todos' ? 'Todos los meses' : val),
                  );
                }).toList(),
                onChanged: (newVal) {
                  if (newVal != null) {
                    setState(() => _selectedPeriod = newVal);
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // KPI Metric Bar
          _buildSummaryCards(),

          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Buscar por cliente, servicio o ubicación...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.leafGreen, size: 22),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Chips de filtro: Todos, En proceso, Realizados, Cancelados
          _buildFilterTabs(),

          const SizedBox(height: 8),

          // Lista de movimientos
          Expanded(
            child: list.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: list.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _buildMovementCard(list[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Total Realizados (Pagados)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.leafBadgeBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.check_circle_outline, color: AppColors.mint, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Realizados',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currencyFormat.format(_totalCollected),
                    style: const TextStyle(
                      color: AppColors.mint,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '$_paidCount servicios completados',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Total En Proceso (Por cobrar / Pendientes)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF35250E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.hourglass_top_rounded, color: AppColors.amber, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'En Proceso',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currencyFormat.format(_totalPending),
                    style: const TextStyle(
                      color: AppColors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '$_pendingCount por cobrar',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      {'label': 'Todos', 'count': _allMovements.length},
      {'label': 'En proceso', 'count': _pendingCount},
      {'label': 'Realizados', 'count': _paidCount},
      {'label': 'Cancelados', 'count': _allMovements.where((m) => m.paymentStatus == 'Cancelado').length},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((tab) {
          final isSelected = _selectedFilter == tab['label'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: false,
              label: Text(
                '${tab['label']} (${tab['count']})',
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              backgroundColor: AppColors.surfaceElevated,
              selectedColor: AppColors.leafGreen,
              side: BorderSide(
                color: isSelected ? AppColors.leafGreen : AppColors.border,
                width: 1,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (_) {
                setState(() => _selectedFilter = tab['label'] as String);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMovementCard(FinancialMovement item) {
    Color statusBg;
    Color statusTextColor;
    String statusLabel = item.paymentStatus;

    if (item.paymentStatus == 'Pagado') {
      statusBg = const Color(0xFF132F21);
      statusTextColor = AppColors.mint;
    } else if (item.paymentStatus == 'Cancelado') {
      statusBg = const Color(0xFF381A1A);
      statusTextColor = AppColors.coral;
    } else {
      statusBg = const Color(0xFF35250E);
      statusTextColor = AppColors.amber;
      statusLabel = 'Pendiente';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: InkWell(
        onTap: () => _showPaymentDetailModal(item),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Initials Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.leafBadgeBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.mint.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    item.initials,
                    style: const TextStyle(
                      color: AppColors.leafGreenAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.clientName,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.serviceType} • ${item.dateText}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (item.notes.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.notes,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 10.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Price & Status Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _currencyFormat.format(item.amount),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          statusLabel,
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, color: AppColors.textMuted, size: 54),
          const SizedBox(height: 12),
          Text(
            'No se encontraron movimientos',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Prueba cambiando el filtro de mes o la búsqueda.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showPaymentDetailModal(FinancialMovement item) {
    String selectedStatus = item.paymentStatus;
    String selectedMethod = item.paymentMethod;
    final notesCtrl = TextEditingController(text: item.notes);

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
                              'Detalle del Servicio',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${item.clientName} • ${item.serviceType}',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _currencyFormat.format(item.amount),
                        style: const TextStyle(
                          color: AppColors.leafGreen,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Estado del cobro / servicio:',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildModalStatusBtn(
                          label: 'Pagado',
                          icon: Icons.check_circle_outline,
                          color: AppColors.leafGreen,
                          isSelected: selectedStatus == 'Pagado',
                          onTap: () => setSheetState(() => selectedStatus = 'Pagado'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildModalStatusBtn(
                          label: 'Pendiente',
                          icon: Icons.schedule,
                          color: AppColors.amber,
                          isSelected: selectedStatus == 'Pendiente',
                          onTap: () => setSheetState(() => selectedStatus = 'Pendiente'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildModalStatusBtn(
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
                    const SizedBox(height: 14),
                    Text(
                      'Método de cobro recibido:',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: ['Efectivo', 'Transferencia SPEI', 'Tarjeta'].map((m) {
                        final isSel = selectedMethod == m;
                        return ChoiceChip(
                          label: Text(m),
                          selected: isSel,
                          selectedColor: AppColors.leafGreen.withValues(alpha: 0.25),
                          labelStyle: TextStyle(
                            color: isSel ? AppColors.leafGreen : AppColors.textSecondary,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          onSelected: (_) => setSheetState(() => selectedMethod = m),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextField(
                    controller: notesCtrl,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Notas y ubicación del trabajo',
                      prefixIcon: Icon(Icons.notes_rounded, color: AppColors.leafGreen),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          item.paymentStatus = selectedStatus;
                          item.paymentMethod = selectedMethod;
                          item.notes = notesCtrl.text.trim();
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: selectedStatus == 'Pagado'
                                ? AppColors.leafGreen
                                : (selectedStatus == 'Cancelado' ? AppColors.coral : AppColors.amber),
                            content: Text('Servicio actualizado: $selectedStatus'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.leafGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Guardar Cambios', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildModalStatusBtn({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : AppColors.border, width: isSelected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : AppColors.textMuted, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
