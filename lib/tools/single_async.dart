import 'package:async/async.dart';

final _globalSingleAsync = SingleAsync();
bool runFirst(Future<void> Function() function) => _globalSingleAsync.runFirst(function);
void runLast(int msDelay, void Function() function) => _globalSingleAsync.runLast(msDelay, function);

class SingleAsync {
  bool _running = false;
  CancelableOperation? _cancelableOperation;

  bool runFirst(Future<void> Function() function) {
    if (!_running) {
      _running = true;
      function().whenComplete(() => _running = false);
      return true;
    } else {
      return false;
    }
  }

  void runLast(int msDelay, void Function() function) {
    _cancelableOperation?.cancel();
    _cancelableOperation = CancelableOperation.fromFuture(Future.delayed(Duration(milliseconds: msDelay)));
    _cancelableOperation!.value.whenComplete(() => function());
  }
}
