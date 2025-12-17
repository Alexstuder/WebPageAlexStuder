class YeastBankEntry {
  const YeastBankEntry({
    this.id,
    required this.userProfileId,
    this.brewfatherId,
    required this.brand,
    required this.strain,
    this.style,
    this.attenuationMin,
    this.attenuationMax,
    this.temperatureMin,
    this.temperatureMax,
    this.url,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String userProfileId;
  final String? brewfatherId;
  final String brand;
  final String strain;
  final String? style;
  final double? attenuationMin;
  final double? attenuationMax;
  final double? temperatureMin;
  final double? temperatureMax;
  final String? url;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  YeastBankEntry copyWith({
    String? id,
    String? userProfileId,
    String? brewfatherId,
    String? brand,
    String? strain,
    String? style,
    double? attenuationMin,
    double? attenuationMax,
    double? temperatureMin,
    double? temperatureMax,
    String? url,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return YeastBankEntry(
      id: id ?? this.id,
      userProfileId: userProfileId ?? this.userProfileId,
      brewfatherId: brewfatherId ?? this.brewfatherId,
      brand: brand ?? this.brand,
      strain: strain ?? this.strain,
      style: style ?? this.style,
      attenuationMin: attenuationMin ?? this.attenuationMin,
      attenuationMax: attenuationMax ?? this.attenuationMax,
      temperatureMin: temperatureMin ?? this.temperatureMin,
      temperatureMax: temperatureMax ?? this.temperatureMax,
      url: url ?? this.url,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory YeastBankEntry.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? value) =>
        value == null ? null : DateTime.tryParse(value);
    return YeastBankEntry(
      id: json['id'] as String?,
      userProfileId: json['user_profile_id'] as String? ?? '',
      brewfatherId: json['brewfather_id'] as String?,
      brand: json['brand'] as String? ?? '',
      strain: json['strain'] as String? ?? '',
      style: json['style'] as String?,
      attenuationMin: (json['attenuation_min'] as num?)?.toDouble(),
      attenuationMax: (json['attenuation_max'] as num?)?.toDouble(),
      temperatureMin: (json['temperature_min'] as num?)?.toDouble(),
      temperatureMax: (json['temperature_max'] as num?)?.toDouble(),
      url: json['url'] as String?,
      notes: json['notes'] as String?,
      createdAt: parseDate(json['created_at'] as String?),
      updatedAt: parseDate(json['updated_at'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_profile_id': userProfileId,
      if (brewfatherId != null) 'brewfather_id': brewfatherId,
      'brand': brand,
      'strain': strain,
      'style': style,
      'attenuation_min': attenuationMin,
      'attenuation_max': attenuationMax,
      'temperature_min': temperatureMin,
      'temperature_max': temperatureMax,
      'url': url,
      'notes': notes,
    };
  }
}
