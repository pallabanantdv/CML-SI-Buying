class PaginationModel<T> {
  const PaginationModel({
    required this.items,
    required this.start,
    required this.hasMore,
  });
  final List<T> items;
  final int start;
  final bool hasMore;
}
