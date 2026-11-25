import 'package:flutter/material.dart';

class QuoteServiceItem {
  final String id;
  final String name;
  double unitPrice;
  String unitLabel;
  final IconData icon;
  bool isSelected;
  double quantity; // m² o cantidad de unidades/servicios
  final bool isFixedPrice; // True para servicios que no se cobran por m² (ej. perfilado, tala de árbol)

  QuoteServiceItem({
    required this.id,
    required this.name,
    required this.unitPrice,
    required this.unitLabel,
    required this.icon,
    this.isSelected = false,
    this.quantity = 1.0,
    this.isFixedPrice = false,
  });

  double get subtotal => isSelected ? (unitPrice * quantity) : 0.0;

  static List<QuoteServiceItem> defaultServices() {
    return [
      QuoteServiceItem(
        id: 's1',
        name: 'Nivelación y preparación de suelo',
        unitPrice: 85.0,
        unitLabel: '/ m²',
        icon: Icons.landscape_outlined,
        isSelected: false,
        quantity: 30.0,
        isFixedPrice: false,
      ),
      QuoteServiceItem(
        id: 's2',
        name: 'Suministro y extendido de tierra',
        unitPrice: 65.0,
        unitLabel: '/ m²',
        icon: Icons.layers_outlined,
        isSelected: false,
        quantity: 25.0,
        isFixedPrice: false,
      ),
      QuoteServiceItem(
        id: 's3',
        name: 'Instalación de pasto natural',
        unitPrice: 145.0,
        unitLabel: '/ m²',
        icon: Icons.grass_outlined,
        isSelected: true,
        quantity: 40.0,
        isFixedPrice: false,
      ),
      QuoteServiceItem(
        id: 's4',
        name: 'Atención y mantenimiento de jardines',
        unitPrice: 45.0,
        unitLabel: '/ m²',
        icon: Icons.yard_outlined,
        isSelected: true,
        quantity: 50.0,
        isFixedPrice: false,
      ),
      QuoteServiceItem(
        id: 's5',
        name: 'Fumigación y control fitosanitario',
        unitPrice: 35.0,
        unitLabel: '/ m²',
        icon: Icons.pest_control_outlined,
        isSelected: false,
        quantity: 30.0,
        isFixedPrice: false,
      ),
      QuoteServiceItem(
        id: 's6',
        name: 'Poda estética y perfilado',
        unitPrice: 650.0,
        unitLabel: 'Precio fijo',
        icon: Icons.content_cut_outlined,
        isSelected: false,
        quantity: 1.0,
        isFixedPrice: true,
      ),
      QuoteServiceItem(
        id: 's7',
        name: 'Retiro / Tala de árbol o tocón',
        unitPrice: 1200.0,
        unitLabel: 'Precio fijo',
        icon: Icons.park_outlined,
        isSelected: false,
        quantity: 1.0,
        isFixedPrice: true,
      ),
    ];
  }
}
