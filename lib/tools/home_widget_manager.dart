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
  static final _singleAsync = a.SingleAsync();
  static void Function(String msg)? onError;

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

  static Future<T?> getWidgetData<T>(String valueName, T? defaultValue) async {
    return await HomeWidget.getWidgetData<T>(valueName, defaultValue: defaultValue);
  }

  //Note: Always update all the used values because _singleAsync will run the last requested function.
  static Future<void> updateWidget(Map<String, String> values) async {
    for (var value in values.entries) {
      var saved = await HomeWidget.saveWidgetData(value.key, value.value);
      if (saved != true) {
        onError?.call('Home widget data not saved: key: ${value.key}, value: ${value.value}');
      }
    }
    _singleAsync.runLast(300, () async {
      var saved = await HomeWidget.updateWidget(name: _androidWidgetName, androidName: _androidWidgetName, iOSName: _iOSWidgetName);
      if (saved != true) {
        onError?.call('Home widget not updated.');
      }
    });
  }

  static Future<void> updateWidgetWithSerializable(Map<String, Object> serializableObjects) async {
    var jsonValues = serializableObjects.map((key, value) => MapEntry(key, cv.jsonEncode(value)));
    await updateWidget(jsonValues);
  }

  static void setClickFunction(String widgetMessage, void Function(Map<String, String> params) function) {
    _clickedFunctions[widgetMessage] = function;
  }

  static Future<void Function()?> getFunctionIfLaunchedFromHomeWidget() async {
    var uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (uri != null && uri.scheme == _appSchemeName) {
      var function = _clickedFunctions[uri.host];
      if (function != null) {
        return () => function(uri.queryParameters);
      }
    }
    return null;
  }
}
