import 'package:flutter/material.dart';

class CustomCheckbox extends StatefulWidget {
  const CustomCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.caption,
    this.width,
    this.backgroundColor,
    this.checkboxColor,
    this.padding,
    this.checkboxVisualDensity,
  });

  final Text? caption;
  final bool Function() value;
  final void Function(bool value) onChanged;
  final double? width;
  final Color? backgroundColor;
  final Color? checkboxColor;
  final EdgeInsets? padding;
  final VisualDensity? checkboxVisualDensity;

  @override
  State<CustomCheckbox> createState() => _CustomCheckboxState();
}

class _CustomCheckboxState extends State<CustomCheckbox> {
  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var themedCheckbox = Theme(
      data: Theme.of(context).copyWith(colorScheme: colorScheme.copyWith(onSurfaceVariant: widget.checkboxColor ?? colorScheme.primary)),
      child: Checkbox(
        visualDensity: widget.checkboxVisualDensity,
        value: widget.value(),
        onChanged: (value) {
          setState(() {
            widget.onChanged(value == true);
          });
        },
      ),
    );
    return Container(
      width: widget.width,
      color: widget.backgroundColor,
      padding: widget.padding,
      child: widget.caption != null
          ? Row(
              children: [
                themedCheckbox,
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        widget.onChanged(!widget.value());
                      });
                    },
                    child: widget.caption,
                  ),
                ),
              ],
            )
          : themedCheckbox,
    );
  }
}
