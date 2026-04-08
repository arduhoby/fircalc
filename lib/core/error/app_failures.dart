sealed class AppFailure {
  const AppFailure(this.message);
  final String message;
}

class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message);
}

class ParsingFailure extends AppFailure {
  const ParsingFailure(super.message);
}

class StorageFailure extends AppFailure {
  const StorageFailure(super.message);
}
