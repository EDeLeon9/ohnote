import 'dart:convert' as convert;
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:ohnote/tools/single_async.dart' as a;

final _clickFunctions = <String, void Function(Map<String, String>)>{};

class HomeWidgetManager {
  const HomeWidgetManager._();

  static late String _appSchemeName;
  static late String _widgetProviderName;
  static late String _iOSWidgetProviderName;
  static late String _widgetDataName;

  static void initialize({
    required String appSchemeName,
    required String widgetProviderName,
    required String iOSWidgetProviderName,
    required String widgetDataName,
    bool runEnsureInitialized = true,
  }) {
    _appSchemeName = appSchemeName;
    _widgetProviderName = widgetProviderName;
    _iOSWidgetProviderName = iOSWidgetProviderName;
    _widgetDataName = widgetDataName;
    if (runEnsureInitialized) {
      WidgetsFlutterBinding.ensureInitialized(); //Required to work with home widget package.
    }
    return;
    //HomeWidget.widgetClicked.listen is not executed in lower android APIs.
    // ignore: dead_code
    HomeWidget.widgetClicked.listen((Uri? uri) {
      if (uri?.scheme == _appSchemeName && _clickFunctions.containsKey(uri!.host)) {
        var function = _clickFunctions[uri.host]!;
        function(uri.queryParameters);
      }
    });
  }

  static void updateWidget(List? list) {
    //TODO: Use a separated filtered list (filter will be asked when adding the widget to homescreen).
    return;
    // ignore: dead_code
    a.runLast(300, () async {
      list ??= [];
      var json = convert.jsonEncode(list);
      await HomeWidget.saveWidgetData<String>(_widgetDataName, json);
      await HomeWidget.updateWidget(name: _widgetProviderName, iOSName: _iOSWidgetProviderName);
    });
  }

  static void setClickFunction(String widgetMessage, void Function(Map<String, String>) function) {
    _clickFunctions[widgetMessage] = function;
  }

  static void runIfLaunchedFromHomeWidget(String widgetMessage, void Function(Map<String, String>) function) {
    HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
      if (uri?.scheme == _appSchemeName && uri!.host == widgetMessage) {
        function(uri.queryParameters);
      }
    });
  }
}
