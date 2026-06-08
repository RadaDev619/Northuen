class DriverEarnings {
  DriverEarnings({
    required this.collected,
    required this.pending,
    required this.total,
    required this.completedJobs,
    required this.pendingJobs,
    required this.entries,
  });

  final num collected;
  final num pending;
  final num total;
  final int completedJobs;
  final int pendingJobs;
  final List<DriverEarningsEntry> entries;

  factory DriverEarnings.fromJson(Map<String, dynamic> json) => DriverEarnings(
    collected: json['collected'] ?? 0,
    pending: json['pending'] ?? 0,
    total: json['total'] ?? 0,
    completedJobs: json['completedJobs'] ?? 0,
    pendingJobs: json['pendingJobs'] ?? 0,
    entries: ((json['entries'] ?? []) as List)
        .map((entry) => DriverEarningsEntry.fromJson(entry))
        .toList(),
  );
}

class DriverEarningsEntry {
  DriverEarningsEntry({
    required this.id,
    required this.source,
    required this.title,
    required this.route,
    required this.amount,
    required this.status,
    required this.paymentStatus,
    required this.createdAt,
  });

  final String id;
  final String source;
  final String title;
  final String route;
  final num amount;
  final String status;
  final String paymentStatus;
  final DateTime createdAt;

  factory DriverEarningsEntry.fromJson(Map<String, dynamic> json) =>
      DriverEarningsEntry(
        id: json['id'],
        source: json['source'],
        title: json['title'],
        route: json['route'],
        amount: json['amount'] ?? 0,
        status: json['status'],
        paymentStatus: json['paymentStatus'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}
