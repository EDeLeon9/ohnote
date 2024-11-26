import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:ohnote/tools/scrollview_with_bar.dart';

class StyleColorPickerDialog {
  const StyleColorPickerDialog._();

  static Future<void> show({required BuildContext context, required Color? pickerColor, required void Function(Color value) onColorChanged}) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(8.0, 10.0, 8.0, 0.0),
          actionsPadding: const EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 15.0),
          content: ScrollViewWithBar(
            paddng: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Transform.translate(
              offset: const Offset(0.0, 10.0),
              child: SlidePicker(
                indicatorBorderRadius: const BorderRadius.all(Radius.circular(15.0)),
                sliderSize: Size(MediaQuery.of(context).size.width - 40.0, 40.0),
                indicatorSize: Size(MediaQuery.of(context).size.width - 40.0, 30.0),
                enableAlpha: false,
                colorModel: ColorModel.hsv,
                pickerColor: pickerColor ?? const Color(0xFFFF0000),
                onColorChanged: onColorChanged,
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('CLEAR COLOR'),
              onPressed: () {
                onColorChanged(Colors.transparent);
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text('CLOSE'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }
}
