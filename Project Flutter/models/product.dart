class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final String imagePath;
  final String description;
  final int quantity;
  bool isFavorite;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imagePath,
    this.description = "",
    this.quantity = 0,
    this.isFavorite = false,
  });
}
