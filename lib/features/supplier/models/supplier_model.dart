class SupplierModel {
  const SupplierModel({
    required this.id,
    required this.name,
    this.group,
    this.type,
    this.country,
    this.province,
    this.island,
    this.village,
    this.phone,
    this.email,
    this.status,
    this.isDisabled = false,
    this.isFrozen = false,
    this.isOnHold = false,
  });

  final String id;
  final String name;
  final String? group;
  final String? type;
  final String? country;
  final String? province;
  final String? island;
  final String? village;
  final String? phone;
  final String? email;
  final String? status;
  final bool isDisabled;
  final bool isFrozen;
  final bool isOnHold;

  String? get location => [village, island, province, country]
      .whereType<String>()
      .where((part) => part.trim().isNotEmpty)
      .join(', ')
      .nonEmpty;

  factory SupplierModel.fromJson(Map<String, dynamic> json) => SupplierModel(
    id: _string(json['name']) ?? '',
    name:
        _string(json['supplier_name']) ??
        _string(json['name']) ??
        'Unnamed supplier',
    group: _string(json['supplier_group']),
    type: _string(json['supplier_type']),
    country: _string(json['country']),
    province: _string(json['province']),
    island: _string(json['custom_island']),
    village: _string(json['village']),
    phone: _string(json['custom_contact_number']) ?? _string(json['mobile_no']),
    email: _string(json['email_id']),
    status: _string(json['custom_status']),
    isDisabled: _flag(json['disabled']),
    isFrozen: _flag(json['is_frozen']),
    isOnHold: _flag(json['on_hold']),
  );

  static String? _string(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static bool _flag(dynamic value) => value == true || value.toString() == '1';
}

extension on String {
  String? get nonEmpty => isEmpty ? null : this;
}
