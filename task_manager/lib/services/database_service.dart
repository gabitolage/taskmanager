import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../models/category.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);
      
      print('Database path: $path');
      
      return await openDatabase(
        path,
        version: 4,
        onCreate: _createDB,
        onUpgrade: _upgradeDB, // Adicionar upgrade
      );
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Criar tabela de categorias
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Criar tabela de tarefas
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        completed INTEGER NOT NULL,
        priority TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        dueDate TEXT,
        categoryId TEXT,
        FOREIGN KEY (categoryId) REFERENCES categories (id)
        photoPath TEXT,
        completedAt TEXT,
        completedBy TEXT,
        latitude REAL,
        longitude REAL,
        locationName TEXT
      )
    ''');

    // Inserir categorias padrão
    final defaultCategories = [
      Category(name: 'Trabalho', color: Category.predefinedColors[2]),
      Category(name: 'Pessoal', color: Category.predefinedColors[4]),
      Category(name: 'Estudos', color: Category.predefinedColors[9]),
      Category(name: 'Saúde', color: Category.predefinedColors[5]),
      Category(name: 'Compras', color: Category.predefinedColors[10]),
    ];

    for (final category in defaultCategories) {
      await db.insert('categories', category.toMap());
    }

    print('Database tables created successfully');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Adicionar tabela de categorias
      await db.execute('''
        CREATE TABLE categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          color TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');

      // Adicionar coluna categoryId na tabela tasks
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE tasks ADD COLUMN photoPath TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE tasks ADD COLUMN completedAt TEXT');
      await db.execute('ALTER TABLE tasks ADD COLUMN completedBy TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE tasks ADD COLUMN latitude REAL');
      await db.execute('ALTER TABLE tasks ADD COLUMN longitude REAL');
      await db.execute('ALTER TABLE tasks ADD COLUMN locationName TEXT');
    }
    print('✅ Banco migrado de v$oldVersion para v$newVersion');

      // Inserir categorias padrão
      final defaultCategories = [
        Category(name: 'Trabalho', color: Category.predefinedColors[2]),
        Category(name: 'Pessoal', color: Category.predefinedColors[4]),
        Category(name: 'Estudos', color: Category.predefinedColors[9]),
        Category(name: 'Saúde', color: Category.predefinedColors[5]),
        Category(name: 'Compras', color: Category.predefinedColors[10]),
      ];

      for (final category in defaultCategories) {
        await db.insert('categories', category.toMap());
      }

      print('Database upgraded to version 2');
    }
  }

  // Métodos para Categorias
  Future<Category> createCategory(Category category) async {
    final db = await database;
    await db.insert('categories', category.toMap());
    print('Category created: ${category.name}');
    return category;
  }

  Future<List<Category>> readAllCategories() async {
    try {
      final db = await database;
      final result = await db.query('categories', orderBy: 'name ASC');
      print('Loaded ${result.length} categories from database');
      return result.map((map) => Category.fromMap(map)).toList();
    } catch (e) {
      print('Error reading categories: $e');
      return [];
    }
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    final result = await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
    print('Category updated: ${category.name}');
    return result;
  }

  Future<int> deleteCategory(String id) async {
    final db = await database;
    
    // Primeiro, remover a categoria das tarefas
    await db.update(
      'tasks',
      {'categoryId': null},
      where: 'categoryId = ?',
      whereArgs: [id],
    );
    
    // Depois deletar a categoria
    final result = await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    print('Category deleted: $id');
    return result;
  }

  // Métodos existentes para Tasks (atualizados)
  Future<Task> create(Task task) async {
    final db = await database;
    await db.insert('tasks', task.toMap());
    print('Task created: ${task.title}');
    return task;
  }

  Future<Task?> read(String id) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Task>> readAll() async {
    try {
      final db = await database;
      const orderBy = '''
        completed ASC,
        CASE WHEN dueDate IS NULL THEN 1 ELSE 0 END,
        dueDate ASC,
        createdAt DESC
      ''';
      final result = await db.query('tasks', orderBy: orderBy);
      print('Loaded ${result.length} tasks from database');
      return result.map((map) => Task.fromMap(map)).toList();
    } catch (e) {
      print('Error reading tasks: $e');
      return [];
    }
  }

  Future<int> update(Task task) async {
    final db = await database;
    final result = await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
    print('Task updated: ${task.title}');
    return result;
  }

  Future<int> delete(String id) async {
    final db = await database;
    final result = await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
    print('Task deleted: $id');
    return result;
  }

    // Método especial: buscar tarefas por proximidade
  Future<List<Task>> getTasksNearLocation({
    required double latitude,
    required double longitude,
    double radiusInMeters = 1000,
  }) async {
    final allTasks = await readAll();
    
    return allTasks.where((task) {
      if (!task.hasLocation) return false;
      
      // Cálculo de distância usando fórmula de Haversine (simplificada)
      final latDiff = (task.latitude! - latitude).abs();
      final lonDiff = (task.longitude! - longitude).abs();
      final distance = ((latDiff * 111000) + (lonDiff * 111000)) / 2;
      
      return distance <= radiusInMeters;
    }).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}