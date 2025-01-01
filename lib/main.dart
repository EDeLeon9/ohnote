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
//Opción para borrar directamente y no enviar a Trash can (colocar en Trash can page y Settings).
//Mejorar ícono con transparencia (se ve una rayita arriba del lápiz al abrir la app).
//Hacer el preview para mostrar cuando se va a agregar Homescreen widget, actualmente muestra el widget vacío (creo que tiene que usarse el android:previewImage en vez de android:previewLayout en ohnote_widget_info.xml).
//cambiar com.example.ohnote a com.<empresa>.ohnote, esto seguro requiere hacer backup antes de desinstalar e instalar
//Revisar redacción de showcases con google Translate y verificar largo de los textos y tamaño de las boquitas.
//Probar en emuladores de android con v21 y v31 (por valores de app widget)
//Anuncios.
//Solicitar Rate us.
//Autenticación google para guardar base de datos (como sería en iPhone? tambien google?).
//About page (investigar que se debe o que se recomienda poner ahí).
//Ver si no es complicado de implementar, sino puede esperar: Error handling (enviar errores periódicamente a desarrollador).
//Verificar si hay cambios en nested_scroll_view.dart para flutter_nestedscrollview.dart y date_picker.dart del paquete flutter_holo_date_picker para HoloDatePicker
//---------------Puede esperar:
//Capturar errores de base de datos con try catch
//Idioma español.
//Opciones para hacer share de nota (por ejemplo enviar por correo o copiar al portapapeles).
//Importar, exportar data (bd)

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
