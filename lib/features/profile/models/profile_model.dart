class ProfileModel {
  const ProfileModel({required this.fields, this.roles = const []});

  final Map<String, dynamic> fields;
  final List<String> roles;

  String get email => '${fields['email'] ?? fields['name'] ?? ''}';
  String get fullName =>
      '${fields['full_name'] ?? fields['first_name'] ?? fields['username'] ?? email}';

  factory ProfileModel.fromJson(
    Map<String, dynamic> json, {
    List<String> roles = const [],
  }) => ProfileModel(fields: Map.unmodifiable(json), roles: roles);
}
