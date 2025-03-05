import 'package:flutter/material.dart';
import 'db_helper.dart'; // Database helper file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DBHelper.initDb(); // Initialize the database
  runApp(CardOrganizerApp());
}

class CardOrganizerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Organizer App',
      home: FoldersScreen(),
    );
  }
}

class FoldersScreen extends StatefulWidget {
  @override
  _FoldersScreenState createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  List<Map<String, dynamic>> folders = [];

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    var data = await DBHelper.getFolders();
    setState(() {
      folders = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Folders')),
      body: ListView.builder(
        itemCount: folders.length,
        itemBuilder: (context, index) {
          var folder = folders[index];
          return ListTile(
            title: Text(folder['name']),
          );
        },
      ),
    );
  }
}
