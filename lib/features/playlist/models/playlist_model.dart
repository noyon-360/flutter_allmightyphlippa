class PlaylistModel {
  final String? name;
  final String? userName;
  final String? password;
  final String? url;

  PlaylistModel({this.name, this.userName, this.password, this.url});

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      name: json['name'],
      userName: json['userName'],
      password: json['password'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'userName': userName,
      'password': password,
      'url': url,
    };
  }

  PlaylistModel copyWith({
    String? name,
    String? userName,
    String? password,
    String? url,
  }) {
    return PlaylistModel(
      name: name ?? this.name,
      userName: userName ?? this.userName,
      password: password ?? this.password,
      url: url ?? this.url,
    );
  }
}
