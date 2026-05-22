import 'api_client.dart';

class RepositoryValidationException implements Exception {
  const RepositoryValidationException({
    required this.message,
    this.fieldErrors = const {},
    this.exception,
  });

  final String message;
  final Map<String, List<String>> fieldErrors;
  final Object? exception;
}

class RepositoryConflictException implements Exception {
  const RepositoryConflictException({required this.message, this.exception});

  final String message;
  final Object? exception;
}

String messageFromApiException(ApiException exception) {
  return switch (exception.statusCode) {
    401 => 'Your session has expired. Please sign in again.',
    403 => exception.message,
    404 => 'The requested resource was not found.',
    409 => exception.message,
    422 => exception.message,
    429 => 'Too many requests. Please try again later.',
    >= 500 => 'The server could not complete the request.',
    _ => exception.message,
  };
}

RepositoryValidationException? validationExceptionFrom(Object? exception) {
  if (exception is ApiException && exception.statusCode == 422) {
    return RepositoryValidationException(
      message: exception.message,
      fieldErrors: exception.fieldErrors,
      exception: exception,
    );
  }
  if (exception is RepositoryValidationException) {
    return exception;
  }
  return null;
}

RepositoryConflictException? conflictExceptionFrom(Object? exception) {
  if (exception is ApiException && exception.statusCode == 409) {
    return RepositoryConflictException(
      message: exception.message,
      exception: exception,
    );
  }
  if (exception is RepositoryConflictException) {
    return exception;
  }
  return null;
}
