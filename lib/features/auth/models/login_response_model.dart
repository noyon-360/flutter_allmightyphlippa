import 'user_response_model.dart';

class LoginData {
  final String? accessToken;
  final String? refreshToken;
  final String? role;
  final String? id;
  final UserModel? user;

  LoginData({
    this.accessToken,
    this.refreshToken,
    this.role,
    this.id,
    this.user,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      role: json['role'],
      id: json['_id'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'role': role,
      '_id': id,
      'user': user?.toJson(),
    };
  }
}
