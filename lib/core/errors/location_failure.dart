class LocationFailure implements Exception {
  final String message;

  const LocationFailure(this.message);

  @override
  String toString() => message;
}
