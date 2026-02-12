import 'dart:math';

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


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Volleyball Players',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE76F51)),
        scaffoldBackgroundColor: const Color(0xFFF3F5F7),
        useMaterial3: true,
      ),
      home: VolleyballHomePage(),
    );
  }
}

class VolleyballHomePage extends StatefulWidget {
  @override
  _VolleyballHomePageState createState() => _VolleyballHomePageState();
}

class _VolleyballHomePageState extends State<VolleyballHomePage> {
  final playersCollection = FirebaseFirestore.instance.collection('players');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 86,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Volleyball Players',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              'Select players and generate balanced teams',
              style: TextStyle(
                color: Color(0xFFE3F2FD),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE76F51), Color(0xFFF4A261)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.shuffle),
              onPressed: _generateTeamsFromSelectedPlayers),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: FloatingActionButton.small(
        onPressed: _showAddPlayerDialog,
        backgroundColor: const Color(0xFF2A9D8F),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: playersCollection.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final players = snapshot.data!.docs
              .map((doc) => Player.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF8FAFC), Color(0xFFEAF4F4)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _generateTeamsFromSelectedPlayers,
                      icon: const Icon(Icons.casino),
                      label: const Text('Wyswietl wylosowane druzyny'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF264653),
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final crossAxisCount = width > 1200
                            ? 4
                            : width > 780
                                ? 3
                                : 2;

                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.45,
                          ),
                          itemCount: players.length,
                          itemBuilder: (context, index) {
                            final player = players[index];
                            return _buildPlayerTile(player);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _generateTeamsFromSelectedPlayers() async {
    try {
      final snapshot = await playersCollection.get();
      final selectedPlayers = snapshot.docs
          .map((doc) => Player.fromMap(doc.data(), doc.id))
          .where((p) => p.isSelected)
          .toList();

      if (!mounted) {
        return;
      }

      if (selectedPlayers.length < 10 || selectedPlayers.length > 18) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Select between 10 and 18 players to generate teams')),
        );
        return;
      }

      _generateTeams(selectedPlayers);
    } on FirebaseException catch (e) {
      _showErrorSnackBar('Firestore error: ${e.message ?? e.code}');
    } catch (e) {
      _showErrorSnackBar('Error loading players: $e');
    }
  }

  void _showAddPlayerDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final attackController = TextEditingController(text: '5');
    final defenseController = TextEditingController(text: '5');
    final settingController = TextEditingController(text: '5');
    final serviceController = TextEditingController(text: '5');
    final heightController = TextEditingController(text: '180');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Player'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                _buildNumberFormField('Attack', attackController),
                _buildNumberFormField('Defense', defenseController),
                _buildNumberFormField('Setting', settingController),
                _buildNumberFormField('Service', serviceController),
                _buildNumberFormField('Height', heightController),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              final newPlayer = Player(
                name: nameController.text.trim(),
                attack: int.parse(attackController.text),
                defense: int.parse(defenseController.text),
                setting: int.parse(settingController.text),
                service: int.parse(serviceController.text),
                height: int.parse(heightController.text),
                isSelected: false,
              );
              try {
                await playersCollection.add(newPlayer.toMap());
                if (!mounted) {
                  return;
                }
                Navigator.pop(context);
              } on FirebaseException catch (e) {
                _showErrorSnackBar('Save failed: ${e.message ?? e.code}');
              } catch (e) {
                _showErrorSnackBar('Save failed: $e');
              }
            },
            child: Text('Add'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ],
      ),
    );
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
                    onPressed: () async {
                      try {
                        await playersCollection.doc(player.id).update({
                          'attack': int.tryParse(attackController.text) ?? player.attack,
                          'defense': int.tryParse(defenseController.text) ?? player.defense,
                          'setting': int.tryParse(settingController.text) ?? player.setting,
                          'service': int.tryParse(serviceController.text) ?? player.service,
                          'height': int.tryParse(heightController.text) ?? player.height,
                        });
                        if (!mounted) {
                          return;
                        }
                        Navigator.pop(context);
                      } on FirebaseException catch (e) {
                        _showErrorSnackBar('Update failed: ${e.message ?? e.code}');
                      } catch (e) {
                        _showErrorSnackBar('Update failed: $e');
                      }
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

  Widget _buildNumberFormField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          final parsed = int.tryParse(value ?? '');
          if (parsed == null) {
            return 'Enter a number';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPlayerTile(Player player) {
    final selected = player.isSelected;
    final baseGradient = selected
        ? const [Color(0xFFE4F7F3), Color(0xFFD7F1EB)]
        : const [Color(0xFFFFFFFF), Color(0xFFF7FAFD)];

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        try {
          await playersCollection.doc(player.id).update({'isSelected': !player.isSelected});
        } on FirebaseException catch (e) {
          _showErrorSnackBar('Selection update failed: ${e.message ?? e.code}');
        } catch (e) {
          _showErrorSnackBar('Selection update failed: $e');
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: baseGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF4FA89A) : const Color(0xFF9FB2C8),
            width: selected ? 2.6 : 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? const Color(0x1A4FA89A)
                  : const Color(0x143A4A5A),
              blurRadius: selected ? 14 : 8,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF1F2937),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.edit,
                    size: 20,
                    color: const Color(0xFF2A9D8F),
                  ),
                  onPressed: () => _showEditPlayerDialog(player),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.delete,
                    size: 20,
                    color: const Color(0xFFE63946),
                  ),
                  onPressed: () async {
                    try {
                      await playersCollection.doc(player.id).delete();
                    } on FirebaseException catch (e) {
                      _showErrorSnackBar('Delete failed: ${e.message ?? e.code}');
                    } catch (e) {
                      _showErrorSnackBar('Delete failed: $e');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _generateTeams(List<Player> selected) {
    final random = Random();
    final teamSizes = _teamSizesForPlayerCount(selected.length);
    final teams = List.generate(teamSizes.length, (_) => <Player>[]);
    final teamStrengths = List.generate(teamSizes.length, (_) => 0.0);

    final sortedPlayers = [...selected]..shuffle(random);
    sortedPlayers.sort((a, b) {
      final aScore = _playerStrength(a) + random.nextDouble() * 0.6;
      final bScore = _playerStrength(b) + random.nextDouble() * 0.6;
      return bScore.compareTo(aScore);
    });

    for (final player in sortedPlayers) {
      final candidates = <MapEntry<int, double>>[];

      for (int i = 0; i < teams.length; i++) {
        final isTeamFull = teams[i].length >= teamSizes[i];
        if (isTeamFull) {
          continue;
        }

        final normalizedStrength = teamStrengths[i] / teamSizes[i];
        candidates.add(MapEntry(i, normalizedStrength));
      }

      if (candidates.isEmpty) {
        continue;
      }

      candidates.sort((a, b) => a.value.compareTo(b.value));
      final minStrength = candidates.first.value;
      final topCandidates =
          candidates.where((c) => c.value <= minStrength + 0.35).toList();
      final chosen = topCandidates[random.nextInt(topCandidates.length)];
      final bestTeamIndex = chosen.key;

      teams[bestTeamIndex].add(player);
      teamStrengths[bestTeamIndex] += _playerStrength(player);
    }

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text('Teams'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < teams.length; i++)
                      Text(
                        'Team ${i + 1} (${teamStrengths[i].toStringAsFixed(1)}): '
                        '${teams[i].map((p) => p.name).join(', ')}',
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('OK')),
              ],
            ));
  }

  List<int> _teamSizesForPlayerCount(int count) {
    switch (count) {
      case 10:
        return [5, 5];
      case 11:
        return [6, 5];
      case 12:
        return [6, 6];
      case 13:
        return [7, 6];
      case 14:
        return [7, 7];
      case 15:
        return [5, 5, 5];
      case 16:
        return [6, 5, 5];
      case 17:
        return [6, 6, 5];
      case 18:
        return [6, 6, 6];
      default:
        return [];
    }
  }

  double _playerStrength(Player player) {
    return player.attack * 1.2 +
        player.defense * 1.1 +
        player.setting * 1.0 +
        player.service * 0.9 +
        player.height * 0.05;
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
