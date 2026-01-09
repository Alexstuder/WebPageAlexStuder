import 'package:uuid/uuid.dart';

class HowToTopic {
  final String id;
  final String userProfileId;
  final String title;
  final String content;
  final int position;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  HowToTopic({
    required this.id,
    required this.userProfileId,
    required this.title,
    this.content = '',
    this.position = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory HowToTopic.create({
    required String userProfileId,
    required String title,
    String content = '',
    int position = 0,
  }) {
    return HowToTopic(
      id: const Uuid().v4(),
      userProfileId: userProfileId,
      title: title,
      content: content,
      position: position,
    );
  }

  factory HowToTopic.fromJson(Map<String, dynamic> json) {
    return HowToTopic(
      id: json['id'],
      userProfileId: json['user_profile_id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      position: json['position'] ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_profile_id': userProfileId,
      'title': title,
      'content': content,
      'position': position,
    };
  }

  HowToTopic copyWith({
    String? title,
    String? content,
    int? position,
  }) {
    return HowToTopic(
      id: id,
      userProfileId: userProfileId,
      title: title ?? this.title,
      content: content ?? this.content,
      position: position ?? this.position,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
