class PostModel {
  final int id;
  final String? title;
  final String content;
  final List<String> images;
  final String? videoUrl;
  final String? link;
  final DateTime createdAt;
  final DateTime updatedAt;

  PostModel({
    required this.id,
    this.title,
    required this.content,
    required this.images,
    this.videoUrl,
    this.link,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as int,
      title: json['title'] as String?,
      content: json['content'] as String,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      videoUrl: json['videoUrl'] as String?,
      link: json['link'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
