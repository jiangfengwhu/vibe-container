enum BridgeErrorCode {
  permissionDenied('PERMISSION_DENIED'),
  invalidParams('INVALID_PARAMS'),
  notFound('NOT_FOUND'),
  notSupported('NOT_SUPPORTED'),
  cancelled('CANCELLED'),
  internalError('INTERNAL_ERROR');

  const BridgeErrorCode(this.value);

  final String value;
}

class BridgeException implements Exception {
  const BridgeException(this.code, this.message);

  final BridgeErrorCode code;
  final String message;

  Map<String, Object?> toJson() => <String, Object?>{
    'code': code.value,
    'message': message,
  };

  @override
  String toString() => '${code.value}: $message';
}
