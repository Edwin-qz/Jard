import 'package:flutter/material.dart';
import '../models/financial_data.dart';

/// Controlador Financiero (Control de Movimientos) en arquitectura MVC.
/// Administra el historial de facturación, filtros mensuales y estado de cobro.
class ControlController extends ChangeNotifier {
  List<FinancialMovement> _movements = [];
  String _selectedPeriod = 'Este mes';

  ControlController() {
    _loadMovements();
  }

  List<FinancialMovement> get movements => _movements;
  String get selectedPeriod => _selectedPeriod;

  void _loadMovements() {
    _movements = FinancialMovement.sampleMovements();
    notifyListeners();
  }

  void setPeriod(String period) {
    _selectedPeriod = period;
    notifyListeners();
  }

  double get totalCollected =>
      _movements.where((m) => m.isPaid).fold(0.0, (acc, item) => acc + item.amount);

  double get totalPending =>
      _movements.where((m) => !m.isPaid).fold(0.0, (acc, item) => acc + item.amount);

  double get totalRevenue => totalCollected + totalPending;

  int get pendingClientsCount =>
      _movements.where((m) => !m.isPaid).length;

  void updatePaymentStatus({
    required FinancialMovement movement,
    required String status,
    String? method,
    String? notes,
  }) {
    movement.paymentStatus = status;
    if (method != null) movement.paymentMethod = method;
    if (notes != null) movement.notes = notes;
    notifyListeners();
  }
}

