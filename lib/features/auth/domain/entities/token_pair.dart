
class TokenPair {
  final String accessToken;
  final String refreshToken;
  final String tokenType;

  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'Bearer',
  });
}