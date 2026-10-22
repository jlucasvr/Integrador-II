class GeoCoordinates {
  final double latitude;
  final double longitude;

  const GeoCoordinates(this.latitude, this.longitude)
      : assert(latitude >= -90 && latitude <= 90),
        assert(longitude >= -180 && longitude <= 180);
}
