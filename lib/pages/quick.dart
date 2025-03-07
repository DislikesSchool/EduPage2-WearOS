import 'package:eduapge2/api.dart';
import 'package:eduapge2/l10n/app_localizations.dart';
import 'package:eduapge2/util.dart';
import 'package:flutter/material.dart';

class QuickInfo extends StatefulWidget {
  const QuickInfo({super.key, required context});

  @override
  State<QuickInfo> createState() => _QuickInfoState();
}

class _QuickInfoState extends State<QuickInfo> {
  AppLocalizations get local => AppLocalizations.of(context)!;
  EP2Data data = EP2Data.getInstance();

  TimeTablePeriod? currentPeriod() {
    return data.timetable.periods?.firstWhere(
      (element) {
        DateTime start = DateTimeExtension.parseTime(element.startTime);
        DateTime end = DateTimeExtension.parseTime(element.endTime);
        if (DateTime.now().isAfter(start) && DateTime.now().isBefore(end)) {
          return true;
        }
        return false;
      },
    );
  }

  TimeTablePeriod? nextPeriod() {
    return data.timetable.periods?.firstWhere(
      (element) {
        DateTime start = DateTimeExtension.parseTime(element.startTime);
        if (DateTime.now().isBefore(start)) {
          return true;
        }
        return false;
      },
    );
  }

  TimeTableClass currentClass() {
    // Take the current period, and try to find a class with this period.
    // If no class is found:
    //  - If the current period is before the first class, return the first class.
    //  - If the current period is after the last class, return the last class.

    TimeTablePeriod? period = currentPeriod();
    if (period == null) {
      TimeTableData day = data.timetable.timetables.entries.firstWhere((entry) {
        // If today's timetable has classes then today's timetable is the current timetable.
        // Otherwise return the first timetable after today's that also has classes.
        if (entry.key.isBefore(DateTime.now())) {
          return entry.value.classes.isNotEmpty;
        }
        return false;
      }).value;

      if (DateTime.now()
          .isBefore(DateTimeExtension.parseTime(day.periods.first.startTime))) {
        return day.classes.first;
      } else {
        return day.classes.last;
      }
    } else {
      return data.timetable.timetables.entries
          .firstWhere((entry) {
            DateTime today = DateTime.now();
            DateTime key = entry.key;
            return today.year == key.year &&
                today.month == key.month &&
                today.day == key.day;
          }, orElse: () {
            return data.timetable.timetables.entries.first;
          })
          .value
          .classes
          .firstWhere((element) {
            return int.parse(element.startPeriod!.id) <= int.parse(period.id) &&
                int.parse(period.id) <= int.parse(element.endPeriod!.id);
          }, orElse: () {
            return data.timetable.timetables.entries.first.value.classes.first;
          });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    TimeTableClass cc = currentClass();
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(cc.subject?.short ?? "?"),
              Text(cc.classrooms.first.short),
            ],
          ),
          SizedBox(width: 20),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  "${cc.startPeriod?.startTime ?? "?"} - ${cc.endPeriod?.endTime ?? "?"}"),
              Text(" "),
            ],
          ),
        ],
      ),
    );
  }
}
