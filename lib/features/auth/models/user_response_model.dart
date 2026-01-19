class UserModel {
  final Avatar? avatar;
  final ShopLogo? shopLogo;
  final VerificationInfo? verificationInfo;
  final String? id;
  final String? name;
  final String? email;
  final String? password;
  final String? language;
  final bool? ticketAlerts;
  final bool? licenseExpiryAlerts;
  final bool?
  inactiveAlerts; // Renamed from lnactiveAlerts for clarity, but JSON has 'lnactiveAlerts'
  final bool? teenDriverAlerts;
  final bool? communityAlerts;
  final String? role;
  final String? passwordResetToken;
  final String? accessToken;
  final String? refreshToken;
  final bool? isEmailVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  UserModel({
    this.avatar,
    this.shopLogo,
    this.verificationInfo,
    this.id,
    this.name,
    this.email,
    this.password,
    this.language,
    this.ticketAlerts,
    this.licenseExpiryAlerts,
    this.inactiveAlerts,
    this.teenDriverAlerts,
    this.communityAlerts,
    this.role,
    this.passwordResetToken,
    this.accessToken,
    this.refreshToken,
    this.isEmailVerified,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      avatar: json['avatar'] != null ? Avatar.fromJson(json['avatar']) : null,
      shopLogo: json['shopLogo'] != null
          ? ShopLogo.fromJson(json['shopLogo'])
          : null,
      verificationInfo: json['verificationInfo'] != null
          ? VerificationInfo.fromJson(json['verificationInfo'])
          : null,
      id: json['_id'],
      name: json['name'],
      email: json['email'],
      password: json['password'],
      language: json['language'],
      ticketAlerts: json['ticketAlerts'],
      licenseExpiryAlerts: json['licenseExpiryAlerts'],
      inactiveAlerts:
          json['lnactiveAlerts'], // Matching the typo in JSON 'lnactiveAlerts'
      teenDriverAlerts: json['teenDriverAlerts'],
      communityAlerts: json['communityAlerts'],
      role: json['role'],
      passwordResetToken: json['password_reset_token'],
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      isEmailVerified: json['isEmailVerified'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      v: json['__v'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avatar': avatar?.toJson(),
      'shopLogo': shopLogo?.toJson(),
      'verificationInfo': verificationInfo?.toJson(),
      '_id': id,
      'name': name,
      'email': email,
      'password': password,
      'language': language,
      'ticketAlerts': ticketAlerts,
      'licenseExpiryAlerts': licenseExpiryAlerts,
      'lnactiveAlerts': inactiveAlerts,
      'teenDriverAlerts': teenDriverAlerts,
      'communityAlerts': communityAlerts,
      'role': role,
      'password_reset_token': passwordResetToken,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      '__v': v,
    };
  }
}

class Avatar {
  final String? publicId;
  final String? url;

  Avatar({this.publicId, this.url});

  factory Avatar.fromJson(Map<String, dynamic> json) {
    return Avatar(publicId: json['public_id'], url: json['url']);
  }

  Map<String, dynamic> toJson() {
    return {'public_id': publicId, 'url': url};
  }
}

class ShopLogo {
  final String? publicId;
  final String? url;

  ShopLogo({this.publicId, this.url});

  factory ShopLogo.fromJson(Map<String, dynamic> json) {
    return ShopLogo(publicId: json['public_id'], url: json['url']);
  }

  Map<String, dynamic> toJson() {
    return {'public_id': publicId, 'url': url};
  }
}

class VerificationInfo {
  final bool? verified;
  final String? token;

  VerificationInfo({this.verified, this.token});

  factory VerificationInfo.fromJson(Map<String, dynamic> json) {
    return VerificationInfo(verified: json['verified'], token: json['token']);
  }

  Map<String, dynamic> toJson() {
    return {'verified': verified, 'token': token};
  }
}
