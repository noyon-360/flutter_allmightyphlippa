class LoginRequestModel {
  final String email;
  final String password;
  final String deviceId;

  LoginRequestModel({
    required this.email,
    required this.password,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() {
    return {"email": email, "password": password, "deviceId": deviceId};
  }
}
