import 'package:flutter/material.dart';
import '../models/inventory_item.dart';

/// Controlador de Inventario / Stock en arquitectura MVC.
/// Coordina la lista de insumos, herramientas, filtros y existencias críticas.
class StockController extends ChangeNotifier {
  List<InventoryItem> _items = [];
  String _selectedCategory = 'Todos';
  String _searchQuery = '';

  StockController() {
    _loadItems();
  }

  List<InventoryItem> get items => _items;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  void _loadItems() {
    _items = InventoryItem.sampleItems();
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<InventoryItem> get filteredItems {
    return _items.where((item) {
      final matchesCategory =
          _selectedCategory == 'Todos' || item.category == _selectedCategory;
      final matchesQuery = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.sku.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  int get lowStockCount => _items.where((item) => item.isLowStock).length;

  int get totalStockQuantity =>
      _items.fold(0, (sum, item) => sum + item.quantity);

  void updateQuantity(InventoryItem item, int delta) {
    final newQty = item.quantity + delta;
    if (newQty >= 0) {
      item.quantity = newQty;
      notifyListeners();
    }
  }

  void addItem(InventoryItem newItem) {
    _items.add(newItem);
    notifyListeners();
  }
}

