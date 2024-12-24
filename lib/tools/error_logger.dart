import 'dart:io';
import 'package:ohnote/tools/datetime_to_str_converter.dart';
import 'package:path_provider/path_provider.dart' as pp;
import 'package:path/path.dart' as p;

class ErrorLogger {
  const ErrorLogger._();

  static void Function()? onLogStarted;
  static void Function()? onLogEnded;
  static String _previousStackTrace = '';
  static bool _isWriting = false;
  static final List<String> _pendingMessages = [];

  // /data/user/0/com.example.ohnote/app_flutter/error_logs
  static String? __errorsPath;
  static Future<String?> get _errorsPath async {
    __errorsPath ??= p.join((await pp.getApplicationDocumentsDirectory()).path, 'error_logs');
    return __errorsPath;
  }

  static void log(String message) async {
    var stackTrace = StackTrace.current.toString();
    onLogStarted?.call();
    if (_previousStackTrace != stackTrace) {
      _previousStackTrace = stackTrace;
      stackTrace =
          '${Platform.lineTerminator}${stackTrace.trim().split('\n').skip(1).map((e) => e.replaceAll('\r', '')).map((e) => '    ${(e.startsWith('#') ? e.substring(e.indexOf(' ')) : e).trim()}').join(Platform.lineTerminator)}';
    } else {
      stackTrace = '';
    }
    var now = DateTime.now();
    try {
      var errPath = await _errorsPath;
      if (errPath != null && errPath.isNotEmpty) {
        var destination = (await Directory(p.join(errPath, now.year.toString())).create(recursive: true)).path;
        var logFile = File(p.join(destination, 'error_${now.parseDateToStr(DTToStrFormat.DATABASE).replaceAll('-', '')}.log'));
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
      onLogEnded?.call();
    }
  }
}
