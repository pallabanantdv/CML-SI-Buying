class UserModel {
  const UserModel({required this.id, this.fullName});
  final String id;
  final String? fullName;
  factory UserModel.fromValue(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return UserModel(id: value);
    }
    if (value is Map) {
      return UserModel(
        id: '${value['name'] ?? value['email'] ?? ''}',
        fullName: value['full_name'] as String?,
      );
    }
    return const UserModel(id: '');
  }
}
