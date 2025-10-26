import 'package:uuid/uuid.dart';

class Category {
  final String id;
  final String name;
  final String color;
  final DateTime createdAt;

  Category({
    String? id,
    required this.name,
    required this.color,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      color: map['color'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Category copyWith({
    String? name,
    String? color,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt,
    );
  }

  // Cores pré-definidas para categorias
  static List<String> get predefinedColors {
    return [
      '#FF6B6B', // Vermelho
      '#4ECDC4', // Verde água
      '#45B7D1', // Azul claro
      '#96CEB4', // Verde claro
      '#FFEAA7', // Amarelo
      '#DDA0DD', // Lilás
      '#98D8C8', // Verde menta
      '#F7DC6F', // Amarelo claro
      '#BB8FCE', // Roxo claro
      '#85C1E9', // Azul céu
      '#F8C471', // Laranja
      '#82E0AA', // Verde
    ];
  }

  static String get defaultColor => predefinedColors[2]; // Azul claro como padrão
}