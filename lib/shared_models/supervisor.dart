import 'json_helpers.dart';

class Supervisor {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String zoneId;

  Supervisor({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    required this.zoneId,
  });

  factory Supervisor.fromJson(Map<String, dynamic> json) {
    return Supervisor(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      zoneId: extractId(json['zoneId']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'zoneId': zoneId,
      };
}
