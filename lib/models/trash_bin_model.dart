class TrashBinData {
  final int metal;
  final int other;
  final int paper;
  final int plastic;

  TrashBinData({
    required this.metal,
    required this.other,
    required this.paper,
    required this.plastic,
  });

  factory TrashBinData.fromMap(Map<String, dynamic> map) {
    return TrashBinData(
      metal: (map['metal'] as num?)?.toInt() ?? 0,
      other: (map['other'] as num?)?.toInt() ?? 0,
      paper: (map['paper'] as num?)?.toInt() ?? 0,
      plastic: (map['plastic'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'metal': metal, 'other': other, 'paper': paper, 'plastic': plastic};
  }

  int get totalItems => metal + other + paper + plastic;

  double getPercentage(TrashType type) {
    if (totalItems == 0) return 0.0;
    final value = getValue(type);
    return (value / totalItems) * 100;
  }

  int getValue(TrashType type) {
    switch (type) {
      case TrashType.metal:
        return metal;
      case TrashType.other:
        return other;
      case TrashType.paper:
        return paper;
      case TrashType.plastic:
        return plastic;
    }
  }
}

enum TrashType { metal, other, paper, plastic }

extension TrashTypeExtension on TrashType {
  String get displayName {
    switch (this) {
      case TrashType.metal:
        return 'Metal';
      case TrashType.other:
        return 'Other';
      case TrashType.paper:
        return 'Paper';
      case TrashType.plastic:
        return 'Plastic';
    }
  }

  String get icon {
    switch (this) {
      case TrashType.metal:
        return '🔧';
      case TrashType.other:
        return '🗑️';
      case TrashType.paper:
        return '📄';
      case TrashType.plastic:
        return '🥤';
    }
  }
}
