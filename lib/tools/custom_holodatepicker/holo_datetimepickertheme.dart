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
    super.dividerColor,
    this.topDividerPos,
    this.bottomDividerPos,
    this.dividerHeight,
    this.dividerThickness,
  }) : super();

  final double? topDividerPos;
  final double? bottomDividerPos;
  final double? dividerHeight;
  final double? dividerThickness;

  // ignore: constant_identifier_names
  static const HoloDateTimePickerTheme Default = HoloDateTimePickerTheme();
}
