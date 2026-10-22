class ManagementFailure implements Exception {
  final int status;
  final String message;
  final bool uncertain;
  const ManagementFailure(this.status, this.message, {this.uncertain = false});
  @override
  String toString() => message;
}
