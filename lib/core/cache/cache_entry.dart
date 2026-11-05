class CacheEntry {
  const CacheEntry({
    required this.key,
    required this.endpoint,
    required this.parameters,
    required this.data,
    required this.owner,
    required this.createdAt,
    required this.updatedAt,
    required this.freshFor,
  });
  final String key, endpoint, owner;
  final Map<String, dynamic> parameters;
  final dynamic data;
  final DateTime createdAt, updatedAt;
  final Duration freshFor;
  bool isFresh(DateTime now) => now.difference(updatedAt) < freshFor;
  Map<String, dynamic> toJson() => {
    'version': 1,
    'key': key,
    'endpoint': endpoint,
    'parameters': parameters,
    'data': data,
    'owner': owner,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'freshSeconds': freshFor.inSeconds,
  };
  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) throw const FormatException('Cache version');
    return CacheEntry(
      key: json['key'] as String,
      endpoint: json['endpoint'] as String,
      parameters: Map<String, dynamic>.from(json['parameters'] as Map),
      data: json['data'],
      owner: json['owner'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      freshFor: Duration(seconds: json['freshSeconds'] as int),
    );
  }
}
