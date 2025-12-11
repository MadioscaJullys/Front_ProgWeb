class Posts {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final String city;
  final String createdAt;
  final int userId;

  Posts({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.city,
    required this.createdAt,
    required this.userId,
  });

  factory Posts.fromJson(Map<String, dynamic> json) {
    return Posts(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['image_url'],
      city: json['city'],
      createdAt: json['created_at'],
      userId: json['user_id'],
    );
  }
}
