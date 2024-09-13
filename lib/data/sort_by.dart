enum SortBy {
  text('By text'),
  date('By date'),
  color('By color'),
  label('By label'),
  favorite('By favorite'),
  crossedOut('By crossed out');

  final String caption;

  const SortBy(this.caption);
}

enum SortByOrder {
  asc,
  desc,
}

class SortByChoice {
  final SortBy sortBy;
  final SortByOrder order;

  SortByChoice(this.sortBy, this.order);
}
