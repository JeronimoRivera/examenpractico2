class BaggageEvent {
  final String id;
  final String baggageId;
  final String type;
  final DateTime createdAt;

  BaggageEvent({
    required this.id,
    required this.baggageId,
    required this.type,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'baggageId': baggageId,
    'type': type,
    'createdAt': createdAt.toIso8601String(),
  };

  factory BaggageEvent.fromJson(Map<String, dynamic> json) => BaggageEvent(
    id: json['id'],
    baggageId: json['baggageId'],
    type: json['type'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}
