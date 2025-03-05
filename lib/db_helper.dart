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
        // Create Folders table
        await db.execute('''
          CREATE TABLE Folders(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        // Create Cards table
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
        // Prepopulate folders (4 suits)
        await db.insert('Folders', {'name': 'Hearts'});
        await db.insert('Folders', {'name': 'Spades'});
        await db.insert('Folders', {'name': 'Diamonds'});
        await db.insert('Folders', {'name': 'Clubs'});
        // Prepopulate a sample card for demonstration (extend as needed)
        await db.insert('Cards', {
          'name': 'Ace',
          'suit': 'Hearts',
          'imageUrl': 'url_to_ace_hearts',
          'folderId': 1
        });
      },
    );
  }

  // Retrieve all folders
  static Future<List<Map<String, dynamic>>> getFolders() async {
    return await _db!.query('Folders');
  }

  // Retrieve cards for a given folder
  static Future<List<Map<String, dynamic>>> getCardsByFolder(int folderId) async {
    return await _db!.query('Cards', where: 'folderId = ?', whereArgs: [folderId]);
  }

  // Insert a new card record
  static Future<int> insertCard(Map<String, dynamic> cardData) async {
    return await _db!.insert('Cards', cardData);
  }

  // Update an existing card record
  static Future<int> updateCard(Map<String, dynamic> cardData) async {
    return await _db!.update('Cards', cardData,
        where: 'id = ?', whereArgs: [cardData['id']]);
  }

  // Delete a card record
  static Future<int> deleteCard(int id) async {
    return await _db!.delete('Cards', where: 'id = ?', whereArgs: [id]);
  }
}
