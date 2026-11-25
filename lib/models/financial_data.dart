class FinancialMovement {
  final String id;
  final String clientName;
  final String initials;
  final String serviceType;
  final String dateText;
  final double amount;
  String paymentStatus; // 'Pagado', 'Pendiente', 'Cancelado'
  String paymentMethod; // 'Efectivo', 'Transferencia SPEI', 'Tarjeta'
  String notes;

  FinancialMovement({
    required this.id,
    required this.clientName,
    required this.initials,
    required this.serviceType,
    required this.dateText,
    required this.amount,
    this.paymentStatus = 'Pendiente',
    this.paymentMethod = 'Transferencia SPEI',
    this.notes = '',
    bool? isPaid,
  }) {
    if (isPaid != null) {
      paymentStatus = isPaid ? 'Pagado' : 'Pendiente';
    }
  }

  bool get isPaid => paymentStatus == 'Pagado';
  set isPaid(bool val) {
    paymentStatus = val ? 'Pagado' : 'Pendiente';
  }

  /// Movimientos del mes actual (los 4 que se muestran en el dashboard principal)
  static List<FinancialMovement> sampleMovements() {
    return [
      FinancialMovement(
        id: 'm1',
        clientName: 'Mariana Ortega',
        initials: 'MO',
        serviceType: 'Poda y mantenimiento',
        dateText: '17 Jun',
        amount: 1850.0,
        paymentStatus: 'Pendiente',
        paymentMethod: 'Transferencia SPEI',
        notes: 'Residencial Montebello, Mérida • En proceso de atención',
      ),
      FinancialMovement(
        id: 'm2',
        clientName: 'Casa Rivera',
        initials: 'CR',
        serviceType: 'Instalación de pasto',
        dateText: '15 Jun',
        amount: 4320.0,
        paymentStatus: 'Pagado',
        paymentMethod: 'Efectivo',
        notes: 'Fracc. Altabrisa, Mérida • Servicio realizado con éxito',
      ),
      FinancialMovement(
        id: 'm3',
        clientName: 'Roberto Salas',
        initials: 'RS',
        serviceType: 'Fumigación',
        dateText: '12 Jun',
        amount: 950.0,
        paymentStatus: 'Pendiente',
        paymentMethod: 'Transferencia SPEI',
        notes: 'Cholul, Yucatán • En proceso de valoración',
      ),
      FinancialMovement(
        id: 'm4',
        clientName: 'Hotel Casa Verde',
        initials: 'HC',
        serviceType: 'Diseño paisajístico',
        dateText: '08 Jun',
        amount: 3500.0,
        paymentStatus: 'Pendiente',
        paymentMethod: 'Tarjeta',
        notes: 'Paseo de Montejo, Mérida • En proceso de ejecución',
      ),
    ];
  }

  /// Historial completo de movimientos (servicios en proceso, realizados y anteriores)
  static List<FinancialMovement> sampleFullHistory() {
    return [
      ...sampleMovements(),
      FinancialMovement(
        id: 'm5',
        clientName: 'Residencia Montejo',
        initials: 'RM',
        serviceType: 'Poda de formación y retiro de ramas',
        dateText: '28 May',
        amount: 2800.0,
        paymentStatus: 'Pagado',
        paymentMethod: 'Transferencia SPEI',
        notes: 'Zona Norte, Mérida • Servicio realizado y liquidado',
      ),
      FinancialMovement(
        id: 'm6',
        clientName: 'Plaza Altabrisa',
        initials: 'PA',
        serviceType: 'Mantenimiento de áreas verdes',
        dateText: '20 May',
        amount: 6200.0,
        paymentStatus: 'Pagado',
        paymentMethod: 'Transferencia SPEI',
        notes: 'Altabrisa, Mérida • Realizado corporativo',
      ),
      FinancialMovement(
        id: 'm7',
        clientName: 'Jardines del Norte',
        initials: 'JN',
        serviceType: 'Nivelación de tierra y fertilización',
        dateText: '14 May',
        amount: 1400.0,
        paymentStatus: 'Pagado',
        paymentMethod: 'Efectivo',
        notes: 'Temozón Norte • Servicio realizado',
      ),
      FinancialMovement(
        id: 'm8',
        clientName: 'Carlos Pech',
        initials: 'CP',
        serviceType: 'Deshierbe y perfilado estético',
        dateText: '05 May',
        amount: 1150.0,
        paymentStatus: 'Pagado',
        paymentMethod: 'Efectivo',
        notes: 'Francisco de Montejo • Servicio realizado',
      ),
      FinancialMovement(
        id: 'm9',
        clientName: 'Quinta San José',
        initials: 'QS',
        serviceType: 'Instalación de pasto en rollo y riego',
        dateText: '28 Abr',
        amount: 4900.0,
        paymentStatus: 'Pagado',
        paymentMethod: 'Transferencia SPEI',
        notes: 'Conkal, Yucatán • Servicio realizado',
      ),
      FinancialMovement(
        id: 'm10',
        clientName: 'Laura Méndez',
        initials: 'LM',
        serviceType: 'Corte de pasto y perfilado',
        dateText: '15 Abr',
        amount: 850.0,
        paymentStatus: 'Cancelado',
        paymentMethod: 'Efectivo',
        notes: 'Cancelado por condiciones climáticas',
      ),
    ];
  }
}
