class MarketNewsItem {
  const MarketNewsItem({
    required this.title,
    required this.url,
    required this.sourceLabel,
    this.publishedAt,
  });

  final String title;
  final String url;
  final String sourceLabel;
  final DateTime? publishedAt;
}
