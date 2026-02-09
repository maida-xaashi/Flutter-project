import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class OrderProvider with ChangeNotifier {
  final List<Order> _orders = [];

  List<Order> get orders => [..._orders];

  Future<void> fetchOrders(String userId) async {
      // Not implemented in Backend (Get Orders) yet, but placeholder
      // For now, list is local.
      // Ideally: GET /api/orders?userId=...
  }

  Future<bool> addOrder(List<OrderItem> items, double total, String userId) async {
    final orderItems = items.map((item) => {
      "productId": item.product.id,
      "quantity": item.quantity,
      "price": item.product.price
    }).toList();

    final response = await ApiService.post('orders', {
      "userId": userId,
      "totalAmount": total,
      "items": orderItems
    });

    if (response['status'] == true) {
      final data = response['id'] != null ? response : response['data'];
      final newOrder = Order(
        id: (data != null && data['id'] != null) ? data['id'].toString() : DateTime.now().millisecondsSinceEpoch.toString(),
        items: items,
        totalAmount: total,
        date: DateTime.now(),
      );
      _orders.insert(0, newOrder);
      notifyListeners();
      return true;
    }
    return false;
  }
}
