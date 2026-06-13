/// Small null-safe coercion helpers shared by every `fromJson` factory, so a
/// missing or wrongly-typed field degrades to a sensible default instead of
/// throwing and taking down a whole screen.
library;

List<String> asStringList(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList(growable: false) : const [];

int asInt(dynamic v, [int fallback = 0]) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

String asStr(dynamic v, [String fallback = '']) => v?.toString() ?? fallback;

Map<String, dynamic> asMap(dynamic v) =>
    v is Map ? v.map((k, value) => MapEntry(k.toString(), value)) : const {};

List<Map<String, dynamic>> asMapList(dynamic v) => v is List
    ? v.whereType<Map>().map((e) => asMap(e)).toList(growable: false)
    : const [];
