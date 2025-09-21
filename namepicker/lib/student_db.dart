import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'student.dart';

class StudentDatabase {
  static final StudentDatabase instance = StudentDatabase._init();
  static Database? _database;

  StudentDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('students.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        gender TEXT NOT NULL,
        studentId TEXT NOT NULL
      )
    ''');
  }

  Future<Student> create(Student student) async {
    final db = await instance.database;
    final id = await db.insert('students', student.toMap());
    return student..id = id;
  }

  Future<List<Student>> readAll() async {
    final db = await instance.database;
    final result = await db.query('students');
    return result.map((map) => Student.fromMap(map)).toList();
  }

  Future<int> update(Student student) async {
    final db = await instance.database;
    return db.update(
      'students',
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return db.delete(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
