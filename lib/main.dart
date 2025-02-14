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

//Main branch test 2
//Branch test 4

//TODO: OhNote Bugs y Pendientes
//Anuncios.
//Solicitar Rate us.
//---------------Puede esperar:
//Autenticación google para guardar base de datos (como sería en iPhone? tambien google?).
//Capturar errores de base de datos con try catch y enviar errores periódicamente a desarrollador.
//Idioma español.
//Opciones para hacer share de nota (por ejemplo enviar por correo o copiar al portapapeles).
//Importar, exportar notas
//Arreglar íconos para iOS generados con "dart run flutter_launcher_icons"
//Revisar los "TODO" en Search

//Reminder:
//Android Widget base files created with Android Studio (right click in android/app -> New -> Widget -> App Widget)
//App icons created with flutter_launcher_icons package, and then with Android Studio (right click in android/app/res -> New -> Image Asset)

void main() {
  WidgetsFlutterBinding.ensureInitialized(); //Required by HomeWidgetManager and AppData.
  HomeWidgetManager.initialize(
    appSchemeName: 'ohnotewidget',
    appGroupId: 'ohnotewidgets',
    androidWidgetName: 'OhNoteWidget',
    iOSWidgetName: 'OhNoteWidget',
    runEnsureInitialized: false,
  );
  AppData.initData(runEnsureInitialized: false); //WidgetsFlutterBinding.ensureInitialized() already run.
  runApp(const OhNoteApp());
}

class OhNoteApp extends StatelessWidget {
  const OhNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AppData.settings[Settings.theme]!,
      builder: (context, theme, child) {
        return MaterialApp(
          title: 'OhNote',
          theme: AppTheme.current.lightTheme,
          darkTheme: AppTheme.current.darkTheme,
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
