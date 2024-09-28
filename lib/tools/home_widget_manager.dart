import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:ohnote/tools/single_async.dart' as a;
import 'dart:convert' as cv;

final _clickFunctions = <String, void Function(Map<String, String>)>{};

class HomeWidgetManager {
  const HomeWidgetManager._();

  static late String _appSchemeName;
  static late String _androidWidgetName;
  static late String _iOSWidgetName;

  static void initialize({
    required String appSchemeName,
    required String appGroupId,
    required String androidWidgetName,
    required String iOSWidgetName,
    bool runEnsureInitialized = true,
  }) {
    _appSchemeName = appSchemeName;
    _androidWidgetName = androidWidgetName;
    _iOSWidgetName = iOSWidgetName;
    if (runEnsureInitialized) {
      WidgetsFlutterBinding.ensureInitialized(); //Required to work with home widget package.
    }
    return;
    //HomeWidget.widgetClicked.listen is not executed in very low android APIs.
    // ignore: dead_code
    HomeWidget.setAppGroupId(appGroupId); //This is needed for iOS Apps to talk to their WidgetExtensions
    HomeWidget.widgetClicked.listen((Uri? uri) {
      if (uri?.scheme == _appSchemeName && _clickFunctions.containsKey(uri!.host)) {
        var function = _clickFunctions[uri.host]!;
        function(uri.queryParameters);
      }
    });
  }

  static Future<T?> getWidgetData<T>(String valueName, T? defaultValue) {
    return HomeWidget.getWidgetData<T>(valueName, defaultValue: defaultValue);
  }

//TODO: Use a separated filtered list (filter will be asked when adding the widget to homescreen).
  static Future<void> updateWidget(String valueName, String value) async {
    return;
    // ignore: dead_code
    await HomeWidget.saveWidgetData(valueName, value);
    a.runLast(300, () async {
      await HomeWidget.updateWidget(name: _androidWidgetName, iOSName: _iOSWidgetName);
    });
  }

  static Future<void> updateWidgetWithSerializable<T>(String valueName, T serializableObject) async {
    var json = cv.jsonEncode(serializableObject);
    await updateWidget(valueName, json);
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
