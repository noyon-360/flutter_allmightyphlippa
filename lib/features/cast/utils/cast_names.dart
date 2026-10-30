/// Splits the free-text cast list IPTV providers supply ("Anna Kim, Ben Lee")
/// into distinct actor names. Providers separate with commas, and sometimes
/// semicolons or pipes; the same person is often listed twice.
List<String> parseCastNames(String? raw, {int max = 12}) {
  if (raw == null || raw.trim().isEmpty) return const [];
  final seen = <String>{};
  final names = <String>[];
  for (final part in raw.split(RegExp(r'[,;|]'))) {
    final name = part.trim();
    if (name.isEmpty || !seen.add(name.toLowerCase())) continue;
    names.add(name);
    if (names.length >= max) break;
  }
  return names;
}

/// Up to two initials for a name ("Jean-Luc Picard" -> "JP"), for avatars
/// with no photo.
String initialsOf(String name) {
  final words = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) return words.first[0].toUpperCase();
  return (words.first[0] + words.last[0]).toUpperCase();
}
