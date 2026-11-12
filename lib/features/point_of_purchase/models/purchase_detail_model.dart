// Fields mirror the purchase form payload. ERP metadata is intentionally excluded.

class PurchaseBagDetail {
  const PurchaseBagDetail({this.bagNumber, this.weight, this.tarebagkg});
  final String? bagNumber;
  final double? weight;
  final double? tarebagkg;
  factory PurchaseBagDetail.fromJson(Map<String, dynamic> json) =>
      PurchaseBagDetail(
        bagNumber: json['bag_number']?.toString(),
        weight: _number(json['weight'])?.toDouble(),
        tarebagkg: _number(json['tarebagkg'])?.toDouble(),
      );
  Map<String, dynamic> toJson() => {
    'bag_number': bagNumber,
    'weight': weight,
    'tarebagkg': tarebagkg,
  };
}

class PurchaseItemDetail {
  const PurchaseItemDetail({
    this.itemCode,
    this.itemName,
    this.qty,
    this.uom,
    this.rate,
    this.totalAmount,
  });
  final String? itemCode;
  final String? itemName;
  final double? qty;
  final String? uom;
  final double? rate;
  final double? totalAmount;
  factory PurchaseItemDetail.fromJson(Map<String, dynamic> json) =>
      PurchaseItemDetail(
        itemCode: json['item_code']?.toString(),
        itemName: json['item_name']?.toString(),
        qty: _number(json['qty'])?.toDouble(),
        uom: json['uom']?.toString(),
        rate: _number(json['rate'])?.toDouble(),
        totalAmount: _number(json['total_amount'])?.toDouble(),
      );
  Map<String, dynamic> toJson() => {
    'item_code': itemCode,
    'item_name': itemName,
    'qty': qty,
    'uom': uom,
    'rate': rate,
    'total_amount': totalAmount,
  };
}

class PurchaseAdvanceDetail {
  const PurchaseAdvanceDetail({
    this.referenceName,
    this.remarks,
    this.advanceAmount,
    this.allocatedAmount,
    this.referenceType,
  });
  final String? referenceName;
  final String? remarks;
  final double? advanceAmount;
  final double? allocatedAmount;
  final String? referenceType;
  factory PurchaseAdvanceDetail.fromJson(Map<String, dynamic> json) =>
      PurchaseAdvanceDetail(
        referenceName: json['reference_name']?.toString(),
        remarks: json['remarks']?.toString(),
        advanceAmount: _number(json['advance_amount'])?.toDouble(),
        allocatedAmount: _number(json['allocated_amount'])?.toDouble(),
        referenceType: json['reference_type']?.toString(),
      );
  Map<String, dynamic> toJson() => {
    'reference_name': referenceName,
    'remarks': remarks,
    'advance_amount': advanceAmount,
    'allocated_amount': allocatedAmount,
    'reference_type': referenceType,
  };
}

class PurchaseCashPaymentDetail {
  const PurchaseCashPaymentDetail({
    this.paymentType,
    this.paymentFrom,
    this.paidAmount,
    this.referenceNo,
    this.referenceDate,
    this.checkKnlg,
  });
  final String? paymentType;
  final String? paymentFrom;
  final double? paidAmount;
  final String? referenceNo;
  final String? referenceDate;
  final int? checkKnlg;
  factory PurchaseCashPaymentDetail.fromJson(Map<String, dynamic> json) =>
      PurchaseCashPaymentDetail(
        paymentType: json['payment_type']?.toString(),
        paymentFrom: json['payment_from']?.toString(),
        paidAmount: _number(json['paid_amount'])?.toDouble(),
        referenceNo: json['reference_no']?.toString(),
        referenceDate: json['reference_date']?.toString(),
        checkKnlg: _number(json['check_knlg'])?.toInt(),
      );
  Map<String, dynamic> toJson() => {
    'payment_type': paymentType,
    'payment_from': paymentFrom,
    'paid_amount': paidAmount,
    'reference_no': referenceNo,
    'reference_date': referenceDate,
    'check_knlg': checkKnlg,
  };
}

