abstract class Failure {
  final String message;
  
  const Failure(this.message);
}

class PdfProtectionFailure extends Failure {
  const PdfProtectionFailure(super.message);
}

class FileNotFoundFailure extends Failure {
  const FileNotFoundFailure() : super('PDF file not found');
}

class InvalidPasswordFailure extends Failure {
  const InvalidPasswordFailure() : super('Password cannot be empty');
}

class FileReadWriteFailure extends Failure {
  const FileReadWriteFailure(String message) : super(message);
}

class PlatformNotSupportedFailure extends Failure {
  const PlatformNotSupportedFailure() : super('PDF encryption is only supported on Android');
}
