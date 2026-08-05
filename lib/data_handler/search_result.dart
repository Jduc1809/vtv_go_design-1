class SearchResult {
  final String id;
  final String title;
  final String subTitle;
  final String type;
  final String image;
  final int TargetType;
  final String? vodId;

  SearchResult({
    required this.id,
    required this.title,
    required this.subTitle,
    required this.type,
    required this.image,
    required this.TargetType,
    this.vodId,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unknown Title',
      subTitle: json['subTitle'] ?? '',
      type: json['type'] ?? '',
      image: json['image'] ?? '',
      TargetType: json['TargetType'] ?? 0,
      vodId: json['vodId'],
    );
  }
}
