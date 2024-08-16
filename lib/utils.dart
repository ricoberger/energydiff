import 'package:health/health.dart';
import 'package:intl/intl.dart';

enum HistoryScope {
  week,
  month,
  sixmonths,
  year,
}

extension HistoryScopeExtension on HistoryScope {
  String toLocalizedString() {
    switch (this) {
      case HistoryScope.week:
        return 'Week';
      case HistoryScope.month:
        return 'Month';
      case HistoryScope.sixmonths:
        return '6 Months';
      case HistoryScope.year:
        return 'Year';
    }
  }

  int toInterval() {
    switch (this) {
      case HistoryScope.week:
        return 3600 * 24;
      case HistoryScope.month:
        return 3600 * 24;
      case HistoryScope.sixmonths:
        return 3600 * 24 * 7;
      case HistoryScope.year:
        return 3600 * 24 * 30;
    }
  }

  double barWidth() {
    switch (this) {
      case HistoryScope.week:
        return 40;
      case HistoryScope.month:
        return 9;
      case HistoryScope.sixmonths:
        return 10;
      case HistoryScope.year:
        return 20;
    }
  }

  List<DateTime> getStartEndDate(DateTime now) {
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (this) {
      case HistoryScope.week:
        return [end.subtract(const Duration(days: 7)), end];
      case HistoryScope.month:
        return [end.subtract(const Duration(days: 30)), end];
      case HistoryScope.sixmonths:
        return [end.subtract(const Duration(days: 30 * 6)), end];
      case HistoryScope.year:
        return [end.subtract(const Duration(days: 30 * 12)), end];
    }
  }

  String formatDateTime(DateTime dateTime) {
    switch (this) {
      case HistoryScope.week:
        return DateFormat('dd.MM.yyyy').format(dateTime);
      case HistoryScope.month:
        return DateFormat('dd.MM.yyyy').format(dateTime);
      case HistoryScope.sixmonths:
        return '${DateFormat('dd.MM').format(dateTime.subtract(Duration(seconds: (toInterval() - 1))))} to ${DateFormat('dd.MM').format(dateTime)}';
      case HistoryScope.year:
        return '${DateFormat('dd.MM').format(dateTime.subtract(Duration(seconds: (toInterval() - 1))))} to ${DateFormat('dd.MM').format(dateTime)}';
    }
  }
}

int getData(List<HealthDataPoint> data, HealthDataType type) {
  final tmpData = data
      .where((element) => element.type == type)
      .map((e) => formatHealthDataPointValue(e));
  return tmpData.isEmpty
      ? 0
      : tmpData.reduce((value, element) => value + element);
}

int formatHealthDataPointValue(HealthDataPoint dataPoint) {
  return dataPoint.value.toJson()['numeric_value'].round();
}

List<DateTime> getIntervals(List<HealthDataPoint> data) {
  final intervals = <DateTime>[];

  for (var dataPoint in data) {
    if (!intervals.contains(dataPoint.dateTo)) {
      intervals.add(dataPoint.dateTo);
    }
  }

  intervals.sort((a, b) {
    return a.compareTo(b);
  });

  return intervals;
}

int getDataForInterval(
  List<HealthDataPoint> data,
  DateTime interval,
  HealthDataType type,
) {
  final tmpData = data
      .where((element) => element.type == type && element.dateTo == interval)
      .map((e) => formatHealthDataPointValue(e));
  return tmpData.isEmpty
      ? 0
      : tmpData.reduce((value, element) => value + element);
}
