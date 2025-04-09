
import 'package:intl/intl.dart';

String convertDateToString(DateTime date) {
  DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  String dateString = dateFormat.format(date);

  return dateString;
}
