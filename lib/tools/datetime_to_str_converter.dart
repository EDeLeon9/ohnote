import 'package:intl/intl.dart';

enum DTToStrFormat {
  DATABASE, // ignore: constant_identifier_names
  LOCAL, // ignore: constant_identifier_names
}

extension DateTimeToStr on DateTime {
  String parseToStr(DTToStrFormat format) {
    if (format == DTToStrFormat.DATABASE) {
      return DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(this);
    } else {
      return DateFormat.yMMMd().add_jm().format(this);
    }
  }
}
