class Zone {
  final String id;
  final String name;
  final String code;
  final int totalStudents;
  final int visitedStudents;

  Zone({
    required this.id,
    required this.name,
    required this.code,
    required this.totalStudents,
    required this.visitedStudents,
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      totalStudents: json['totalStudents'] ?? 0,
      visitedStudents: json['visitedStudents'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'totalStudents': totalStudents,
        'visitedStudents': visitedStudents,
      };
}
