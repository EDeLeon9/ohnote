import 'package:flutter/material.dart';

class ValueNotifierPlus<T> extends ValueNotifier<T> {
  ValueNotifierPlus(super.value);

  @override
  void notifyListeners() => super.notifyListeners();
}
