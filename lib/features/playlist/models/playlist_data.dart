class PlaylistData {
  final String url;
  final String username;
  final String password;

  PlaylistData({
    required this.url,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {'url': url, 'username': username, 'password': password};
  }

  factory PlaylistData.fromJson(Map<String, dynamic> json) {
    return PlaylistData(
      url: json['url'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
    );
  }

  factory PlaylistData.empty() {
    return PlaylistData(url: '', username: '', password: '');
  }

  bool get isEmpty => url.isEmpty && username.isEmpty && password.isEmpty;
  bool get isNotEmpty => !isEmpty;

  @override
  String toString() =>
      'PlaylistData(url: $url, username: $username, password: $password)';
}
