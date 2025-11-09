import 'package:dartz/dartz.dart';
import 'package:open_filex/open_filex.dart';

class OpenService {
  static Future<Either<Exception, bool>> open(String path) async {
    try {
      final res = await OpenFilex.open(path);
      return Right(res.type == ResultType.done);
    } catch (e) {
      return Left(Exception('Open failed: $e'));
    }
  }
}
