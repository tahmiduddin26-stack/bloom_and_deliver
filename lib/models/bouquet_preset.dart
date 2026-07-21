/// A named bouquet recipe the player can save and reload.
class BouquetPreset {
  final String id; // unique identifier (timestamp-based)
  final String name;
  final List<String> flowerIds; // ordered list of flower IDs

  const BouquetPreset({
    required this.id,
    required this.name,
    required this.flowerIds,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'flowerIds': flowerIds,
      };

  factory BouquetPreset.fromJson(Map<String, dynamic> j) => BouquetPreset(
        id: j['id'] as String,
        name: j['name'] as String,
        flowerIds: List<String>.from(j['flowerIds'] as List),
      );

  BouquetPreset copyWith({String? name, List<String>? flowerIds}) =>
      BouquetPreset(
        id: id,
        name: name ?? this.name,
        flowerIds: flowerIds ?? this.flowerIds,
      );
}
