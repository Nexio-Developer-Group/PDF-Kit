abstract class Failure {
  final String message;

  const Failure(this.message);
}

class PdfProtectionFailure extends Failure {
  const PdfProtectionFailure(super.message);
}

class FileNotFoundFailure extends Failure {
  const FileNotFoundFailure() : super('error_file_not_found');
}

class InvalidPasswordFailure extends Failure {
  const InvalidPasswordFailure() : super('error_invalid_password');
}

class FileReadWriteFailure extends Failure {
  const FileReadWriteFailure(super.message);
}

class PlatformNotSupportedFailure extends Failure {
  const PlatformNotSupportedFailure()
    : super('PDF encryption is only supported on Android');
}
