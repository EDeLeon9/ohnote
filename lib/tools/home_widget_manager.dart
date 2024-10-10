import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:ohnote/tools/single_async.dart' as a;
import 'dart:convert' as cv;

final _clickedFunctions = <String, void Function(Map<String, String>)>{};

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
    HomeWidget.setAppGroupId(appGroupId); //This is needed for iOS Apps to talk to their WidgetExtensions.
    //HomeWidget.widgetClicked.listen is not executed in very low android APIs.
    HomeWidget.widgetClicked.listen((Uri? uri) {
      if (uri != null && uri.scheme == _appSchemeName && _clickedFunctions.containsKey(uri.host)) {
        _clickedFunctions[uri.host]!(uri.queryParameters);
      }
    });
  }

  static Future<T?> getWidgetData<T>(String valueName, T? defaultValue) {
    return HomeWidget.getWidgetData<T>(valueName, defaultValue: defaultValue);
  }

  static Future<void> updateWidget(String valueName, String value) async {
    await HomeWidget.saveWidgetData(valueName, value);
    a.runLast(300, () async {
      await HomeWidget.updateWidget(name: _androidWidgetName, androidName: _androidWidgetName, iOSName: _iOSWidgetName);
    });
  }

  static Future<void> updateWidgetWithSerializable<T>(String valueName, T serializableObject) async {
    var json = cv.jsonEncode(serializableObject);
    await updateWidget(valueName, json);
  }

  static void setClickFunction(String widgetMessage, void Function(Map<String, String> params) function) {
    _clickedFunctions[widgetMessage] = function;
  }

  static Future<void Function()?> getFunctionIfLaunchedFromHomeWidget(String widgetMessage) async {
    var uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (uri != null && uri.scheme == _appSchemeName && _clickedFunctions.containsKey(uri.host) && uri.host == widgetMessage) {
      return () => _clickedFunctions[widgetMessage]!(uri.queryParameters);
    }
    return null;
  }
}
