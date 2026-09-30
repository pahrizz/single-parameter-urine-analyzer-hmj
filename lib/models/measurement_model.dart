class Measurement {
  const Measurement({
    required this.id,
    required this.timestamp,
    required this.parameterType,
    required this.value,
    required this.categoryStatus,
  });

  final String id;
  final DateTime timestamp;
  final String parameterType;
  final double value;
  final String categoryStatus;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'parameterType': parameterType,
      'value': value,
      'categoryStatus': categoryStatus,
    };
  }

  factory Measurement.fromMap(Map<String, Object?> map) {
    final rawValue = map['value'];
    final double parsedValue = switch (rawValue) {
      final num n => n.toDouble(),
      _ => throw ArgumentError('Invalid value in map: $rawValue'),
    };
    return Measurement(
      id: map['id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      parameterType: map['parameterType'] as String,
      value: parsedValue,
      categoryStatus: map['categoryStatus'] as String,
    );
  }
}
