import 'package:flutter/material.dart';
import '../models/garden_photo.dart';
import '../models/quote_item.dart';

/// Controlador del Cotizador en arquitectura MVC.
/// Administra servicios por m², fotos con diagnóstico IA y validaciones estrictas de cliente.
class CotizadorController extends ChangeNotifier {
  List<QuoteServiceItem> _services = [];
  List<GardenPhoto> _capturedPhotos = [];
  DateTime _selectedDate = DateTime(2026, 10, 31);
  bool _isGeneratingPdf = false;

  CotizadorController() {
    _services = QuoteServiceItem.defaultServices();
    _capturedPhotos = GardenPhoto.samplePhotos();
  }

  List<QuoteServiceItem> get services => _services;
  List<GardenPhoto> get capturedPhotos => _capturedPhotos;
  DateTime get selectedDate => _selectedDate;
  bool get isGeneratingPdf => _isGeneratingPdf;

  double get totalPrice {
    double total = 0.0;
    for (final service in _services) {
      if (service.isSelected) {
        total += service.subtotal;
      }
    }
    return total;
  }

  double get totalSquareMeters {
    double total = 0.0;
    for (final service in _services) {
      // Solo se suman metros cuadrados a servicios por m², NO a servicios de precio fijo (ej. árboles, perfilado)
      if (service.isSelected && !service.isFixedPrice) {
        total += service.quantity;
      }
    }
    return total;
  }

  void addCustomService({
    required String name,
    required double unitPrice,
    required bool isFixedPrice,
    double quantity = 1.0,
    IconData icon = Icons.design_services_outlined,
  }) {
    final newId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final newItem = QuoteServiceItem(
      id: newId,
      name: name,
      unitPrice: unitPrice,
      unitLabel: isFixedPrice ? 'Precio fijo' : '/ m²',
      icon: icon,
      isSelected: true,
      quantity: quantity,
      isFixedPrice: isFixedPrice,
    );
    _services.add(newItem);
    notifyListeners();
  }

  String formatM2(double value) {
    if (value % 1 == 0) {
      return '${value.toInt()} m²';
    }
    return '${value.toStringAsFixed(1)} m²';
  }

  void toggleServiceSelection(QuoteServiceItem service, bool isSelected) {
    service.isSelected = isSelected;
    notifyListeners();
  }

  void updateServiceQuantity(QuoteServiceItem service, double newQuantity) {
    service.quantity = newQuantity.clamp(0.5, 99999.0);
    notifyListeners();
  }

  void updateServiceUnitPrice(QuoteServiceItem service, double newPrice) {
    if (newPrice > 0) {
      service.unitPrice = newPrice;
      notifyListeners();
    }
  }

  void addPhoto(GardenPhoto photo) {
    _capturedPhotos.add(photo);
    notifyListeners();
  }

  void removePhotoAt(int index) {
    if (index >= 0 && index < _capturedPhotos.length) {
      _capturedPhotos.removeAt(index);
      notifyListeners();
    }
  }

  void setAppointmentDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setGeneratingPdf(bool generating) {
    _isGeneratingPdf = generating;
    notifyListeners();
  }

  // Validaciones if / else de datos del cliente
  static String? validateClientName(String name) {
    final trimmed = name.trim();
    final nameRegex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]{2,60}$');
    if (trimmed.isEmpty) {
      return 'Ingresa el nombre del cliente (solo letras)';
    } else if (!nameRegex.hasMatch(trimmed)) {
      return 'El nombre solo permite letras (sin números ni símbolos)';
    }
    return null;
  }

  static String? validateClientPhone(String phone) {
    final trimmed = phone.trim();
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    if (trimmed.isEmpty) {
      return 'Ingresa el número celular de 10 dígitos';
    } else if (!phoneRegex.hasMatch(trimmed)) {
      return 'El número debe contener exactamente 10 dígitos (sin letras)';
    }
    return null;
  }
}

