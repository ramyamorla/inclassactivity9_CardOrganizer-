import 'package:flutter/material.dart';
import 'db_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DBHelper.initDb();
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
            onTap: () {
              // Navigate to CardsScreen for the tapped folder
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CardsScreen(folder: folder),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class CardsScreen extends StatefulWidget {
  final Map<String, dynamic> folder;
  CardsScreen({required this.folder});

  @override
  _CardsScreenState createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  List<Map<String, dynamic>> cards = [];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    var data = await DBHelper.getCardsByFolder(widget.folder['id']);
    setState(() {
      cards = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.folder['name']} Cards')),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          var card = cards[index];
          return Card(
            child: Center(child: Text(card['name'])),
          );
        },
      ),
    );
  }
}