import 'package:hive/hive.dart';

part 'note_option.g.dart';

@HiveType(typeId: 102)
class NoteOption extends HiveObject {
  @HiveField(0)
  final String label;

  @HiveField(1)
  final bool requireRemark;

  @HiveField(2)
  final bool isSystemOnly;

  NoteOption({
    required this.label,
    this.requireRemark = false,
    this.isSystemOnly = false,
  });

  // Factory untuk parsing dari JSON API
  factory NoteOption.fromJson(Map<String, dynamic> json) {
    return NoteOption(
      label: json['label'] as String? ?? '',
      requireRemark: json['require_remark'] as bool? ?? false,
      isSystemOnly: json['is_system_only'] as bool? ?? false,
    );
  }

  factory NoteOption.fromString(String text) {
    return NoteOption(label: text);
  }
}