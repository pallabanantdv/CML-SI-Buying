import '../../../core/errors/app_exception.dart';

/// Amounts use minor currency units so allocations sum exactly to the deduction.
class SupplierAdvance {
  const SupplierAdvance({
    required this.name,
    required this.paidMinor,
    required this.unallocatedMinor,
    this.remarks = '',
  });
  final String name;
  final int paidMinor;
  final int unallocatedMinor;
  final String remarks;
  double get unallocatedAmount => unallocatedMinor / 100;

  factory SupplierAdvance.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString().trim() ?? '';
    int amount(dynamic value) {
      final parsed = num.tryParse('$value');
      if (parsed == null || !parsed.isFinite || parsed < 0) {
        throw const AppException(
          'The server returned an invalid supplier advance amount.',
        );
      }
      final scaled = parsed * 100;
      if (!scaled.isFinite || scaled > 9007199254740991) {
        throw const AppException(
          'The server returned an invalid supplier advance amount.',
        );
      }
      return scaled.round();
    }

    if (name.isEmpty) {
      throw const AppException(
        'The server returned an advance without a reference name.',
      );
    }
    return SupplierAdvance(
      name: name,
      paidMinor: amount(json['paid_amount']),
      unallocatedMinor: amount(json['unallocated_amount']),
      remarks: json['remarks']?.toString() ?? '',
    );
  }
}

class SupplierAdvanceAllocation {
  const SupplierAdvanceAllocation({
    required this.advance,
    required this.allocatedMinor,
  });
  final SupplierAdvance advance;
  final int allocatedMinor;
  double get allocatedAmount => allocatedMinor / 100;
  Map<String, dynamic> toJson() => {
    'reference_name': advance.name,
    'remarks': advance.remarks,
    'advance_amount': advance.unallocatedAmount,
    'allocated_amount': allocatedAmount,
  };
}
