class YeastEntryModel {
  const YeastEntryModel({
    required this.brand,
    required this.type,
  });

  final String brand;
  final String type;

  Map<String, dynamic> toJson() => {
        'brand': brand,
        'type': type,
      };

  factory YeastEntryModel.fromJson(Map<String, dynamic> json) =>
      YeastEntryModel(
        brand: (json['brand'] as String?) ?? '',
        type: (json['type'] as String?) ?? '',
      );
}

class MaltDepotEntry {
  const MaltDepotEntry({required this.name, required this.url});

  final String name;
  final String url;

  Map<String, dynamic> toJson() => {
        'name': name,
        'url': url,
      };

  factory MaltDepotEntry.fromJson(Map<String, dynamic> json) =>
      MaltDepotEntry(
        name: (json['name'] as String?) ?? '',
        url: (json['url'] as String?) ?? '',
      );
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.kettleBrand,
    required this.kettleType,
    required this.defaultBatchLiters,
    required this.fermenterBrand,
    required this.fermenterType,
    required this.controller,
    this.controllerUser,
    this.controllerApiKey,
    required this.yeastEntries,
    required this.maltDepot,
  });

  final String id;
  final String name;
  final String avatarUrl;
  final String kettleBrand;
  final String kettleType;
  final double? defaultBatchLiters;
  final String fermenterBrand;
  final String fermenterType;
  final String controller;
  final String? controllerUser;
  final String? controllerApiKey;
  final List<YeastEntryModel> yeastEntries;
  final List<MaltDepotEntry> maltDepot;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar_url': avatarUrl,
        'kettle_brand': kettleBrand,
        'kettle_type': kettleType,
        'default_batch_liters': defaultBatchLiters,
        'fermenter_brand': fermenterBrand,
        'fermenter_type': fermenterType,
        'controller': controller,
        'controller_user': controllerUser,
        'controller_api_key': controllerApiKey,
        'yeast_entries': yeastEntries.map((e) => e.toJson()).toList(),
        'malt_depot': maltDepot.map((e) => e.toJson()).toList(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String? ?? '',
        kettleBrand: json['kettle_brand'] as String? ?? '',
        kettleType: json['kettle_type'] as String? ?? '',
        defaultBatchLiters:
            (json['default_batch_liters'] as num?)?.toDouble(),
        fermenterBrand: json['fermenter_brand'] as String? ?? '',
        fermenterType: json['fermenter_type'] as String? ?? '',
        controller: json['controller'] as String? ?? '',
        controllerUser: json['controller_user'] as String?,
        controllerApiKey: json['controller_api_key'] as String?,
        yeastEntries: (json['yeast_entries'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(YeastEntryModel.fromJson)
            .toList(),
        maltDepot: (json['malt_depot'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(MaltDepotEntry.fromJson)
            .toList(),
      );
}
