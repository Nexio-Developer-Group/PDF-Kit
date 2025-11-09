class UnsupportedPlatformException implements Exception {
  final String message;
  UnsupportedPlatformException([this.message = "Unsupported platform for permission request"]);
  @override
  String toString() => "UnsupportedPlatformException: $message";
}
