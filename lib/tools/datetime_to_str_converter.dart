import 'package:intl/intl.dart';

enum DTToStrFormat {
  DATABASE, // ignore: constant_identifier_names
  LOCALE, // ignore: constant_identifier_names
}

extension DateTimeToStr on DateTime {
  String toStr(DTToStrFormat format) {
    if (format == DTToStrFormat.DATABASE) {
      return DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(this);
    } else {
      return DateFormat.yMMMd().add_jms().format(this);
    }
  }

  String dateToStr(DTToStrFormat format) {
    if (format == DTToStrFormat.DATABASE) {
      return DateFormat('yyyy-MM-dd').format(this);
    } else {
      return DateFormat.yMMMd().format(this);
    }
  }

  String timeToStr(DTToStrFormat format) {
    if (format == DTToStrFormat.DATABASE) {
      return DateFormat('HH:mm:ss.SSS').format(this);
    } else {
      return DateFormat.jms().format(this);
    }
  }
}
