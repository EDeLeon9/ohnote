import 'package:flutter/material.dart';
import 'package:ohnote/data/app_theme.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/data/home_widget_config.dart';
import 'package:ohnote/tools/scrollview_with_bar.dart';
import 'package:ohnote/tools/landscape_textfield.dart';
import 'package:ohnote/tools/option_tiles.dart';
import 'package:ohnote/views/dialogs/filters_form.dart';
import 'package:ohnote/view_components/header_container.dart';
import 'package:ohnote/tools/custom_toast.dart' as t;
import 'package:ohnote/constants.dart' as c;

class HomeWidgetConfigDialog extends StatefulWidget {
  const HomeWidgetConfigDialog._(this.homeWidgetConfig);

  final HomeWidgetConfig? homeWidgetConfig;

  @override
  State<HomeWidgetConfigDialog> createState() => _HomeWidgetConfigDialogState();

  static Future<HomeWidgetConfig?> show({required BuildContext context, HomeWidgetConfig? homeWidgetConfig}) {
    return showDialog<HomeWidgetConfig>(
      context: context,
      builder: (context) {
        return HomeWidgetConfigDialog._(homeWidgetConfig);
      },
    );
  }
}

class _HomeWidgetConfigDialogState extends State<HomeWidgetConfigDialog> {
  late final HomeWidgetConfig _homeWidgetConfigResult;
  final _titleController = TextEditingController();
  final _opacityController = TextEditingController();
  final _themeFocusNode = FocusNode();

  @override
  void initState() {
    if (widget.homeWidgetConfig != null) {
      var copy = HomeWidgetConfig(id: widget.homeWidgetConfig!.id);
      copy.copyFrom(widget.homeWidgetConfig!);
      _homeWidgetConfigResult = copy;
    } else {
      _homeWidgetConfigResult = HomeWidgetConfig(id: 0);
    }
    AppData.notesManager.updateStyleColors();
    _titleController.text = _homeWidgetConfigResult.title;
    _opacityController.text = _homeWidgetConfigResult.opacity.toString();
    super.initState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      clipBehavior: Clip.antiAlias,
      titlePadding: EdgeInsets.zero,
      insetPadding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
      contentPadding: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 10.0),
      title: HeaderContainer(
        child: Padding(
          padding: const EdgeInsets.only(left: 30.0, top: 18.0, bottom: 8.0),
          child: Text(
            '${widget.homeWidgetConfig == null ? 'New' : 'Edit'} Configuration',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ),
      content: ScrollViewWithBar(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: [
              const SizedBox(height: 5.0),
              _title(),
              c.defaultDivider,
              _theme(),
              c.defaultDivider,
              _opacity(),
              c.defaultDivider,
              //TODO: Filters header (sin curvatura obvio).
              FiltersForm(
                filtersToEdit: _homeWidgetConfigResult.notesManager.filters.value,
                availableColors: AppData.notesManager.styleColors,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _homeWidgetConfigResult.title = _homeWidgetConfigResult.title.trim();
            if (_homeWidgetConfigResult.title.isEmpty) {
              t.showCustomToast('Please set a title for the configuration.', context);
            } else if (_opacityController.text.trim().isEmpty) {
              //TODO: fix custom toast to center screen
              t.showCustomToast('Please set a valid opacity for the configuration.', context);
            } else {
              Navigator.pop(context, _homeWidgetConfigResult);
            }
          },
          child: const Text('SAVE'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
      ],
    );
  }

  Widget _title() {
    return ListTile(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Widget title'),
          Padding(
            padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
            child: LandscapeTextField(
              controller: _titleController,
              textFieldBuilder: (controller, focusNode, readOnly) {
                return TextField(
                  showCursor: true,
                  controller: controller,
                  focusNode: focusNode,
                  readOnly: readOnly,
                  maxLength: 30,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _homeWidgetConfigResult.title = value;
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _theme() {
    return Focus(
      focusNode: _themeFocusNode,
      child: ListTile(
        title: const Text('Theme'),
        subtitle: Text(_homeWidgetConfigResult.theme.caption),
        onTap: () {
          _themeFocusNode.requestFocus();
          showDialog<String>(
            context: context,
            builder: (context) {
              return SimpleDialog(
                children: OptionTiles.build(context: context, options: {
                  AppThemeBrightness.systemDefault.caption: Icons.brightness_6,
                  AppThemeBrightness.light.caption: Icons.light_mode,
                  AppThemeBrightness.dark.caption: Icons.dark_mode,
                }),
              );
            },
          ).then((value) {
            if (value != null) {
              setState(() {
                _homeWidgetConfigResult.theme = AppThemeBrightness.values.firstWhere((e) => e.caption == value);
              });
            }
          });
        },
      ),
    );
  }

  Widget _opacity() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Text('Opacity'),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('${_homeWidgetConfigResult.opacity}%'),
          ),
          Slider(
            min: 0.0,
            max: 100.0,
            divisions: 20,
            value: _homeWidgetConfigResult.opacity.toDouble(),
            onChanged: (value) {
              setState(() {
                _homeWidgetConfigResult.opacity = value.round();
              });
            },
          ),
          // LandscapeTextField(
          //   controller: _opacityController,
          //   textFieldBuilder: (controller, focusNode, readOnly) {
          //     return TextField(
          //       showCursor: true,
          //       controller: controller,
          //       focusNode: focusNode,
          //       readOnly: readOnly,
          //       keyboardType: TextInputType.number,
          //       style: Theme.of(context).textTheme.bodyMedium,
          //       inputFormatters: [
          //         FilteringTextInputFormatter.digitsOnly,
          //         LengthLimitingTextInputFormatter(3),
          //       ],
          //       decoration: const InputDecoration(
          //         isDense: true,
          //         contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          //         border: OutlineInputBorder(),
          //       ),
          //       onChanged: (value) {
          //         var number = int.tryParse(value);
          //         if (number == null) {
          //           number = 0;
          //           controller.text = '';
          //         } else if (number < 0) {
          //           number = 0;
          //           controller.text = '0';
          //         } else if (number > 100) {
          //           number = 100;
          //           controller.text = '100';
          //         }
          //         _homeWidgetConfigResult.opacity = number;
          //       },
          //     );
          //   },
          // ),
        ],
      ),
    );
  }
}
