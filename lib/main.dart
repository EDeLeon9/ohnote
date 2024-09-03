import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/data/app_theme.dart';
import 'package:ohnote/data/settings.dart';
import 'package:ohnote/views/main_page/main_scaffold.dart';
import 'package:ohnote/tools/custom_showcase.dart';
import 'package:ohnote/tools/custom_modalbottomsheet.dart';
import 'package:ohnote/tools/home_widget_manager.dart';

//TODO: OhNote Bugs y Pendientes
//Solicitar guardar nota en db justo escribir/modificar algo (usar SingleAsync no global) (cancelar al salir de Edit Note) y probar cuando se minimiza, cuando abre el selector de apps, cuando se bloquea el celular y cuando se cierra la app antes de guardar.
//Paneles con sombra en Dark mode no se aprecian (e.g. Style panel), pero lo que no se aprecia en light mode pero si en dark mode será poner esos paneles en otra tonalidad.
//En Dark mode aclarar los encabezados y oscurecer los textos de los controles desactivados (por ejemplo en los filtros de From y To).
//En Dark mode revisar colores de labels, al hacer tap no se aprecia.
//Sort by (y para Trash can y Archive) (y guardar Sort usado en db) (recordar deshabilitar reordering).
//Homescreen widget.
//Anuncios.
//Solicitar Rate us.
//Autenticación google para guardar base de datos (como sería en iPhone? tambien google?).
//Verificar texto grande desde el teléfono, Dark mode, en horizontal (que no haya overflow), y en Dark mode con horizontal.
//Revisar redacción de showcases con google Translate y verificar largo de los textos y tamaño de las boquitas.
//About page (investigar que se debe o que se recomienda poner ahí).
//Ver si no es complicado de implementar, sino puede esperar: Error handling (enviar errores a desarrollador).
//---------------Puede esperar:
//Idioma español.
//Opciones para hacer share (por ejemplo enviar por correo o copiar al portapapeles).
//Importar, exportar

void main() {
  WidgetsFlutterBinding.ensureInitialized(); //Required by HomeWidgetManager and AppData.
  HomeWidgetManager.initialize(
    appSchemeName: 'ohnotewidget',
    widgetProviderName: 'OhNoteWidgetProvider',
    iOSWidgetProviderName: 'OhNoteWidgetProvider',
    widgetDataName: '_widgetNotes',
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
    //This wraps MaterialApp instead being in home property because is being used FToastBuilder() as builder.
    return CustomShowCaseWidget(
      shownMap: AppData.firstAccesses,
      onFinish: (shownKeyValues) {
        AppData.updateDbShownFirstAccesses(shownKeyValues, true);
      },
      //This wraps MaterialApp instead being in home property because is being used FToastBuilder() as builder.
      child: CustomModalBottomSheetListener(
        child: ValueListenableBuilder(
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
              builder: FToastBuilder(),
            );
          },
        ),
      ),
    );
  }
}
