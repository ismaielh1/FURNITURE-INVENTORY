class LogEntry {
  final String id;
  final String productName;
  final String? productId;
  final String changeType;
  final String oldValue;
  final String newValue;
  final DateTime timestamp;

  LogEntry({
    required this.id,
    required this.productName,
    this.productId,
    required this.changeType,
    required this.oldValue,
    required this.newValue,
    required this.timestamp,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) =>
      LogEntry(
        id: json['id'],
        productName: json['product_name'] ?? 'منتج محذوف',
        productId: json['product_id'],
        changeType: json['change_type'] ?? 'غير معروف',
        oldValue: json['old_value'] ?? '-',
        newValue: json['new_value'] ?? '-',
        timestamp: DateTime.parse(json['created_at']),
      );
}
