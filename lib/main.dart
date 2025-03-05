import 'dart:convert';
import 'dart:typed_data';

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
      theme: ThemeData(primarySwatch: Colors.blue),
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

  // Build a folder tile showing the folder name, a preview image (from its first card if available) and card count.
  Widget _buildFolderTile(Map<String, dynamic> folder) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DBHelper.getCardsByFolder(folder['id']),
      builder: (context, snapshot) {
        int cardCount = 0;
        Widget preview;
        if (snapshot.hasData) {
          var cards = snapshot.data!;
          cardCount = cards.length;
          if (cards.isNotEmpty && (cards.first['imageUrl'] ?? '').toString().isNotEmpty) {
            // For demonstration, we try decoding the first card's image URL if it's base64.
            try {
              Uint8List imageBytes = base64Decode(cards.first['imageUrl']);
              preview = Image.memory(imageBytes, fit: BoxFit.cover, width: 80, height: 80);
            } catch (e) {
              // If not base64, show a placeholder.
              preview = Container(
                width: 80,
                height: 80,
                color: Colors.grey[300],
                child: Icon(Icons.image),
              );
            }
          } else {
            preview = Container(
              width: 80,
              height: 80,
              color: Colors.grey[300],
              child: Icon(Icons.image, color: Colors.grey[700]),
            );
          }
        } else {
          preview = Container(
            width: 80,
            height: 80,
            color: Colors.grey[300],
            child: Icon(Icons.image),
          );
        }
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            leading: preview,
            title: Text(folder['name'], style: TextStyle(fontSize: 18)),
            subtitle: Text('Cards: $cardCount'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CardsScreen(folder: folder)),
              );
            },
            onLongPress: () => _showFolderOptions(folder),
          ),
        );
      },
    );
  }

  // Options for renaming or deleting a folder.
  void _showFolderOptions(Map<String, dynamic> folder) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('Rename Folder'),
            onTap: () {
              Navigator.pop(context);
              _renameFolder(folder);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete),
            title: Text('Delete Folder'),
            onTap: () {
              Navigator.pop(context);
              _deleteFolder(folder);
            },
          ),
        ],
      ),
    );
  }

  void _renameFolder(Map<String, dynamic> folder) {
    TextEditingController controller = TextEditingController(text: folder['name']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rename Folder'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: 'New Folder Name'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              folder['name'] = controller.text;
              await DBHelper.updateFolder(folder);
              Navigator.pop(context);
              _loadFolders();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteFolder(Map<String, dynamic> folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Folder'),
        content: Text('Are you sure you want to delete folder "${folder['name']}" and all its cards?'),
        actions: [
          TextButton(
            onPressed: () async {
              await DBHelper.deleteFolder(folder['id']);
              Navigator.pop(context);
              _loadFolders();
            },
            child: Text('Delete'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // "Add Card" from the home screen: let user pick a folder.
  void _addCardFromHome() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        shrinkWrap: true,
        itemCount: folders.length,
        itemBuilder: (context, index) {
          var folder = folders[index];
          return ListTile(
            title: Text(folder['name']),
            onTap: () async {
              var cardsInFolder = await DBHelper.getCardsByFolder(folder['id']);
              if (cardsInFolder.length >= 6) {
                Navigator.pop(context);
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
                Navigator.pop(context);
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Folders')),
      body: RefreshIndicator(
        onRefresh: _loadFolders,
        child: ListView(
          children: folders.map((folder) => _buildFolderTile(folder)).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        tooltip: "Add Card",
        onPressed: _addCardFromHome,
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

  // Build a card tile that shows its name and decoded image (if available).
  Widget _buildCardTile(Map<String, dynamic> card) {
    Widget imageWidget;
    String imageData = card['imageUrl'] ?? '';
    if (imageData.isNotEmpty) {
      try {
        Uint8List imageBytes = base64Decode(imageData);
        imageWidget = Image.memory(imageBytes, fit: BoxFit.cover);
      } catch (e) {
        imageWidget = Container(
          color: Colors.grey[300],
          child: Icon(Icons.image, color: Colors.grey[700]),
        );
      }
    } else {
      imageWidget = Container(
        color: Colors.grey[300],
        child: Icon(Icons.image, color: Colors.grey[700]),
      );
    }
    return Card(
      child: Column(
        children: [
          Expanded(child: imageWidget),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(card['name'], style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.folder['name']} Cards')),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
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
      body: RefreshIndicator(
        onRefresh: _loadCards,
        child: GridView.builder(
          padding: EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            var card = cards[index];
            return GestureDetector(
              onLongPress: () {
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
              child: _buildCardTile(card),
            );
          },
        ),
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
    _imageUrlController = TextEditingController(text: widget.card?['imageUrl'] ?? '');
  }

  // Simulate picking an image from assets and converting it to base64.
  Future<void> _pickImage() async {
    // Replace with your actual asset path and declare the asset in pubspec.yaml.
    String base64Image = await DBHelper.imageToBase64('assets/sample_image.png');
    setState(() {
      _imageUrlController.text = base64Image;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.card == null ? 'Add Card' : 'Edit Card')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Card Name'),
                validator: (value) => value!.isEmpty ? 'Enter card name' : null,
              ),
              TextFormField(
                controller: _suitController,
                decoration: InputDecoration(labelText: 'Suit'),
                validator: (value) => value!.isEmpty ? 'Enter suit' : null,
              ),
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(labelText: 'Image (Base64)'),
                maxLines: 3,
                validator: (value) =>
                    value!.isEmpty ? 'Enter image data or pick an image' : null,
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                icon: Icon(Icons.image),
                label: Text('Pick Image from Assets'),
                onPressed: _pickImage,
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