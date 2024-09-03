import 'package:flutter/material.dart';
import 'package:ohnote/data/app_data.dart';
import 'package:ohnote/data/filters.dart';
import 'package:ohnote/data/gui_manager.dart';
import 'package:ohnote/tools/custom_checkbox.dart';
import 'package:ohnote/tools/custom_holodatepicker/holo_datepicker.dart';
import 'package:ohnote/view_components/colored_circle.dart';
import 'package:ohnote/view_components/header_container.dart';
import 'package:ohnote/constants.dart' as c;

class FiltersDialog extends StatefulWidget {
  const FiltersDialog._(this.guiManager);

  final GuiManager guiManager;

  @override
  State<FiltersDialog> createState() => _FiltersDialogState();

  static Future<Filters?> show({required BuildContext context, required GuiManager guiManager}) {
    return showDialog<Filters>(
      context: context,
      builder: (context) {
        return FiltersDialog._(guiManager);
      },
    );
  }
}

class _FiltersDialogState extends State<FiltersDialog> {
  final _textController = TextEditingController();
  final Filters _filters = Filters();
  late DateTime _pickerMin, _pickerMax, _pickerFrom, _pickerTo;

  @override
  void initState() {
    _filters.copyFrom(widget.guiManager.filters.value);
    _textController.text = _filters.text;
    var now = DateTime.now();
    now = DateTime(now.year, now.month, now.day);
    _pickerFrom = now;
    _pickerTo = now;
    _pickerMin = DateTime(now.subtract(const Duration(days: 36500)).year);
    _pickerMax = DateTime(now.add(const Duration(days: 36500)).year, 12, 31);
    if (_filters.from != null) {
      _pickerFrom = _filters.from!;
      if (_filters.from!.isBefore(_pickerMin)) {
        _pickerMin = _filters.from!;
      }
    }
    if (_filters.to != null) {
      _pickerTo = _filters.to!;
      if (_filters.to!.isAfter(_pickerMax)) {
        _pickerMax = _filters.to!;
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
    var datePickerTheme = HoloDateTimePickerTheme(
      topDividerPos: 5.0,
      bottomDividerPos: 29.0,
      itemHeight: 22.0,
      pickerHeight: 50.0,
      backgroundColor: Colors.transparent,
      dividerColor: Theme.of(context).colorScheme.outlineVariant, //outlineVariant is used by Dividers.
      itemTextStyle: Theme.of(context).textTheme.bodyMedium!,
    );
    return AlertDialog(
      clipBehavior: Clip.antiAlias,
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15.0),
      title: HeaderContainer(
        child: Padding(
          padding: const EdgeInsets.only(left: 30.0, top: 18.0, bottom: 8.0),
          child: Text(
            'Filters',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: [
              _favorites(),
              c.defaultDivider,
              ListTile(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._from(datePickerTheme),
                    ..._to(datePickerTheme),
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
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, _filters);
          },
          child: const Text('APPLY'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _filters.getAppliedCaptions().isNotEmpty ? Filters() : null),
          child: const Text('CLEAR'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
      ],
    );
  }

  Widget _favorites() {
    return ListTile(
      title: const Text(Filters.FAVORITES),
      trailing: CustomCheckbox(
        checkboxVisualDensity: const VisualDensity(horizontal: -4.0, vertical: -4.0),
        value: () => _filters.favorites,
        onChanged: (value) {
          _filters.favorites = value;
        },
      ),
    );
  }

  List<Widget> _from(HoloDateTimePickerTheme datePickerTheme) {
    return [
      Row(
        children: [
          const Expanded(child: Text('From')),
          CustomCheckbox(
            checkboxVisualDensity: const VisualDensity(horizontal: -4.0, vertical: -4.0),
            value: () => _filters.from != null,
            onChanged: (value) {
              setState(() {
                _filters.from = value ? _pickerFrom : null;
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
          pickerTheme: datePickerTheme,
          isEnabled: _filters.from != null,
          onChange: (dateTime, selectedIndex) {
            _pickerFrom = DateTime(dateTime.year, dateTime.month, dateTime.day);
            _filters.from = _pickerFrom;
          },
        ),
      ),
    ];
  }

  List<Widget> _to(HoloDateTimePickerTheme datePickerTheme) {
    return [
      Row(
        children: [
          const Expanded(child: Text('To')),
          CustomCheckbox(
            checkboxVisualDensity: const VisualDensity(horizontal: -4.0, vertical: -4.0),
            value: () => _filters.to != null,
            onChanged: (value) {
              setState(() {
                _filters.to = value ? _pickerTo : null;
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
          pickerTheme: datePickerTheme,
          isEnabled: _filters.to != null,
          onChange: (dateTime, selectedIndex) {
            _pickerTo = DateTime(dateTime.year, dateTime.month, dateTime.day);
            _filters.to = _pickerTo;
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
            child: TextField(
              controller: _textController,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _filters.text = value.trim();
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
      subtitle: Wrap(
        runSpacing: -3.0,
        spacing: 8.0,
        children: AppData.labels.isNotEmpty
            ? AppData.labels.map((e) {
                return FilterChip(
                  showCheckmark: false,
                  visualDensity: const VisualDensity(vertical: -2.0),
                  label: Text(e.text, style: Theme.of(context).textTheme.bodySmall),
                  selected: _filters.labelIds.contains(e.id),
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _filters.labelIds.add(e.id);
                      } else {
                        _filters.labelIds.remove(e.id);
                      }
                    });
                  },
                );
              }).toList()
            : [Text('<No current labels>', style: Theme.of(context).textTheme.bodySmall)],
      ),
    );
  }

  Widget _color() {
    return ListTile(
      title: const Text(Filters.BY_COLOR),
      subtitle: Wrap(
        runSpacing: -3.0,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: widget.guiManager.styleColors.isNotEmpty
            ? [
                ...widget.guiManager.styleColors.map((e) {
                  return ColoredCircle(
                    color: e,
                    diameter: 35.0,
                    margin: const EdgeInsets.all(8.0),
                    isSelectedIcon: _filters.colors.contains(e),
                    onTap: () {
                      setState(() {
                        if (!_filters.colors.contains(e)) {
                          _filters.colors.add(e);
                        } else {
                          _filters.colors.remove(e);
                        }
                      });
                    },
                  );
                }),
                FilterChip(
                  showCheckmark: false,
                  visualDensity: const VisualDensity(vertical: -2.0),
                  label: Text('Colorless', style: Theme.of(context).textTheme.bodySmall),
                  selected: _filters.colors.contains(Colors.transparent),
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _filters.colors.add(Colors.transparent);
                      } else {
                        _filters.colors.remove(Colors.transparent);
                      }
                    });
                  },
                )
              ]
            : [Text('<No assigned colors>', style: Theme.of(context).textTheme.bodySmall)],
      ),
    );
  }

  Widget _crossedOut() {
    return ListTile(
      title: const Text(Filters.CROSSED_OUT),
      trailing: CustomCheckbox(
        checkboxVisualDensity: const VisualDensity(horizontal: -4.0, vertical: -4.0),
        value: () => _filters.crossedOut,
        onChanged: (value) {
          _filters.crossedOut = value;
        },
      ),
    );
  }
}
