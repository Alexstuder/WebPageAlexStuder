class BrewKettle {
  const BrewKettle({
    this.id,
    required this.userProfileId,
    required this.brand,
    this.model,
    this.isDefault = false,
    this.volumeLiters,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String userProfileId;
  final String brand;
  final String? model;
  final bool isDefault;
  final double? volumeLiters;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BrewKettle copyWith({
    String? id,
    String? userProfileId,
    String? brand,
    String? model,
    bool? isDefault,
    double? volumeLiters,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BrewKettle(
      id: id ?? this.id,
      userProfileId: userProfileId ?? this.userProfileId,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      isDefault: isDefault ?? this.isDefault,
      volumeLiters: volumeLiters ?? this.volumeLiters,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory BrewKettle.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? value) =>
        value == null ? null : DateTime.tryParse(value);
    return BrewKettle(
      id: json['id'] as String?,
      userProfileId: json['user_profile_id'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String?,
      isDefault: (json['is_default'] as bool?) ?? false,
      volumeLiters: (json['volume_liters'] as num?)?.toDouble(),
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
      'model': model,
      'is_default': isDefault,
      'volume_liters': volumeLiters,
      'notes': notes,
    };
  }
}
