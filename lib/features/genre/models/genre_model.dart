class GenreModel {
  final String categoryId;
  final String categoryName;

  GenreModel({required this.categoryId, required this.categoryName});

  factory GenreModel.fromJson(Map<String, dynamic> json) {
    return GenreModel(
      categoryId: json['category_id'],
      categoryName: json['category_name'],
    );
  }
}
