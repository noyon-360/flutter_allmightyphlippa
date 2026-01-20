class MovieSeriesChannelRequestModel {
  final String serverUrl;
  final String username;
  final String password;
  final String type;
  final int limit;
  final int page;

  MovieSeriesChannelRequestModel({
    this.serverUrl = 'http://proxpanel.pro',
    this.username = 'tes83747',
    this.password = 'tes736836',
    required this.type,
    this.limit = 50,
    this.page = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'serverUrl': serverUrl,
      'username': username,
      'password': password,
      'type': type,
      'limit': limit,
      'page': page,
    };
  }

  MovieSeriesChannelRequestModel copyWith({
    String? serverUrl,
    String? username,
    String? password,
    String? type,
    int? limit,
    int? page,
  }) {
    return MovieSeriesChannelRequestModel(
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      type: type ?? this.type,
      limit: limit ?? this.limit,
      page: page ?? this.page,
    );
  }

  factory MovieSeriesChannelRequestModel.fromJson(Map<String, dynamic> json) {
    return MovieSeriesChannelRequestModel(
      serverUrl: json['serverUrl'] ?? 'http://proxpanel.pro',
      username: json['username'] ?? 'tes83747',
      password: json['password'] ?? 'tes736836',
      type: json['type'] ?? 'movies',
      limit: json['limit'] ?? 50,
      page: json['page'] ?? 1,
    );
  }
}
