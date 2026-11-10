double summaryNumber(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

List<Map<String, dynamic>> summaryRows(dynamic value) => value is List
    ? value
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList()
    : [];

class PurchaseTrend {
  PurchaseTrend.fromJson(Map<String, dynamic> json)
    : id = '${json['period_start'] ?? json['period'] ?? json['label'] ?? ''}',
      label = '${json['label'] ?? ''}',
      count = summaryNumber(json['count']),
      dailyCounts = summaryRows(json['daily_counts'])
          .map(
            (row) => (
              '${row['short_day'] ?? row['date'] ?? ''}',
              summaryNumber(row['count']),
            ),
          )
          .toList();

  final String id;
  final String label;
  final double count;
  final List<(String, double)> dailyCounts;
}

class PurchaseInvoiceSummary {
  PurchaseInvoiceSummary.fromJson(Map<String, dynamic> json)
    : fromDate = '${json['from_date'] ?? ''}',
      toDate = '${json['to_date'] ?? ''}',
      currency = '${json['currency'] ?? ''}',
      currencyWarning = json['currency_warning']?.toString(),
      totalValue = summaryNumber(json['total_purchase_value']),
      transactions = summaryNumber(json['total_transactions']).toInt(),
      paidCount = summaryNumber((json['fully_paid'] as Map?)?['count']).toInt(),
      unpaidCount = summaryNumber((json['fully_unpaid'] as Map?)?['count'])
          .toInt(),
      partlyPaidCount = summaryNumber((json['partly_paid'] as Map?)?['count'])
          .toInt(),
      items = summaryRows(json['items']),
      weekly = _trends(json, 'weekly'),
      monthly = _trends(json, 'monthly'),
      yearly = _trends(json, 'yearly');

  final String fromDate, toDate, currency;
  final String? currencyWarning;
  final double totalValue;
  final int transactions, paidCount, unpaidCount, partlyPaidCount;
  final List<Map<String, dynamic>> items;
  final List<PurchaseTrend> weekly, monthly, yearly;

  static List<PurchaseTrend> _trends(Map<String, dynamic> json, String key) =>
      summaryRows((json['trends'] as Map?)?[key])
          .map(PurchaseTrend.fromJson)
          .toList();
}
