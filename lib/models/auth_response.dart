import 'user_model.dart';

class AuthResponse {
  final String token;
  final UserModel user;

  const AuthResponse({
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json["token"],
      user: UserModel.fromJson(json["user"]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "token": token,
      "user": user.toJson(),
    };
  }

  AuthResponse copyWith({
    String? token,
    UserModel? user,
  }) {
    return AuthResponse(
      token: token ?? this.token,
      user: user ?? this.user,
    );
  }
}