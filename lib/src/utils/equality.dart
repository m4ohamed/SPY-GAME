/// Small structural-equality helpers so domain entities can hold collections
/// without pulling in extra packages.
bool listsEqual<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool setsEqual<T>(Set<T> a, Set<T> b) {
  if (identical(a, b)) return true;
  return a.length == b.length && a.containsAll(b);
}

bool mapsEqual<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

int hashMap<K, V>(Map<K, V> map) => Object.hashAllUnordered(
      map.entries.map((entry) => Object.hash(entry.key, entry.value)),
    );
