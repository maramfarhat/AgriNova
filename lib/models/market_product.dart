class MarketProduct {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final bool availability;
  final double quantity;
  final String unit;
  final String imageUrl;
  final String? phone;

  MarketProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.availability,
    required this.quantity,
    required this.unit,
    required this.imageUrl,
    this.phone,
  });

  factory MarketProduct.fromJson(Map<String, dynamic> json) {
    return MarketProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      category: json['category'] as String,
      availability: json['availability'] == 1,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      imageUrl: json['imageUrl'] as String,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'availability': availability ? 1 : 0,
      'quantity': quantity,
      'unit': unit,
      'imageUrl': imageUrl,
      'phone': phone ?? '',
    };
  }

  MarketProduct copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? category,
    bool? availability,
    double? quantity,
    String? unit,
    String? imageUrl,
    String? phone,
  }) {
    return MarketProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      availability: availability ?? this.availability,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      imageUrl: imageUrl ?? this.imageUrl,
      phone: phone ?? this.phone,
    );
  }
}
