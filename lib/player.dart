import 'dart:convert';

class Player {
  String name;
  int attack;
  int defense;
  int setting;
  int service;
  int height;

  Player({
    required this.name,
    required this.attack,
    required this.defense,
    required this.setting,
    required this.service,
    required this.height,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'attack': attack,
      'defense': defense,
      'setting': setting,
      'service': service,
      'height': height,
    };
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      name: json['name'],
      attack: json['attack'],
      defense: json['defense'],
      setting: json['setting'],
      service: json['service'],
      height: json['height'],
    );
  }

  // Pomocnicze funkcje do listy
  static String encode(List<Player> players) => json.encode(
        players.map<Map<String, dynamic>>((p) => p.toJson()).toList(),
      );

  static List<Player> decode(String players) =>
      (json.decode(players) as List<dynamic>)
          .map<Player>((item) => Player.fromJson(item))
          .toList();
}
