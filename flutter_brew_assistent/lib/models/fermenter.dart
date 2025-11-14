class Fermenter {
  const Fermenter({
    this.id,
    required this.userProfileId,
    required this.brand,
    this.type,
    this.volumeLiters,
    this.hasHeating = false,
    this.hasCooling = false,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String userProfileId;
  final String brand;
  final String? type;
  final double? volumeLiters;
  final bool hasHeating;
  final bool hasCooling;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Fermenter copyWith({
    String? id,
    String? userProfileId,
    String? brand,
    String? type,
    double? volumeLiters,
    bool? hasHeating,
    bool? hasCooling,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Fermenter(
      id: id ?? this.id,
      userProfileId: userProfileId ?? this.userProfileId,
      brand: brand ?? this.brand,
      type: type ?? this.type,
      volumeLiters: volumeLiters ?? this.volumeLiters,
      hasHeating: hasHeating ?? this.hasHeating,
      hasCooling: hasCooling ?? this.hasCooling,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Fermenter.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? value) =>
        value == null ? null : DateTime.tryParse(value);
    return Fermenter(
      id: json['id'] as String?,
      userProfileId: json['user_profile_id'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      type: json['type'] as String?,
      volumeLiters: (json['volume_liters'] as num?)?.toDouble(),
      hasHeating: (json['has_heating'] as bool?) ?? false,
      hasCooling: (json['has_cooling'] as bool?) ?? false,
      notes: json['notes'] as String?,
      createdAt: parseDate(json['created_at'] as String?),
      updatedAt: parseDate(json['updated_at'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_profile_id': userProfileId,
      'brand': brand,
      'type': type,
      'volume_liters': volumeLiters,
      'has_heating': hasHeating,
      'has_cooling': hasCooling,
      'notes': notes,
    };
  }
}
