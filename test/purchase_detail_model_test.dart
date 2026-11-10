import 'package:flutter_test/flutter_test.dart';
import 'package:cml_si_buying/features/point_of_purchase/models/purchase_detail_model.dart';

void main() {
  test(
    'parses form payload values and excludes ERP-only fields at every level',
    () {
      final model = PurchaseDetailModel.fromJson({
        'name': 'POP-1',
        'docstatus': '1',
        'supplier_name': 'SUP-1',
        'gross_weight': '50',
        'net_qty': 0.045,
        'instant_paid': true,
        'paid_to': 'Payable account',
        'owner': 'Administrator',
        'unknown': 'hidden',
        'total_bag': [
          {
            'bag_number': 'Bag - 1',
            'weight': '50',
            'tarebagkg': 5,
            'parent': 'POP-1',
          },
        ],
        'supplier_pop_item': [
          {
            'item_code': 'RAW-002',
            'qty': '0.045',
            'total_amount': 450,
            'modified': 'hidden',
          },
        ],
        'pop_cash_payment': [
          {
            'payment_type': 'Bank',
            'reference_no': 'CHQ-10',
            'reference_date': '2026-11-10',
            'paid_amount': '450',
            'due_amount': 99,
          },
        ],
        'extra_table': [
          {'secret': 'hidden'},
        ],
      });
      expect(model.grossWeight, 50);
      expect(model.netQty, 0.045);
      expect(model.docstatus, 1);
      expect(model.instantPaid, 1);
      expect(model.totalBag!.single.tarebagkg, 5);
      expect(model.supplierPopItem!.single.qty, 0.045);
      expect(model.popCashPayment!.single.referenceNo, 'CHQ-10');
      final json = model.toJson();
      expect(json.containsKey('owner'), false);
      expect(json.containsKey('extra_table'), false);
      expect((json['total_bag'] as List).single.containsKey('parent'), false);
      expect(
        (json['pop_cash_payment'] as List).single.containsKey('due_amount'),
        false,
      );
      expect(PurchaseDetailModel.fromJson({}).totalBag, isEmpty);
    },
  );
}
