// ignore_for_file: constant_identifier_names

import 'package:ohnote/tools/custom_holodatepicker/holo_datepicker.dart';

class HoloDateTimePickerTheme extends DateTimePickerTheme {
  const HoloDateTimePickerTheme({
    super.backgroundColor = DATETIME_PICKER_BACKGROUND_COLOR,
    super.cancelTextStyle,
    super.confirmTextStyle,
    super.cancel,
    super.confirm,
    super.title,
    super.showTitle = DATETIME_PICKER_SHOW_TITLE_DEFAULT,
    super.pickerHeight = DATETIME_PICKER_HEIGHT,
    super.titleHeight = DATETIME_PICKER_TITLE_HEIGHT,
    super.itemHeight = DATETIME_PICKER_ITEM_HEIGHT,
    super.itemTextStyle = DATETIME_PICKER_ITEM_TEXT_STYLE,
    super.dividerHeight = DATETIME_PICKER_DIVIDER_HEIGHT,
    super.dividerThickness = DATETIME_PICKER_DIVIDER_THICKNESS,
    super.dividerSpacing,
    super.dividerColor,
    super.squeeze = DATETIME_PICKER_SQUEEZE,
    super.diameterRatio = DATETIME_PICKER_DIAMETER_RATIO,
    this.topDividerPos,
    this.bottomDividerPos,
  }) : super();

  final double? topDividerPos;
  final double? bottomDividerPos;

  static const HoloDateTimePickerTheme Default = HoloDateTimePickerTheme();
}
