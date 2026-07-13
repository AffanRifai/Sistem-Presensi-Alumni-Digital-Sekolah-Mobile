import '../../../core/network/api_client.dart';

class EducationNews {
  final int id;
  final String title;
  final String publishedAt;
  final String category;
  final String imageUrl;
  final String articleUrl;
  final String source;

  const EducationNews({
    required this.id,
    required this.title,
    required this.publishedAt,
    required this.category,
    required this.imageUrl,
    required this.articleUrl,
    required this.source,
  });

  factory EducationNews.fromJson(Map<String, dynamic> json) {
    return EducationNews(
      id: _readInt(json['id']),
      title: json['title']?.toString() ?? 'Informasi Pendidikan',
      publishedAt: json['published_at']?.toString() ?? '-',
      category: json['category']?.toString() ?? 'Berita',
      imageUrl: json['image_url']?.toString() ?? '',
      articleUrl: json['article_url']?.toString() ?? '',
      source: json['source']?.toString() ?? 'Kemendikdasmen',
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class EducationNewsService {
  EducationNewsService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<EducationNews>> fetchLatest() async {
    final response = await _apiClient.get('/education-news');
    final data = response['data'];

    if (data is! List) return const [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(EducationNews.fromJson)
        .where((news) => news.id > 0 && news.articleUrl.isNotEmpty)
        .toList();
  }
}
