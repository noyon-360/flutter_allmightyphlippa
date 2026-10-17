import 'playlist_account_info.dart';

class PlaylistModel {
  final String? name;
  final String? userName;
  final String? password;
  final String? url;
  final String? id;

  /// Subscription state of this line, when the provider could be reached.
  /// Null means unknown — the card simply shows no badge.
  final PlaylistAccountInfo? accountInfo;

  PlaylistModel({
    this.name,
    this.userName,
    this.password,
    this.url,
    this.id,
    this.accountInfo,
  });

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      name: json['name'],
      userName: json['userName'],
      password: json['password'],
      url: json['url'],
      id: json['_id'],
      accountInfo: PlaylistAccountInfo.fromJson(json['accountInfo']),
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
    PlaylistAccountInfo? accountInfo,
  }) {
    return PlaylistModel(
      name: name ?? this.name,
      userName: userName ?? this.userName,
      password: password ?? this.password,
      url: url ?? this.url,
      id: id ?? this.id,
      accountInfo: accountInfo ?? this.accountInfo,
    );
  }
}
