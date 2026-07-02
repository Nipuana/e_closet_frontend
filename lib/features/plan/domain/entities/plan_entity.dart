import 'package:equatable/equatable.dart';

/// A scheduled outfit — an [outfitId] assigned to a calendar [date], with its
/// own independent reminder settings.
class PlanEntity extends Equatable {
  final String? id;
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

  const PlanEntity({
    this.id,
    this.userId = '',
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

  /// The calendar day (time stripped) this plan belongs to.
  DateTime get day => DateTime(date.year, date.month, date.day);

  PlanEntity copyWith({
    String? id,
    String? userId,
    String? outfitId,
    DateTime? date,
    String? title,
    String? note,
    bool? reminderEnabled,
    DateTime? reminderAt,
    bool? worn,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlanEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      outfitId: outfitId ?? this.outfitId,
      date: date ?? this.date,
      title: title ?? this.title,
      note: note ?? this.note,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderAt: reminderAt ?? this.reminderAt,
      worn: worn ?? this.worn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, userId, outfitId, date, title, note, reminderEnabled, reminderAt, worn, createdAt, updatedAt];
}
