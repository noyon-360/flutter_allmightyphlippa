class GenreRequestModel {
  final String serverUrl;
  final String username;
  final String password;
  final String type;

  GenreRequestModel({
    required this.serverUrl,
    required this.username,
    required this.password,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      "serverUrl": serverUrl,
      "username": username,
      "password": password,
      "type": type,
    };
  }
}
