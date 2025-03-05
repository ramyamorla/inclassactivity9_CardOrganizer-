import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
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

        // Prepopulate folders (four suits)
        List<String> suits = ['Hearts', 'Spades', 'Diamonds', 'Clubs'];
        for (String suit in suits) {
          await db.insert('Folders', {'name': suit});
        }

        // Prepopulate Cards table with a full deck (1 to 13 per suit)
        // Assuming that folders get auto-assigned IDs in order 1-4.
        for (int folderId = 1; folderId <= suits.length; folderId++) {
          String suit = suits[folderId - 1];
          for (int rank = 1; rank <= 13; rank++) {
            String cardName;
            if (rank == 1) {
              cardName = 'Ace';
            } else if (rank == 11) {
              cardName = 'Jack';
            } else if (rank == 12) {
              cardName = 'Queen';
            } else if (rank == 13) {
              cardName = 'King';
            } else {
              cardName = rank.toString();
            }
            // For demonstration, we use an asset path based on suit and card name.
            // You can change this to any URL or base64 string.
            String imageUrl = "assets/${suit.toLowerCase()}/${cardName.toLowerCase()}.png";
            await db.insert('Cards', {
              'name': cardName,
              'suit': suit,
              'imageUrl': imageUrl,
              'folderId': folderId
            });
          }
        }
      },
    );
  }

  // Retrieve all folders.
  static Future<List<Map<String, dynamic>>> getFolders() async {
    return await _db!.query('Folders');
  }

  // Retrieve cards for a given folder.
  static Future<List<Map<String, dynamic>>> getCardsByFolder(int folderId) async {
    return await _db!.query('Cards', where: 'folderId = ?', whereArgs: [folderId]);
  }

  // Insert a new card record.
  static Future<int> insertCard(Map<String, dynamic> cardData) async {
    return await _db!.insert('Cards', cardData);
  }

  // Update an existing card record.
  static Future<int> updateCard(Map<String, dynamic> cardData) async {
    return await _db!.update('Cards', cardData,
        where: 'id = ?', whereArgs: [cardData['id']]);
  }

  // Delete a card record.
  static Future<int> deleteCard(int id) async {
    return await _db!.delete('Cards', where: 'id = ?', whereArgs: [id]);
  }

  // Update a folder's name.
  static Future<int> updateFolder(Map<String, dynamic> folderData) async {
    return await _db!.update('Folders', folderData,
        where: 'id = ?', whereArgs: [folderData['id']]);
  }

  // Delete a folder and all its cards.
  static Future<int> deleteFolder(int folderId) async {
    await _db!.delete('Cards', where: 'folderId = ?', whereArgs: [folderId]);
    return await _db!.delete('Folders', where: 'id = ?', whereArgs: [folderId]);
  }

  // Convert an asset image to a base64 string.
  // Adjust the assetPath and ensure the asset is declared in pubspec.yaml.
  static Future<String> imageToBase64(String assetPath) async {
    ByteData bytes = await rootBundle.load(assetPath);
    Uint8List list = bytes.buffer.asUint8List();
    return base64Encode(list);
  }
}