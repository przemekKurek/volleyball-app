import 'package:flutter/material.dart';
import 'player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(MaterialApp(
      title: 'Volleyball Players',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyApp(),
    ));

// MODEL DANYCH ZAWODNIKA

// GŁÓWNA APLIKACJA
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // lista zawodników
  List<Player> players = [];

  final _nameController = TextEditingController();

  // dodawanie zawodnika
  void addPlayer(String name) {
    if (name.isEmpty) return;
    setState(() {
      players.add(Player(
          name: name,
          attack: 5,
          defense: 5,
          setting: 5,
          service: 5,
          height: 180));
    });
    _nameController.clear();
    savePlayers();
  }

  // usuwanie zawodnika
  void removePlayer(Player player) {
    setState(() {
      players.remove(player);
    });
    savePlayers();
  }

  // edycja zawodnika
  void editPlayer(Player player) {
    final _attackController = TextEditingController(text: player.attack.toString());
    final _defenseController = TextEditingController(text: player.defense.toString());
    final _settingController = TextEditingController(text: player.setting.toString());
    final _serviceController = TextEditingController(text: player.service.toString());
    final _heightController = TextEditingController(text: player.height.toString());

    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: Text('Edit ${player.name}'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  buildStatField('Attack', _attackController),
                  buildStatField('Defense', _defenseController),
                  buildStatField('Setting', _settingController),
                  buildStatField('Service', _serviceController),
                  buildStatField('Height', _heightController),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    setState(() {
                      player.attack = int.tryParse(_attackController.text) ?? player.attack;
                      player.defense = int.tryParse(_defenseController.text) ?? player.defense;
                      player.setting = int.tryParse(_settingController.text) ?? player.setting;
                      player.service = int.tryParse(_serviceController.text) ?? player.service;
                      player.height = int.tryParse(_heightController.text) ?? player.height;
                    });
                    Navigator.of(context).pop();
                    savePlayers();
                  },
                  child: Text('Save')),
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'))
            ],
          );
        });
  }

  // pomocnicza funkcja do tworzenia TextField dla statystyk
  Widget buildStatField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Volleyball Players')),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // formularz dodawania zawodnika
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'New player name'),
                ),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                  onPressed: () => addPlayer(_nameController.text),
                  child: Text('Add')),
            ],
          ),
          SizedBox(height: 20),
          // lista zawodników w 3 kolumnach
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 3 kolumny
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 3,
              ),
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                return Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(player.name),
                      Row(
                        children: [
                          // Ikona ołówka → edycja
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.green),
                            onPressed: () => editPlayer(player),
                            tooltip: 'Edit player',
                          ),
                          // Ikona kosza → usuwanie
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => removePlayer(player),
                            tooltip: 'Delete player',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

@override
void initState() {
  super.initState();
  loadPlayers();
}

void loadPlayers() async {
  final prefs = await SharedPreferences.getInstance();
  final String? playersString = prefs.getString('players');
  if (playersString != null) {
    setState(() {
      players = Player.decode(playersString);
    });
  }
}

void savePlayers() async {
  final prefs = await SharedPreferences.getInstance();
  final String encodedData = Player.encode(players);
  await prefs.setString('players', encodedData);
}





}