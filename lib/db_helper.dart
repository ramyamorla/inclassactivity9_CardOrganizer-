import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  static Future<void> initDb() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'card_organizer.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create the Folders table
        await db.execute('''
          CREATE TABLE Folders(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        // Create the Cards table
        await db.execute('''
          CREATE TABLE Cards(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            suit TEXT,
            imageUrl TEXT,
            folderId INTEGER,
            FOREIGN KEY (folderId) REFERENCES Folders(id)
          )
        ''');
        // Prepopulate folders
        await db.insert('Folders', {'name': 'Hearts'});
        await db.insert('Folders', {'name': 'Spades'});
        await db.insert('Folders', {'name': 'Diamonds'});
        await db.insert('Folders', {'name': 'Clubs'});
        // Prepopulate one sample card (extend as needed)
        await db.insert('Cards', {
          'name': 'Ace',
          'suit': 'Hearts',
          'imageUrl': 'url_to_ace_hearts',
          'folderId': 1
        });
      },
    );
  }

  static Future<List<Map<String, dynamic>>> getFolders() async {
    return await _db!.query('Folders');
  }
}
