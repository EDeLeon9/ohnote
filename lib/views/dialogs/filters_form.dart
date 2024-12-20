import 'package:flutter/material.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/data/filters.dart';
import 'package:ohnote/tools/custom_checkbox.dart';
import 'package:ohnote/tools/custom_holodatepicker/holo_datepicker.dart';
import 'package:ohnote/tools/landscape_textfield.dart';
import 'package:ohnote/view_components/colored_circle.dart';
import 'package:ohnote/constants.dart' as c;
import 'package:ohnote/view_components/label_container.dart';

class FiltersForm extends StatefulWidget {
  const FiltersForm({super.key, required this.filtersToEdit, required this.availableColors});

  final Filters filtersToEdit;
  final List<Color> availableColors;

  @override
  State<FiltersForm> createState() => _FiltersFormState();
}

class _FiltersFormState extends State<FiltersForm> {
  final _textController = TextEditingController();
  late DateTime _pickerMin, _pickerMax, _pickerFrom, _pickerTo;

  @override
  void initState() {
    _textController.text = widget.filtersToEdit.text;
    var now = DateTime.now();
    now = DateTime(now.year, now.month, now.day);
    _pickerFrom = now;
    _pickerTo = now;
    _pickerMin = DateTime(now.subtract(const Duration(days: 36500)).year);
    _pickerMax = DateTime(now.add(const Duration(days: 36500)).year, 12, 31);
    if (widget.filtersToEdit.from != null) {
      _pickerFrom = widget.filtersToEdit.from!;
      if (widget.filtersToEdit.from!.isBefore(_pickerMin)) {
        _pickerMin = widget.filtersToEdit.from!;
      }
    }
    if (widget.filtersToEdit.to != null) {
      _pickerTo = widget.filtersToEdit.to!;
      if (widget.filtersToEdit.to!.isAfter(_pickerMax)) {
        _pickerMax = widget.filtersToEdit.to!;
      }
    }
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _favorites(),
        c.defaultDivider,
        ListTile(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._from(),
              ..._to(),
            ],
          ),
        ),
        c.defaultDivider,
        _text(),
        c.defaultDivider,
        _label(),
        c.defaultDivider,
        _color(),
        c.defaultDivider,
        _crossedOut(),
      ],
    );
  }

  Widget _favorites() {
    return ListTile(
      title: const Text(Filters.FAVORITES),
      trailing: CustomCheckbox(
        checkboxVisualDensity: const VisualDensity(horizontal: -4.0, vertical: -4.0),
        value: () => widget.filtersToEdit.favorites,
        onChanged: (value) {
          widget.filtersToEdit.favorites = value;
        },
      ),
    );
  }

  List<Widget> _from() {
    return [
      Row(
        children: [
          const Expanded(child: Text('From')),
          CustomCheckbox(
            checkboxVisualDensity: const VisualDensity(horizontal: -4.0, vertical: -4.0),
            value: () => widget.filtersToEdit.from != null,
            onChanged: (value) {
              setState(() {
                widget.filtersToEdit.from = value ? _pickerFrom : null;
              });
            },
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.only(top: 5.0, bottom: 7.0),
        child: HoloDatePicker(
          initialDate: _pickerFrom,
          firstDate: _pickerMin,
          lastDate: _pickerMax,
          pickerTheme: _getDateTimePickerTheme(),
          isEnabled: widget.filtersToEdit.from != null,
          onChange: (dateTime, selectedIndex) {
            _pickerFrom = DateTime(dateTime.year, dateTime.month, dateTime.day);
            widget.filtersToEdit.from = _pickerFrom;
          },
        ),
      ),
    ];
  }

  List<Widget> _to() {
    return [
      Row(
        children: [
          const Expanded(child: Text('To')),
          CustomCheckbox(
            checkboxVisualDensity: const VisualDensity(horizontal: -4.0, vertical: -4.0),
            value: () => widget.filtersToEdit.to != null,
            onChanged: (value) {
              setState(() {
                widget.filtersToEdit.to = value ? _pickerTo : null;
              });
            },
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.only(top: 5.0, bottom: 9.0),
        child: HoloDatePicker(
          initialDate: _pickerTo,
          firstDate: _pickerMin,
          lastDate: _pickerMax,
          pickerTheme: _getDateTimePickerTheme(),
          isEnabled: widget.filtersToEdit.to != null,
          onChange: (dateTime, selectedIndex) {
            _pickerTo = DateTime(dateTime.year, dateTime.month, dateTime.day);
            widget.filtersToEdit.to = _pickerTo;
          },
        ),
      ),
    ];
  }

  Widget _text() {
    return ListTile(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(Filters.BY_TEXT),
          Padding(
            padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
            child: LandscapeTextField(
              controller: _textController,
              textFieldBuilder: (controller, focusNode, readOnly) {
                return TextField(
                  showCursor: true,
                  controller: controller,
                  focusNode: focusNode,
                  readOnly: readOnly,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    widget.filtersToEdit.text = value.trim();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _label() {
    return ListTile(
      title: const Text(Filters.BY_LABEL),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6.0),
        child: Wrap(
          spacing: 10.0,
          runSpacing: 10.0,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: AppData.labels.isNotEmpty
              ? [
                  ...AppData.labels.map((e) {
                    var selected = widget.filtersToEdit.labelIds.contains(e.id);
                    return LabelContainer(
                      color: selected ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
                      onTap: () {
                        setState(() {
                          if (selected) {
                            widget.filtersToEdit.labelIds.remove(e.id);
                          } else {
                            widget.filtersToEdit.labelIds.add(e.id);
                          }
                        });
                      },
                      content: Text(
                        e.text,
                        maxLines: 1,
                        style: TextStyle(
                          color: selected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.primary,
                          fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                        ),
                      ),
                    );
                  }),
                  FilterChip(
                    showCheckmark: false,
                    visualDensity: const VisualDensity(vertical: -2.0),
                    label: Text('Without label', style: Theme.of(context).textTheme.bodySmall),
                    selected: widget.filtersToEdit.labelIds.contains(0),
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          widget.filtersToEdit.labelIds.add(0);
                        } else {
                          widget.filtersToEdit.labelIds.remove(0);
                        }
                      });
                    },
                  ),
                ]
              : [Text('<No current labels>', style: Theme.of(context).textTheme.bodySmall)],
        ),
      ),
    );
  }

  Widget _color() {
    return ListTile(
      title: const Text(Filters.BY_COLOR),
      subtitle: Wrap(
        spacing: 3.0,
        runSpacing: -3.0,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: widget.availableColors.isNotEmpty
            ? [
                ...widget.availableColors.map((e) {
                  return ColoredCircle(
                    color: e,
                    diameter: 35.0,
                    margin: const EdgeInsets.all(8.0),
                    isSelectedIcon: widget.filtersToEdit.colors.contains(e),
                    onTap: () {
                      setState(() {
                        if (!widget.filtersToEdit.colors.contains(e)) {
                          widget.filtersToEdit.colors.add(e);
                        } else {
                          widget.filtersToEdit.colors.remove(e);
                        }
                      });
                    },
                  );
                }),
                FilterChip(
                  showCheckmark: false,
                  visualDensity: const VisualDensity(vertical: -2.0),
                  label: Text('Colorless', style: Theme.of(context).textTheme.bodySmall),
                  selected: widget.filtersToEdit.colors.contains(Colors.transparent),
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        widget.filtersToEdit.colors.add(Colors.transparent);
                      } else {
                        widget.filtersToEdit.colors.remove(Colors.transparent);
                      }
                    });
                  },
                ),
              ]
            : [Text('<No colors assigned in notes>', style: Theme.of(context).textTheme.bodySmall)],
      ),
    );
  }

  Widget _crossedOut() {
    return ListTile(
      title: const Text(Filters.CROSSED_OUT),
      trailing: CustomCheckbox(
        checkboxVisualDensity: const VisualDensity(horizontal: -4.0, vertical: -4.0),
        value: () => widget.filtersToEdit.crossedOut,
        onChanged: (value) {
          widget.filtersToEdit.crossedOut = value;
        },
      ),
    );
  }

  HoloDateTimePickerTheme _getDateTimePickerTheme() {
    return HoloDateTimePickerTheme(
      // topDividerPos: 5.0,
      // bottomDividerPos: 29.0,
      itemHeight: 22.0,
      pickerHeight: 50.0,
      backgroundColor: Colors.transparent,
      dividerColor: Theme.of(context).colorScheme.outlineVariant, //outlineVariant is used by Dividers.
      itemTextStyle: Theme.of(context).textTheme.bodyMedium!,
    );
  }
}
