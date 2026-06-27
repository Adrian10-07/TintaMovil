import '../../domain/entities/token_pair.dart';

class TokenPairModel {
  static TokenPair fromJson(Map<String, dynamic> json) {
    return TokenPair(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String? ?? 'Bearer',
    );
  }
}