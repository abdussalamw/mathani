class Reciter {
  final String id;
  final String name;
  final String style;
  final String bitrate;

  Reciter({
    required this.id,
    required this.name,
    required this.style,
    required this.bitrate,
  });

  factory Reciter.fromJson(Map<String, dynamic> json) {
    return Reciter(
      id: json['id'] as String,
      name: json['name'] as String,
      style: json['style'] as String,
      bitrate: json['bitrate'] as String,
    );
  }
}
