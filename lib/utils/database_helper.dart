// lib/utils/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'package:map_locator/models/map_data.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;

  DatabaseHelper._();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'map_database.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE maps ADD COLUMN createdOn TEXT;');
      await db.execute('ALTER TABLE maps ADD COLUMN lastModifiedOn TEXT;');

      final now = DateTime.now().toIso8601String();
      await db.execute(
        'UPDATE maps SET createdOn = ? WHERE createdOn IS NULL;',
        [now],
      );
      await db.execute(
        'UPDATE maps SET lastModifiedOn = ? WHERE lastModifiedOn IS NULL;',
        [now],
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE maps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        createdOn TEXT,     -- <--- NEW COLUMN
        lastModifiedOn TEXT -- <--- NEW COLUMN
      )
    ''');
    await db.execute('''
      CREATE TABLE points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        map_id INTEGER,
        latitude REAL,
        longitude REAL,
        name TEXT,
        FOREIGN KEY (map_id) REFERENCES maps(id) ON DELETE CASCADE -- <--- Added ON DELETE CASCADE for data integrity
      )
    ''');
  }

  Future<int> insertMap(MapData mapData) async {
    final db = await database;
    final mapId = await db.insert('maps', {
      'name': mapData.name,
      'createdOn': mapData.createdOn.toIso8601String(),
      'lastModifiedOn': mapData.lastModifiedOn.toIso8601String(),
    });
    for (final point in mapData.points) {
      await db.insert('points', {
        'map_id': mapId,
        'latitude': point.latitude,
        'longitude': point.longitude,
        'name': point.name,
      });
    }
    return mapId;
  }

  Future<List<MapData>> getMaps() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'maps',
      orderBy: 'lastModifiedOn DESC',
    );
    return Future.wait(
      maps.map((map) async {
        final List<Map<String, dynamic>> points = await db.query(
          'points',
          where: 'map_id = ?',
          whereArgs: [map['id']],
        );
        return MapData.fromMap({...map, 'points': points});
      }),
    );
  }

  Future<int> updateMap(MapData mapData) async {
    final db = await database;
    await db.update(
      'maps',
      {
        'name': mapData.name,
        'lastModifiedOn': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [mapData.id],
    );

    await db.delete('points', where: 'map_id = ?', whereArgs: [mapData.id]);
    for (final point in mapData.points) {
      await db.insert('points', {
        'map_id': mapData.id,
        'latitude': point.latitude,
        'longitude': point.longitude,
        'name': point.name,
      });
    }
    return mapData.id!;
  }

  Future<void> deleteMap(int id) async {
    final db = await database;
    await db.delete('points', where: 'map_id = ?', whereArgs: [id]);
    await db.delete('maps', where: 'id = ?', whereArgs: [id]);
  }
}
