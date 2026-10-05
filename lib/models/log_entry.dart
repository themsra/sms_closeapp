class LogEntry {
  final String sender;
  final String message;
  final DateTime time;

  LogEntry({
    required this.sender,
    required this.message,
    required this.time,
  });

  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'message': message,
      'time': time.toIso8601String(),
    };
  }

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      sender: json['sender'] ?? '',
      message: json['message'] ?? '',
      time: DateTime.tryParse(json['time'] ?? '') ?? DateTime.now(),
    );
  }
}