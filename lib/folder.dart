import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'cards_screen.dart';

class FolderScreen extends StatefulWidget {
  const FolderScreen({super.key});

  @override
  _FolderScreenState createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  late DatabaseHelper dbHelper;
  late Future<List<Map<String, dynamic>>> foldersWithCardInfo;

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper();
    foldersWithCardInfo = _fetchFoldersWithCardInfo();
  }

  Future<List<Map<String, dynamic>>> _fetchFoldersWithCardInfo() async {
    List<Map<String, dynamic>> folderList = [];
    // Fetch all folders from the database
    List<Map<String, dynamic>> folders = await dbHelper.getAllFolders();

    for (var folder in folders) {
      int folderId = folder['id'];
      int cardCount = await dbHelper.getCardCount(folderId);
      String? previewImage = await dbHelper.getFirstCardImage(folderId);
      folderList.add({
        'folderName': folder['name'],
        'folderId': folderId,
        'cardCount': cardCount,
        'previewImage': previewImage,
      });
    }
    return folderList;
  }

  Future<void> _addFolder() async {
    TextEditingController folderNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Folder'),
          content: TextField(
            controller: folderNameController,
            decoration: InputDecoration(hintText: 'Folder Name'),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () async {
                String folderName = folderNameController.text;
                if (folderName.isNotEmpty) {
                  await dbHelper.addFolder(folderName);
                  setState(() {
                    foldersWithCardInfo = _fetchFoldersWithCardInfo();
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _renameFolder(int folderId) async {
    TextEditingController folderNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Rename Folder'),
          content: TextField(
            controller: folderNameController,
            decoration: InputDecoration(hintText: 'New Folder Name'),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Rename'),
              onPressed: () async {
                String newFolderName = folderNameController.text;
                if (newFolderName.isNotEmpty) {
                  await dbHelper.updateFolder(folderId, newFolderName);
                  setState(() {
                    foldersWithCardInfo = _fetchFoldersWithCardInfo();
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteFolder(int folderId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Folder'),
          content: Text(
              'Are you sure you want to delete this folder and all its cards?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
                await dbHelper.deleteFolder(folderId);
                setState(() {
                  foldersWithCardInfo = _fetchFoldersWithCardInfo();
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Card Organizer'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addFolder,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner with soft background and app name
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.lightBlue[200],
            ),
            child: Text(
              'Card Organizer',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: foldersWithCardInfo,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading folders'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No folders available.'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    var folder = snapshot.data![index];
                    return ListTile(
                      leading: folder['previewImage'] != null
                          ? Image.network(folder['previewImage']!, height: 50)
                          : Icon(Icons.folder,
                              size: 50, color: Colors.lightBlue[300]),
                      title: Text(
                        folder['folderName'],
                        style: TextStyle(color: Colors.black87),
                      ),
                      subtitle: Text(
                        '${folder['cardCount']} cards',
                        style: TextStyle(color: Colors.black54),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit,
                                color: Colors.lightBlue[300]),
                            onPressed: () => _renameFolder(folder['folderId']),
                          ),
                          IconButton(
                            icon:
                                Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _deleteFolder(folder['folderId']),
                          ),
                        ],
                      ),
                      onTap: () {
                        // Navigate to the card screen when a folder is tapped
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CardScreen(
                              folderId: folder['folderId'],
                              folderName: folder['folderName'],
                            ),
                          ),
                        ).then((value) {
                          if (value == true) {
                            setState(() {
                              foldersWithCardInfo = _fetchFoldersWithCardInfo();
                            });
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
