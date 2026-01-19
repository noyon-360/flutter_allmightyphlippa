class RegisterRequestModel {
  final String? name;
  final String? email;
  final String? password;
  final String? confirmPassword;

  RegisterRequestModel({
    this.name,
    this.email,
    this.password,
    this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword,
    };
  }
}
