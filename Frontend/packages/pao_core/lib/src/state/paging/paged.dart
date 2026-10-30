/// One page of a cursor-paged list.
class Paged<T> {
  /// Creates a page; [next] is null on the last page.
  const Paged(this.items, [this.next]);

  /// Rows of this page.
  final List<T> items;

  /// Cursor of the following page.
  final String? next;
}
