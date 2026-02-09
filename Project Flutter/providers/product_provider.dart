import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Product> _favorites = [];

  List<Product> get allProducts => [..._products];
  List<Product> get favorites => [..._favorites];

  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> fetchProducts({String? userId}) async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiService.get('products', params: {
      'category': _selectedCategory,
      'search': _searchQuery,
      if (userId != null) 'user_id': userId,
    });

    if (response['status'] == true && response['data'] != null) {
      final List<dynamic> data = response['data'];
      _products = data.map((item) => Product(
        id: item['id'].toString(), // Ensure ID is string to match model
        name: item['name'],
        category: item['category'],
        price: double.parse(item['price'].toString()),
        imagePath: item['imagePath'],
        description: item['description'] ?? '',
        quantity: item['quantity'] ?? 0,
        isFavorite: item['isFavorite'] ?? false,
      )).toList();
    } else {
      // Handle error or keep empty
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchFavorites(String userId) async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiService.get('favorites', params: {'user_id': userId});

    if (response['status'] == true && response['data'] != null) {
      final List<dynamic> data = response['data'];
      _favorites = data.map((item) => Product(
        id: item['id'].toString(),
        name: item['name'],
        category: item['category'],
        price: double.parse(item['price'].toString()),
        imagePath: item['imagePath'],
        description: item['description'] ?? '',
        quantity: item['quantity'] ?? 0,
        isFavorite: true,
      )).toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  List<Product> get products {
    return [..._products];
  }

  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  void setCategory(String category) {
    _selectedCategory = category;
    fetchProducts(); // Refetch with new category
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    if (query.length > 2 || query.isEmpty) {
        fetchProducts(); // Optimize: debounce ideally, but refetching for now
    }
    notifyListeners();
  }

  final Map<String, int> _cartItems = {}; // {productId: quantity}
  final Map<String, Product> _cartProductData = {}; // {productId: Product}

  Map<String, int> get cartItems => _cartItems;
  Map<String, Product> get cartProductData => _cartProductData;

  void addToCart(Product product) {
    String id = product.id;
    int availableStock = product.quantity;
    
    if (_cartItems.containsKey(id)) {
      if (_cartItems[id]! < availableStock) {
        _cartItems[id] = _cartItems[id]! + 1;
      }
    } else {
      if (availableStock > 0) {
        _cartItems[id] = 1;
        _cartProductData[id] = product;
      }
    }
    notifyListeners();
  }

  void removeFromCart(String id) {
    _cartItems.remove(id);
    _cartProductData.remove(id);
    notifyListeners();
  }

  void updateQuantity(String id, int delta) {
    if (_cartItems.containsKey(id)) {
      int availableStock = _cartProductData[id]?.quantity ?? 0;
      int newQty = _cartItems[id]! + delta;
      
      if (newQty > availableStock && delta > 0) {
        // Prevent exceeding stock
        return;
      }

      if (newQty > 0) {
        _cartItems[id] = newQty;
      } else {
        _cartItems.remove(id);
        _cartProductData.remove(id);
      }
      notifyListeners();
    }
  }

  double get cartSubtotal {
    double total = 0;
    _cartItems.forEach((id, qty) {
      final product = _cartProductData[id];
      if (product != null) {
        total += product.price * qty;
      }
    });
    return total;
  }

  double get deliveryFee => 0.0;
  double get tax => 0.0;
  double get discount => 0.0;

  double get totalCost {
    return cartSubtotal;
  }

  Future<bool> toggleFavorite(String productId, String userId) async {
    final response = await ApiService.post('favorites', {
      'user_id': userId,
      'product_id': productId,
    });

    if (response['status'] == true) {
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index].isFavorite = response['isFavorite'] ?? !_products[index].isFavorite;
        
        // Update favorites list
        if (_products[index].isFavorite) {
          if (!_favorites.any((p) => p.id == productId)) {
            _favorites.add(_products[index]);
          }
        } else {
          _favorites.removeWhere((p) => p.id == productId);
        }
        notifyListeners();
      } else {
        // If not in main list (maybe on favorites screen only), toggle based on response
        final favIndex = _favorites.indexWhere((p) => p.id == productId);
        if (favIndex != -1 && response['isFavorite'] == false) {
           _favorites.removeAt(favIndex);
           notifyListeners();
        }
      }
      return true;
    }
    return false;
  }

  Future<bool> addProduct(Product product, XFile? imageFile) async {
    final response = await ApiService.postMultipart('products', {
        'name': product.name,
        'category': product.category,
        'price': product.price.toString(),
        'description': product.description,
        'quantity': product.quantity.toString(),
        'imagePath': product.imagePath, 
    }, imageFile);

    if (response['status'] == true) {
        fetchProducts(); 
        return true;
    }
    return false;
  }

  Future<void> deleteProduct(String id) async {
    final response = await ApiService.delete('products', id);
    if (response['status'] == true) {
        _products.removeWhere((p) => p.id == id);
        notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    _cartProductData.clear();
    notifyListeners();
  }

  Future<bool> updateProduct(Product updatedProduct, XFile? imageFile) async {
    // For now, let's stick to POST for everything that might have an image.
    final response = await ApiService.postMultipart('products?id=${updatedProduct.id}', {
        'name': updatedProduct.name,
        'category': updatedProduct.category,
        'price': updatedProduct.price.toString(),
        'description': updatedProduct.description,
        'quantity': updatedProduct.quantity.toString(),
        'imagePath': updatedProduct.imagePath,
    }, imageFile);

    if (response['status'] == true) {
        fetchProducts();
        return true;
    }
    return false;
  }
}