class PurchaseDetailModel {
  const PurchaseDetailModel({
    this.name,
    this.namingSeries,
    this.supplierName,
    this.supplierName1,
    this.supplierType,
    this.village,
    this.province,
    this.collectionLocation,
    this.island,
    this.phonemobileNo,
    this.ffa,
    this.deliveryType,
    this.customProductType,
    this.courierName,
    this.moisture,
    this.copraBagLevel,
    this.defaultAcceptedWarehouse,
    this.vesel,
    this.veselName,
    this.date,
    this.company,
    this.contractNo,
    this.refPvNo,
    this.bankAccount,
    this.cashAccount,
    this.cashbankAccount,
    this.inventoryAccount,
    this.advanceReceivableAccount,
    this.supplierPayableAccount,
    this.paidTo,
    this.othershippingAccount,
    this.journalEntry,
    this.time,
    this.popDatetime,
    this.noOfBag,
    this.grossWeight,
    this.rate,
    this.freight,
    this.others,
    this.tare15kgsbag,
    this.seaFare,
    this.totalAmount,
    this.grandTotal,
    this.shipPayment,
    this.totalDeduction,
    this.advances,
    this.customPaidAdvance,
    this.netPayable,
    this.outstandingAmount,
    this.netQty,
    this.docstatus,
    this.instantPaid,
    this.totalBag,
    this.supplierPopItem,
    this.advance,
    this.popCashPayment,
  });
  final String? name;
  final String? namingSeries;
  final String? supplierName;
  final String? supplierName1;
  final String? supplierType;
  final String? village;
  final String? province;
  final String? collectionLocation;
  final String? island;
  final String? phonemobileNo;
  final String? ffa;
  final String? deliveryType;
  final String? customProductType;
  final String? courierName;
  final String? moisture;
  final String? copraBagLevel;
  final String? defaultAcceptedWarehouse;
  final String? vesel;
  final String? veselName;
  final String? date;
  final String? company;
  final String? contractNo;
  final String? refPvNo;
  final String? bankAccount;
  final String? cashAccount;
  final String? cashbankAccount;
  final String? inventoryAccount;
  final String? advanceReceivableAccount;
  final String? supplierPayableAccount;
  final String? paidTo;
  final String? othershippingAccount;
  final String? journalEntry;
  final String? time;
  final String? popDatetime;
  final double? noOfBag;
  final double? grossWeight;
  final double? rate;
  final double? freight;
  final double? others;
  final double? tare15kgsbag;
  final double? seaFare;
  final double? totalAmount;
  final double? grandTotal;
  final double? shipPayment;
  final double? totalDeduction;
  final double? advances;
  final double? customPaidAdvance;
  final double? netPayable;
  final double? outstandingAmount;

  /// Prefer the saved balance; net payable already includes advance deductions.
  double? get outstandingBalance {
    if (outstandingAmount != null) return outstandingAmount;
    if (netPayable == null) return null;
    final paid = (popCashPayment ?? <PurchaseCashPaymentDetail>[]).fold<double>(
      0,
      (sum, payment) => sum + (payment.paidAmount ?? 0),
    );
    final balance = netPayable! - paid;
    return balance > 0 ? balance : 0;
  }

