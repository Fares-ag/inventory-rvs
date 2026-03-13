class ProductVariant {
  final int? id;
  final int productId;
  final String? size;
  final String? color;
  final String? material;
  final String? style;
  final String? otherAttributes; // JSON string for additional attributes
  final String? variantSku; // Optional unique SKU for this variant

  ProductVariant({
    this.id,
    required this.productId,
    this.size,
    this.color,
    this.material,
    this.style,
    this.otherAttributes,
    this.variantSku,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'size': size,
      'color': color,
      'material': material,
      'style': style,
      'other_attributes': otherAttributes,
      'variant_sku': variantSku,
    };
  }

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      size: map['size'] as String?,
      color: map['color'] as String?,
      material: map['material'] as String?,
      style: map['style'] as String?,
      otherAttributes: map['other_attributes'] as String?,
      variantSku: map['variant_sku'] as String?,
    );
  }

  String get displayName {
    final parts = <String>[];
    if (size != null) parts.add('Size: $size');
    if (color != null) parts.add('Color: $color');
    if (material != null) parts.add('Material: $material');
    if (style != null) parts.add('Style: $style');
    return parts.isEmpty ? 'Default' : parts.join(', ');
  }

  ProductVariant copyWith({
    int? id,
    int? productId,
    String? size,
    String? color,
    String? material,
    String? style,
    String? otherAttributes,
    String? variantSku,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      size: size ?? this.size,
      color: color ?? this.color,
      material: material ?? this.material,
      style: style ?? this.style,
      otherAttributes: otherAttributes ?? this.otherAttributes,
      variantSku: variantSku ?? this.variantSku,
    );
  }
}


