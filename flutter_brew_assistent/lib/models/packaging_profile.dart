class PackagingProfile {
  const PackagingProfile({
    this.id,
    required this.userProfileId,
    required this.name,
    this.bottleEnabled = false,
    this.bottleCarbonationTempC,
    this.bottleStorageTempC,
    this.kegEnabled = false,
    this.kegCarbonationTempC,
    this.kegStorageTempC,
    this.kegVolumeLiters,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String userProfileId;
  final String name;
  final bool bottleEnabled;
  final double? bottleCarbonationTempC;
  final double? bottleStorageTempC;
  final bool kegEnabled;
  final double? kegCarbonationTempC;
  final double? kegStorageTempC;
  final double? kegVolumeLiters;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PackagingProfile copyWith({
    String? id,
    String? userProfileId,
    String? name,
    bool? bottleEnabled,
    double? bottleCarbonationTempC,
    double? bottleStorageTempC,
    bool? kegEnabled,
    double? kegCarbonationTempC,
    double? kegStorageTempC,
    double? kegVolumeLiters,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PackagingProfile(
      id: id ?? this.id,
      userProfileId: userProfileId ?? this.userProfileId,
      name: name ?? this.name,
      bottleEnabled: bottleEnabled ?? this.bottleEnabled,
      bottleCarbonationTempC:
          bottleCarbonationTempC ?? this.bottleCarbonationTempC,
      bottleStorageTempC: bottleStorageTempC ?? this.bottleStorageTempC,
      kegEnabled: kegEnabled ?? this.kegEnabled,
      kegCarbonationTempC: kegCarbonationTempC ?? this.kegCarbonationTempC,
      kegStorageTempC: kegStorageTempC ?? this.kegStorageTempC,
      kegVolumeLiters: kegVolumeLiters ?? this.kegVolumeLiters,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory PackagingProfile.fromJson(Map<String, dynamic> json) {
    DateTime? parse(String? value) =>
        value == null ? null : DateTime.tryParse(value);
    return PackagingProfile(
      id: json['id'] as String?,
      userProfileId: json['user_profile_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      bottleEnabled: (json['bottle_enabled'] as bool?) ?? false,
      bottleCarbonationTempC:
          (json['bottle_carbonation_temp_c'] as num?)?.toDouble(),
      bottleStorageTempC:
          (json['bottle_storage_temp_c'] as num?)?.toDouble(),
      kegEnabled: (json['keg_enabled'] as bool?) ?? false,
      kegCarbonationTempC:
          (json['keg_carbonation_temp_c'] as num?)?.toDouble(),
      kegStorageTempC: (json['keg_storage_temp_c'] as num?)?.toDouble(),
      kegVolumeLiters: (json['keg_volume_l'] as num?)?.toDouble(),
      isDefault: (json['is_default'] as bool?) ?? false,
      createdAt: parse(json['created_at'] as String?),
      updatedAt: parse(json['updated_at'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_profile_id': userProfileId,
      'name': name,
      'bottle_enabled': bottleEnabled,
      'bottle_carbonation_temp_c': bottleCarbonationTempC,
      'bottle_storage_temp_c': bottleStorageTempC,
      'keg_enabled': kegEnabled,
      'keg_carbonation_temp_c': kegCarbonationTempC,
      'keg_storage_temp_c': kegStorageTempC,
      'keg_volume_l': kegVolumeLiters,
      'is_default': isDefault,
    };
  }
}
