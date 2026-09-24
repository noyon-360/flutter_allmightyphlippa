class PlaylistModel {
  final String? name;
  final String? userName;
  final String? password;
  final String? url;
  final String? id;

  PlaylistModel({this.name, this.userName, this.password, this.url, this.id});

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      name: json['name'],
      userName: json['userName'],
      password: json['password'],
      url: json['url'],
      id: json['_id'],
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
    String? id,
  }) {
    return PlaylistModel(
      name: name ?? this.name,
      userName: userName ?? this.userName,
      password: password ?? this.password,
      url: url ?? this.url,
      id: id ?? this.id,
    );
  }
}
