/// The smallest index of a source mark not in [used] (FR-012.2, ADR-012).
///
/// @implements FR-012: two disks never share a mark, and a disk registered
/// after another gets the first free one.
int nextFreeMarkIndex(Iterable<int> used) {
  final taken = used.toSet();
  var index = 0;
  while (taken.contains(index)) {
    index++;
  }
  return index;
}
