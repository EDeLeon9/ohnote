import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/data/app_theme.dart';
import 'package:ohnote/data/settings.dart';
import 'package:ohnote/tools/landscape_textfield.dart';
import 'package:ohnote/views/main_page/main_scaffold.dart';
import 'package:ohnote/tools/custom_showcase.dart';
import 'package:ohnote/tools/custom_modalbottomsheet.dart';
import 'package:ohnote/tools/home_widget_manager.dart';

//TODO: OhNote Bugs y Pendientes
//Homescreen widget.
//cambiar com.example.ohnote a com.<empresa>.ohnote, esto seguro requiere hacer backup antes de desinstalar e instalar
//Revisar redacción de showcases con google Translate y verificar largo de los textos y tamaño de las boquitas.
//Anuncios.
//Solicitar Rate us.
//Autenticación google para guardar base de datos (como sería en iPhone? tambien google?).
//About page (investigar que se debe o que se recomienda poner ahí).
//Ver si no es complicado de implementar, sino puede esperar: Error handling (enviar errores a desarrollador).
//---------------Puede esperar:
//Idioma español.
//Opciones para hacer share (por ejemplo enviar por correo o copiar al portapapeles).
//Importar, exportar
//Deslizar a la izquierda o derecha para cambiar de nota cuando se está en modo edición

void main() {
  WidgetsFlutterBinding.ensureInitialized(); //Required by HomeWidgetManager and AppData.
  HomeWidgetManager.initialize(
    appSchemeName: 'ohnotewidget',
    appGroupId: 'ohnotewidgets',
    androidWidgetName: 'OhNoteWidget',
    iOSWidgetName: 'OhNoteWidget',
    runEnsureInitialized: false,
  );
  AppData.initData(runEnsureInitialized: false);
  runApp(const OhNoteApp());
}

class OhNoteApp extends StatelessWidget {
  const OhNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    var appTheme = AppTheme();
    return ValueListenableBuilder(
      valueListenable: AppData.settings[Settings.theme]!,
      builder: (context, theme, child) {
        return MaterialApp(
          title: 'OhNote',
          theme: appTheme.lightTheme,
          darkTheme: appTheme.darkTheme,
          themeMode: theme == AppThemeBrightness.light.caption
              ? ThemeMode.light
              : (theme == AppThemeBrightness.dark.caption ? ThemeMode.dark : ThemeMode.system),
          home: const MainScaffold(),
          builder: (context, child) {
            LandscapeTextField.inputDecoration = InputDecoration(
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Theme.of(context).colorScheme.tertiaryContainer,
            );
            return FToastBuilder().call(
              context,
              CustomShowCaseWidget(
                shownMap: AppData.firstAccesses,
                onFinish: (shownKeyValues) {
                  AppData.updateDbShownFirstAccesses(shownKeyValues, true);
                },
                child: CustomModalBottomSheetListener(
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
