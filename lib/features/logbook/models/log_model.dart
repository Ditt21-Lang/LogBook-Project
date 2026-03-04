import 'package:mongo_dart/mongo_dart.dart';

enum LogCategory { pekerjaan, pribadi, urgent }

class LogModel {
  final ObjectId? id; 
  final String title;
  final String description;
  final DateTime date;
  final LogCategory category;

  LogModel({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.category,
  });

  ///  Convert Object → Map (kirim ke MongoDB)
  Map<String, dynamic> toMap() {
    return {
      '_id': id ?? ObjectId(), // Auto-generate jika belum ada
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'category': category.name,
    };
  }

  ///  Convert Map (Mongo) → Object Flutter
  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: map['_id'] == null 
        ? null 
        : map['_id'] is ObjectId
          ? map['_id'] 
          : ObjectId.fromHexString(map['_id']),
          
      title: map['title'] ?? '',
      description: map['description'] ?? '',

      date: map['date'] == null
          ? DateTime.now()
          : map['date'] is DateTime
            ? map['date']
            : DateTime.parse(map['date']),

      category: LogCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => LogCategory.pribadi,
      ),
    );
  }

  ///  CopyWith untuk update data
  LogModel copyWith({
    ObjectId? id,
    String? title,
    String? description,
    DateTime? date,
    LogCategory? category,
  }) {
    return LogModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      category: category ?? this.category,
    );
  }
}