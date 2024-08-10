import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class TimezoneService {
  static void initialize() {
    tz.initializeTimeZones();
    // Set the local location to Bangkok, Thailand
    final String timeZoneName = 'Asia/Bangkok';
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  static tz.TZDateTime convertToTZDateTime(DateTime dateTime) {
    final tz.TZDateTime tzDateTime = tz.TZDateTime.from(dateTime, tz.local);
    return tzDateTime;
  }
}
