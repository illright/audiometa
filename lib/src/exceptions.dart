class BadTagException implements Exception {
  String cause;
  
  BadTagException(this.cause);
}


class BadTagDataException implements Exception {
  String cause;

  BadTagDataException(this.cause);
}