  final double? netQty;
  final int? docstatus;
  final int? instantPaid;
  final List<PurchaseBagDetail>? totalBag;
  final List<PurchaseItemDetail>? supplierPopItem;
  final List<PurchaseAdvanceDetail>? advance;
  final List<PurchaseCashPaymentDetail>? popCashPayment;
  factory PurchaseDetailModel.fromJson(
    Map<String, dynamic> json,
  ) => PurchaseDetailModel(
    name: json['name']?.toString(),
    namingSeries: json['naming_series']?.toString(),
    supplierName: json['supplier_name']?.toString(),
    supplierName1: json['supplier_name1']?.toString(),
    supplierType: json['supplier_type']?.toString(),
    village: json['village']?.toString(),
    province: json['province']?.toString(),
    collectionLocation: json['collection_location']?.toString(),
    island: json['island']?.toString(),
    phonemobileNo: json['phonemobile_no']?.toString(),
    ffa: json['ffa']?.toString(),
    deliveryType: json['delivery_type']?.toString(),
    customProductType: json['custom_product_type']?.toString(),
    courierName: json['courier_name']?.toString(),
    moisture: json['moisture']?.toString(),
    copraBagLevel: json['copra_bag_level']?.toString(),
    defaultAcceptedWarehouse: json['default_accepted_warehouse']?.toString(),
    vesel: json['vesel']?.toString(),
    veselName: json['vesel_name']?.toString(),
    date: json['date']?.toString(),
    company: json['company']?.toString(),
    contractNo: json['contract_no']?.toString(),
    refPvNo: json['ref_pv_no']?.toString(),
    bankAccount: json['bank_account']?.toString(),
    cashAccount: json['cash_account']?.toString(),
    cashbankAccount: json['cashbank_account']?.toString(),
    inventoryAccount: json['inventory_account']?.toString(),
    advanceReceivableAccount: json['advance_receivable_account']?.toString(),
    supplierPayableAccount: json['supplier_payable_account']?.toString(),
    paidTo: json['paid_to']?.toString(),
    othershippingAccount: json['othershipping_account']?.toString(),
    journalEntry: json['journal_entry']?.toString(),
    time: json['time']?.toString(),
    popDatetime: json['pop_datetime']?.toString(),
    noOfBag: _number(json['no_of_bag'])?.toDouble(),
    grossWeight: _number(json['gross_weight'])?.toDouble(),
    rate: _number(json['rate'])?.toDouble(),
    freight: _number(json['freight'])?.toDouble(),
    others: _number(json['others'])?.toDouble(),
    tare15kgsbag: _number(json['tare15kgsbag'])?.toDouble(),
    seaFare: _number(json['sea_fare'])?.toDouble(),
    totalAmount: _number(json['total_amount'])?.toDouble(),
    grandTotal: _number(json['grand_total'])?.toDouble(),
    shipPayment: _number(json['ship_payment'])?.toDouble(),
    totalDeduction: _number(json['total_deduction'])?.toDouble(),
    advances: _number(json['advances'])?.toDouble(),
    customPaidAdvance: _number(json['custom_paid_advance'])?.toDouble(),
    netPayable: _number(json['net_payable'])?.toDouble(),
    outstandingAmount: _number(json['outstanding_amount'])?.toDouble(),
    netQty: _number(json['net_qty'])?.toDouble(),
    docstatus: _number(json['docstatus'])?.toInt(),
    instantPaid: _number(json['instant_paid'])?.toInt(),
    totalBag: _rows(json['total_bag'])
        .map(PurchaseBagDetail.fromJson)
        .toList(growable: false),
    supplierPopItem: _rows(json['supplier_pop_item'])
        .map(PurchaseItemDetail.fromJson)
        .toList(growable: false),
    advance: _rows(json['advance'])
        .map(PurchaseAdvanceDetail.fromJson)
        .toList(growable: false),
    popCashPayment: _rows(json['pop_cash_payment'])
        .map(PurchaseCashPaymentDetail.fromJson)
        .toList(growable: false),
  );
  Map<String, dynamic> toJson() => {
    'name': name,
    'naming_series': namingSeries,
    'supplier_name': supplierName,
    'supplier_name1': supplierName1,
    'supplier_type': supplierType,
    'village': village,
    'province': province,
    'collection_location': collectionLocation,
    'island': island,
    'phonemobile_no': phonemobileNo,
    'ffa': ffa,
    'delivery_type': deliveryType,
    'custom_product_type': customProductType,
    'courier_name': courierName,
    'moisture': moisture,
    'copra_bag_level': copraBagLevel,
    'default_accepted_warehouse': defaultAcceptedWarehouse,
    'vesel': vesel,
    'vesel_name': veselName,
    'date': date,
    'company': company,
    'contract_no': contractNo,
    'ref_pv_no': refPvNo,
    'bank_account': bankAccount,
    'cash_account': cashAccount,
    'cashbank_account': cashbankAccount,
    'inventory_account': inventoryAccount,
    'advance_receivable_account': advanceReceivableAccount,
    'supplier_payable_account': supplierPayableAccount,
    'paid_to': paidTo,
    'othershipping_account': othershippingAccount,
    'journal_entry': journalEntry,
    'time': time,
    'pop_datetime': popDatetime,
    'no_of_bag': noOfBag,
    'gross_weight': grossWeight,
    'rate': rate,
    'freight': freight,
    'others': others,
    'tare15kgsbag': tare15kgsbag,
    'sea_fare': seaFare,
    'total_amount': totalAmount,
    'grand_total': grandTotal,
    'ship_payment': shipPayment,
    'total_deduction': totalDeduction,
    'advances': advances,
    'custom_paid_advance': customPaidAdvance,
    'net_payable': netPayable,
    'outstanding_amount': outstandingAmount,
    'net_qty': netQty,
    'docstatus': docstatus,
    'instant_paid': instantPaid,
    'total_bag': totalBag?.map((row) => row.toJson()).toList(growable: false),
    'supplier_pop_item': supplierPopItem
        ?.map((row) => row.toJson())
        .toList(growable: false),
    'advance': advance?.map((row) => row.toJson()).toList(growable: false),
    'pop_cash_payment': popCashPayment
        ?.map((row) => row.toJson())
        .toList(growable: false),
  };
}

num? _number(dynamic value) => value is num
    ? value
    : value is bool
    ? (value ? 1 : 0)
    : num.tryParse("$value");
List<Map<String, dynamic>> _rows(dynamic value) => value is List
    ? value
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList()
    : [];
