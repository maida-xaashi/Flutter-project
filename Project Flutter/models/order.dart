import 'product.dart';

class OrderItem {
  final Product product;
  final int quantity;

  OrderItem({required this.product, required this.quantity});
}

class Order {
  final String id;
  final List<OrderItem> items;
  final double totalAmount;
  final DateTime date;

  Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.date,
  });
}
