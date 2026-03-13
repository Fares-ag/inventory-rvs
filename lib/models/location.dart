class Location {
  final String? id; // Changed to String for Firestore compatibility
  final String name;
  final String? description;
  final String? address;

  Location({
    this.id,
    required this.name,
    this.description,
    this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
    };
  }

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      id: map['id']?.toString(), // Handle both int and String IDs
      name: map['name'] as String,
      description: map['description'] as String?,
      address: map['address'] as String?,
    );
  }

  Location copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
  }) {
    return Location(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
    );
  }
}

