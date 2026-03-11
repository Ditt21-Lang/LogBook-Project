import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'package:hive/hive.dart';

part 'log_model.g.dart';

@HiveType(typeId: 1)
enum LogCategory { 
  @HiveField(0) mechanical, 
  @HiveField(1) electronic, 
  @HiveField(2) software 
}

@HiveType(typeId: 0)
class LogModel {
  @HiveField(0)
  final String? id; 

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final LogCategory category;

  @HiveField(5)
  final String authorId; // ID unik pengguna yang membuat log

  @HiveField(6)
  final String teamId; // ID kelompok (Collaborative Team ID)

  @HiveField(7)
  final bool isPublic;

  LogModel({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.category, 
    required this.authorId, 
    required this.teamId,
    required this.isPublic,
  });

  ///  Convert Object → Map (kirim ke MongoDB)
  Map<String, dynamic> toMap() {
    return {
      '_id': id == null ? ObjectId() : ObjectId.fromHexString(id!), // Auto-generate jika belum ada
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'category': category.name,
      'authorId': authorId,
      'teamId': teamId,
      'isPublic': isPublic,
    };
  }

  ///  Convert Map (Mongo) → Object Flutter
  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: map['_id'] == null 
        ? null 
        : map['_id'] is ObjectId
          ? (map['_id'] as ObjectId).toHexString()
          : map['_id'],
          
      title: map['title'] ?? '',
      description: map['description'] ?? '',

      date: map['date'] == null
          ? DateTime.now()
          : map['date'] is DateTime
            ? map['date']
            : DateTime.parse(map['date']),

      category: LogCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => LogCategory.software,
      ), 
      authorId: map['authorId'] ?? 'unknown_user', 
      teamId: map['teamId'] ?? 'no_team',
      isPublic: map['isPublic'] ?? false,
    );
  }

  ///  CopyWith untuk update data
  LogModel copyWith({
    ObjectId? id,
    String? title,
    String? description,
    DateTime? date,
    LogCategory? category,
    String? authorId,
    String? teamId,
    bool? isPublic,
  }) {
    return LogModel(
      id: id != null ? id.toHexString() : this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      category: category ?? this.category, 
      authorId: authorId ?? this.authorId, 
      teamId: teamId ?? this.teamId,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}