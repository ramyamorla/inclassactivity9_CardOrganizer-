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

  // Called when the "Add Card" button on home screen is pressed.
  void _addCardFromHome() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: folders.length,
          itemBuilder: (context, index) {
            var folder = folders[index];
            return ListTile(
              title: Text(folder['name']),
              onTap: () async {
                // Check the card count in the selected folder.
                var cardsInFolder = await DBHelper.getCardsByFolder(folder['id']);
                if (cardsInFolder.length >= 6) {
                  Navigator.pop(context); // dismiss the folder selection
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text("Error"),
                      content: Text("This folder can only hold 6 cards."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("OK"),
                        ),
                      ],
                    ),
                  );
                } else {
                  Navigator.pop(context); // dismiss the folder selection
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditCardScreen(folderId: folder['id']),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
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
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: _addCardFromHome,
        tooltip: "Add Card",
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
    // Show warning if folder has fewer than 3 cards.
    if (cards.length < 3) {
      Future.delayed(Duration.zero, () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Warning: This folder needs at least 3 cards.")),
        );
      });
    }
  }

  void _deleteCard(int cardId) async {
    await DBHelper.deleteCard(cardId);
    _loadCards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.folder['name']} Cards')),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          // Enforce maximum limit of 6 cards per folder.
          if (cards.length >= 6) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text("Error"),
                content: Text("This folder can only hold 6 cards."),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("OK"),
                  ),
                ],
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditCardScreen(folderId: widget.folder['id']),
              ),
            ).then((value) {
              _loadCards();
            });
          }
        },
      ),
      body: GridView.builder(
        gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          var card = cards[index];
          return GestureDetector(
            onLongPress: () {
              // Options to edit or delete the card.
              showModalBottomSheet(
                context: context,
                builder: (context) => Wrap(
                  children: [
                    ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditCardScreen(
                                card: card, folderId: widget.folder['id']),
                          ),
                        ).then((value) {
                          _loadCards();
                        });
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.delete),
                      title: Text('Delete'),
                      onTap: () {
                        Navigator.pop(context);
                        _deleteCard(card['id']);
                      },
                    ),
                  ],
                ),
              );
            },
            child: Card(
              child: Center(child: Text(card['name'])),
            ),
          );
        },
      ),
    );
  }
}

class EditCardScreen extends StatefulWidget {
  final Map<String, dynamic>? card;
  final int folderId;
  EditCardScreen({this.card, required this.folderId});

  @override
  _EditCardScreenState createState() => _EditCardScreenState();
}

class _EditCardScreenState extends State<EditCardScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _suitController;
  late TextEditingController _imageUrlController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.card?['name'] ?? '');
    _suitController = TextEditingController(text: widget.card?['suit'] ?? '');
    _imageUrlController =
        TextEditingController(text: widget.card?['imageUrl'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(widget.card == null ? 'Add Card' : 'Edit Card')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Card Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Enter card name' : null,
              ),
              TextFormField(
                controller: _suitController,
                decoration: InputDecoration(labelText: 'Suit'),
                validator: (value) =>
                    value!.isEmpty ? 'Enter suit' : null,
              ),
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(labelText: 'Image URL'),
                validator: (value) =>
                    value!.isEmpty ? 'Enter image URL' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text('Save'),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    Map<String, dynamic> cardData = {
                      'name': _nameController.text,
                      'suit': _suitController.text,
                      'imageUrl': _imageUrlController.text,
                      'folderId': widget.folderId,
                    };
                    if (widget.card == null) {
                      await DBHelper.insertCard(cardData);
                    } else {
                      cardData['id'] = widget.card!['id'];
                      await DBHelper.updateCard(cardData);
                    }
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
