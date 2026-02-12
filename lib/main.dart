import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'player.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // this will be generated


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );
  runApp(MyApp());
}


class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final playersCollection = FirebaseFirestore.instance.collection('players');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Volleyball Players'),
        actions: [
          IconButton(
              icon: Icon(Icons.shuffle),
              onPressed: () async {
                final snapshot = await playersCollection.get();
                final selectedPlayers = snapshot.docs
                    .map((doc) => Player.fromMap(doc.data(), doc.id))
                    .where((p) => p.isSelected)
                    .toList();

                if (selectedPlayers.length < 10 || selectedPlayers.length > 18) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          'Select between 10 and 18 players to generate teams')));
                  return;
                }

                _generateTeams(selectedPlayers);
              }),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddPlayerDialog(),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: playersCollection.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final players = snapshot.data!.docs
              .map((doc) => Player.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();
          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 3),
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                return GestureDetector(
                  onTap: () {
                    playersCollection.doc(player.id).update({'isSelected': !player.isSelected});
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: player.isSelected ? Colors.green[200] : Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(player.name),
                        Row(
                          children: [
                            IconButton(
                                icon: Icon(Icons.edit, color: Colors.green),
                                onPressed: () => _showEditPlayerDialog(player)),
                            IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => playersCollection.doc(player.id).delete()),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showAddPlayerDialog() {
    final nameController = TextEditingController();
    final attackController = TextEditingController(text: "5");
    final defenseController = TextEditingController(text: "5");
    final settingController = TextEditingController(text: "5");
    final serviceController = TextEditingController(text: "5");
    final heightController = TextEditingController(text: "180");

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text('Add Player'),
              content: SingleChildScrollView(
                  child: Column(
                children: [
                  TextField(controller: nameController, decoration: InputDecoration(labelText: 'Name')),
                  TextField(controller: attackController, decoration: InputDecoration(labelText: 'Attack'), keyboardType: TextInputType.number),
                  TextField(controller: defenseController, decoration: InputDecoration(labelText: 'Defense'), keyboardType: TextInputType.number),
                  TextField(controller: settingController, decoration: InputDecoration(labelText: 'Setting'), keyboardType: TextInputType.number),
                  TextField(controller: serviceController, decoration: InputDecoration(labelText: 'Service'), keyboardType: TextInputType.number),
                  TextField(controller: heightController, decoration: InputDecoration(labelText: 'Height'), keyboardType: TextInputType.number),
                ],
              )),
              actions: [
                TextButton(
                    onPressed: () {
                      final newPlayer = Player(
                        name: nameController.text,
                        attack: int.tryParse(attackController.text) ?? 5,
                        defense: int.tryParse(defenseController.text) ?? 5,
                        setting: int.tryParse(settingController.text) ?? 5,
                        service: int.tryParse(serviceController.text) ?? 5,
                        height: int.tryParse(heightController.text) ?? 180,
                        isSelected: false,
                      );
                      playersCollection.add(newPlayer.toMap());
                      Navigator.pop(context);
                    },
                    child: Text('Add')),
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
              ],
            ));
  }

  void _showEditPlayerDialog(Player player) {
    final attackController = TextEditingController(text: player.attack.toString());
    final defenseController = TextEditingController(text: player.defense.toString());
    final settingController = TextEditingController(text: player.setting.toString());
    final serviceController = TextEditingController(text: player.service.toString());
    final heightController = TextEditingController(text: player.height.toString());

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text('Edit ${player.name}'),
              content: SingleChildScrollView(
                  child: Column(
                children: [
                  _buildStatField('Attack', attackController),
                  _buildStatField('Defense', defenseController),
                  _buildStatField('Setting', settingController),
                  _buildStatField('Service', serviceController),
                  _buildStatField('Height', heightController),
                ],
              )),
              actions: [
                TextButton(
                    onPressed: () {
                      playersCollection.doc(player.id).update({
                        'attack': int.tryParse(attackController.text) ?? player.attack,
                        'defense': int.tryParse(defenseController.text) ?? player.defense,
                        'setting': int.tryParse(settingController.text) ?? player.setting,
                        'service': int.tryParse(serviceController.text) ?? player.service,
                        'height': int.tryParse(heightController.text) ?? player.height,
                      });
                      Navigator.pop(context);
                    },
                    child: Text('Save')),
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
              ],
            ));
  }

  Widget _buildStatField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  void _generateTeams(List<Player> selected) {
    selected.shuffle();
    List<List<Player>> teams = [];

    switch (selected.length) {
      case 10:
        teams = [selected.sublist(0, 5), selected.sublist(5)];
        break;
      case 11:
        teams = [selected.sublist(0, 6), selected.sublist(6)];
        break;
      case 12:
        teams = [selected.sublist(0, 6), selected.sublist(6)];
        break;
      case 13:
        teams = [selected.sublist(0, 7), selected.sublist(7)];
        break;
      case 14:
        teams = [selected.sublist(0, 7), selected.sublist(7)];
        break;
      case 15:
        teams = [selected.sublist(0, 5), selected.sublist(5, 10), selected.sublist(10)];
        break;
      case 16:
        teams = [selected.sublist(0, 6), selected.sublist(6, 11), selected.sublist(11)];
        break;
      case 17:
        teams = [selected.sublist(0, 6), selected.sublist(6, 12), selected.sublist(12)];
        break;
      case 18:
        teams = [selected.sublist(0, 6), selected.sublist(6, 12), selected.sublist(12)];
        break;
    }

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text('Teams'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < teams.length; i++)
                    Text('Team ${i + 1}: ${teams[i].map((p) => p.name).join(', ')}')
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('OK')),
              ],
            ));
  }
}
