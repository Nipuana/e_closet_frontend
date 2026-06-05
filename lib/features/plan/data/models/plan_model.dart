import '../../domain/entities/plan_entity.dart';

/// Maps the backend plan payload (snake_case) to/from the domain entity.
class PlanModel {
  final String? planId;
  final String userId;
  final String outfitId;
  final DateTime date;
  final String? title;
  final String? note;
  final bool reminderEnabled;
  final DateTime? reminderAt;
  final bool worn;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PlanModel({
    this.planId,
    required this.userId,
    required this.outfitId,
    required this.date,
    this.title,
    this.note,
    this.reminderEnabled = true,
    this.reminderAt,
    this.worn = false,
    this.createdAt,
    this.updatedAt,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      planId: json['plan_id'] as String?,
      userId: json['user_id'] as String? ?? '',
      outfitId: json['outfit_id'] as String? ?? '',
      date: _parseDate(json['date']) ?? DateTime.now(),
      title: json['title'] as String?,
      note: json['note'] as String?,
      reminderEnabled: json['reminder_enabled'] as bool? ?? true,
      reminderAt: _parseDate(json['reminder_at']),
      worn: json['worn'] as bool? ?? false,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  PlanEntity toEntity() {
    return PlanEntity(
      id: planId,
      userId: userId,
      outfitId: outfitId,
      date: date,
      title: title,
      note: note,
      reminderEnabled: reminderEnabled,
      reminderAt: reminderAt,
      worn: worn,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
