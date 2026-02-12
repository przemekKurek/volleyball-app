class Player {
  String? id;
  String name;
  int attack, defense, setting, service, height;
  bool isSelected;

  Player({
    this.id,
    required this.name,
    required this.attack,
    required this.defense,
    required this.setting,
    required this.service,
    required this.height,
    this.isSelected = false,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'attack': attack,
        'defense': defense,
        'setting': setting,
        'service': service,
        'height': height,
        'isSelected': isSelected,
      };

  factory Player.fromMap(Map<String, dynamic> map, String id) => Player(
        id: id,
        name: map['name'],
        attack: map['attack'],
        defense: map['defense'],
        setting: map['setting'],
        service: map['service'],
        height: map['height'],
        isSelected: map['isSelected'] ?? false,
      );
}