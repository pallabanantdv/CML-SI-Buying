import 'purchase_invoice_summary.dart';

class RevenueSummary {
  RevenueSummary.fromJson(Map<String, dynamic> json)
    : currency = '${json['currency'] ?? ''}',
      fromDate = '${json['from_date'] ?? ''}',
      toDate = '${json['to_date'] ?? ''}',
      total = summaryNumber(json['total_revenue']),
      quarters = summaryRows((json['revenue_trends'] as Map?)?['quarterly'])
          .map((row) => ('${row['label'] ?? ''}', summaryNumber(row['amount'])))
          .toList();

  final String currency, fromDate, toDate;
  final double total;
  final List<(String, double)> quarters;
}
