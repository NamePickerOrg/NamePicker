import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'student.dart';

class ListGroup {
  int? id;
  String name;
  ListGroup({this.id, required this.name});
  Map<String, dynamic> toMap() => {'id': id, 'name': name};
  factory ListGroup.fromMap(Map<String, dynamic> map) => ListGroup(id: map['id'], name: map['name']);
}

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
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        // 简单处理：升级时重建表（开发期安全，生产建议做数据迁移）
        await db.execute('DROP TABLE IF EXISTS students');
        await db.execute('DROP TABLE IF EXISTS lists');
        await _createDB(db, newVersion);
      },
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE lists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        gender TEXT NOT NULL,
        studentId TEXT NOT NULL,
        listId INTEGER NOT NULL,
        FOREIGN KEY(listId) REFERENCES lists(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<Student> create(Student student, int listId) async {
    final db = await instance.database;
    final id = await db.insert('students', {
      ...student.toMap(),
      'listId': listId,
    });
    return student..id = id;
  }

  Future<List<Student>> readAll(int listId) async {
    final db = await instance.database;
    final result = await db.query('students', where: 'listId = ?', whereArgs: [listId]);
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

  // 名单相关
  Future<int> createList(String name) async {
    final db = await instance.database;
    return await db.insert('lists', {'name': name});
  }

  Future<List<ListGroup>> readAllLists() async {
    final db = await instance.database;
    var result = await db.query('lists');
    if (result.isEmpty) {
      // 自动创建一个默认名单
      await db.insert('lists', {'name': '默认名单'});
      result = await db.query('lists');
    }
    return result.map((map) => ListGroup.fromMap(map)).toList();
  }

  Future<int> updateList(ListGroup list) async {
    final db = await instance.database;
    return db.update('lists', list.toMap(), where: 'id = ?', whereArgs: [list.id]);
  }

  Future<int> deleteList(int id) async {
    final db = await instance.database;
    // 删除名单时，学生表中对应的学生会被级联删除
    return db.delete('lists', where: 'id = ?', whereArgs: [id]);
  }

  // Future<int> update(Student student) async {
  //   final db = await instance.database;
  //   return db.update(
  //     'students',
  //     student.toMap(),
  //     where: 'id = ?',
  //     whereArgs: [student.id],
  //   );
  // }

  // Future<int> delete(int id) async {
  //   final db = await instance.database;
  //   return db.delete(
  //     'students',
  //     where: 'id = ?',
  //     whereArgs: [id],
  //   );
  // }

  Future close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
