/// A capability mismatch is distinct from an expired session or bad credentials.
class ApiCompatibilityException implements Exception {
  const ApiCompatibilityException();
}

class InvalidApiResponseException implements Exception {
  const InvalidApiResponseException();
}
