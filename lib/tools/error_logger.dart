import 'dart:io';
import 'package:ohnote/tools/datetime_to_str_converter.dart';
import 'package:path_provider/path_provider.dart' as pp;
import 'package:path/path.dart' as p;

class ErrorLogger {
  const ErrorLogger._();

  static String _previousStackTrace = '';
  static bool _isWriting = false;
  static final List<String> _pendingMessages = [];

  static String? __errorsPath;
  static Future<String?> get _errorsPath async {
    __errorsPath ??= (await Directory(p.join((await pp.getApplicationDocumentsDirectory()).path, 'error_logs')).create(recursive: true)).path;
    return __errorsPath;
  }

  static void log(String message) async {
    String stackTrace;
    try {
      throw message;
    } catch (e, s) {
      stackTrace = s.toString();
    }
    if (_previousStackTrace != stackTrace) {
      _previousStackTrace = stackTrace;
      stackTrace = '${Platform.lineTerminator}$stackTrace';
    } else {
      //TODO: test
      stackTrace = '';
    }
    var now = DateTime.now();
    try {
      var errPath = await _errorsPath;
      if (errPath != null && errPath.isNotEmpty) {
        var logFile = File(p.join(errPath, 'error_${now.parseDateToStr(DTToStrFormat.DATABASE).replaceAll('-', '')}.log'));
        _pendingMessages.add('${now.parseToStr(DTToStrFormat.LOCALE)}: $message$stackTrace${Platform.lineTerminator}');
        while (_isWriting) {
          await Future.delayed(const Duration(milliseconds: 10));
        }
        _isWriting = true;
        await logFile.writeAsString(_pendingMessages.removeAt(0), mode: FileMode.writeOnlyAppend);
      }
    } catch (_) {
    } finally {
      _isWriting = false;
    }
  }
}
