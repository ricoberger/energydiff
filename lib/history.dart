import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';

import 'package:energydiff/utils.dart';

class HistoryData {
  DateTime interval;
  int activeEnergyBurned;
  int basalEnergyBurned;
  int dietaryEnergyConsumed;

  HistoryData({
    required this.interval,
    required this.activeEnergyBurned,
    required this.basalEnergyBurned,
    required this.dietaryEnergyConsumed,
  });
}

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  final _now = DateTime.now();
  HistoryBarChartType _barChartType = HistoryBarChartType.difference;
  HistoryScope _scope = HistoryScope.week;
  late Future<List<HistoryData>> _futureFetchData;

  Future<List<HistoryData>> _fetchData() async {
    await Health().requestAuthorization(
      [
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.BASAL_ENERGY_BURNED,
        HealthDataType.DIETARY_ENERGY_CONSUMED,
      ],
      permissions: [
        HealthDataAccess.READ,
        HealthDataAccess.READ,
        HealthDataAccess.READ,
      ],
    );

    final startEndData = _scope.getStartEndDate(_now);
    final interval = _scope.toInterval();

    final data = await Health().getHealthIntervalDataFromTypes(
      startDate: startEndData[0],
      endDate: startEndData[1],
      types: [
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.BASAL_ENERGY_BURNED,
        HealthDataType.DIETARY_ENERGY_CONSUMED,
      ],
      interval: interval,
    );

    final intervals = getIntervals(data);

    return intervals
        .map(
          (interval) => HistoryData(
            interval: interval,
            activeEnergyBurned: getDataForInterval(
              data,
              interval,
              HealthDataType.ACTIVE_ENERGY_BURNED,
            ),
            basalEnergyBurned: getDataForInterval(
              data,
              interval,
              HealthDataType.BASAL_ENERGY_BURNED,
            ),
            dietaryEnergyConsumed: getDataForInterval(
              data,
              interval,
              HealthDataType.DIETARY_ENERGY_CONSUMED,
            ),
          ),
        )
        .toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    setState(() {
      _futureFetchData = _fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        color: const Color(0xff1b2738),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 8,
                    ),
                    child: Icon(
                      Icons.calendar_month,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'History',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton(
                    initialValue: _barChartType,
                    onSelected: (value) {
                      setState(() {
                        _barChartType = value;
                      });
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: HistoryBarChartType.burned,
                        child: Text(
                          HistoryBarChartType.burned.toLocalizedString(),
                        ),
                      ),
                      PopupMenuItem(
                        value: HistoryBarChartType.consumed,
                        child: Text(
                          HistoryBarChartType.consumed.toLocalizedString(),
                        ),
                      ),
                      PopupMenuItem(
                        value: HistoryBarChartType.difference,
                        child: Text(
                          HistoryBarChartType.difference.toLocalizedString(),
                        ),
                      ),
                    ],
                    child: Text(
                      _barChartType.toLocalizedString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    ' | ',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PopupMenuButton(
                    initialValue: _scope,
                    onSelected: (value) {
                      setState(() {
                        _scope = value;
                        _futureFetchData = _fetchData();
                      });
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: HistoryScope.week,
                        child: Text(HistoryScope.week.toLocalizedString()),
                      ),
                      PopupMenuItem(
                        value: HistoryScope.month,
                        child: Text(HistoryScope.month.toLocalizedString()),
                      ),
                      PopupMenuItem(
                        value: HistoryScope.sixmonths,
                        child: Text(HistoryScope.sixmonths.toLocalizedString()),
                      ),
                      PopupMenuItem(
                        value: HistoryScope.year,
                        child: Text(HistoryScope.year.toLocalizedString()),
                      ),
                    ],
                    child: Text(
                      _scope.toLocalizedString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FutureBuilder(
                future: _futureFetchData,
                builder: (
                  BuildContext context,
                  AsyncSnapshot<List<HistoryData>> snapshot,
                ) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                    case ConnectionState.waiting:
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                            ),
                            child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      );
                    default:
                      if (snapshot.hasError) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                ),
                                child: Text(
                                  snapshot.error.toString(),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      if (snapshot.data == null || snapshot.data!.isEmpty) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                ),
                                child: Text(
                                  'No data available.',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          SizedBox(
                            height: 320,
                            width: double.infinity,
                            child: BarChart(
                              BarChartData(
                                barGroups: List.generate(snapshot.data!.length,
                                    (index) {
                                  return BarChartGroupData(
                                    x: index,
                                    barRods: [
                                      BarChartRodData(
                                        toY: _barChartType ==
                                                HistoryBarChartType.burned
                                            ? (snapshot.data![index]
                                                        .activeEnergyBurned +
                                                    snapshot.data![index]
                                                        .basalEnergyBurned)
                                                .toDouble()
                                            : _barChartType ==
                                                    HistoryBarChartType.consumed
                                                ? (snapshot.data![index]
                                                        .dietaryEnergyConsumed)
                                                    .toDouble()
                                                : (snapshot.data![index]
                                                            .activeEnergyBurned +
                                                        snapshot.data![index]
                                                            .basalEnergyBurned -
                                                        snapshot.data![index]
                                                            .dietaryEnergyConsumed)
                                                    .toDouble(),
                                        color: _barChartType ==
                                                HistoryBarChartType.burned
                                            ? const Color(0xfff9104f)
                                            : _barChartType ==
                                                    HistoryBarChartType.consumed
                                                ? const Color(0xffa7fe01)
                                                : const Color(0xff00fff7),
                                        width: _scope.barWidth(),
                                        borderRadius: const BorderRadius.all(
                                          Radius.zero,
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                                barTouchData: BarTouchData(
                                  touchTooltipData: BarTouchTooltipData(
                                    tooltipPadding: const EdgeInsets.all(8),
                                    fitInsideHorizontally: true,
                                    fitInsideVertically: true,
                                    getTooltipColor: (BarChartGroupData group) {
                                      return Theme.of(context)
                                          .colorScheme
                                          .primary;
                                    },
                                    getTooltipItem:
                                        (group, groupIndex, rod, rodIndex) {
                                      return BarTooltipItem(
                                        '${_scope.formatDateTime(snapshot.data![group.x.toInt()].interval)}\n',
                                        TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                          fontWeight: FontWeight.normal,
                                          fontSize: 12,
                                        ),
                                        children: [
                                          TextSpan(
                                            text:
                                                'Burned: ${snapshot.data![group.x.toInt()].activeEnergyBurned + snapshot.data![group.x.toInt()].basalEnergyBurned}\n',
                                            style: const TextStyle(
                                              color: Color(0xfff9104f),
                                              fontSize: 12,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                          TextSpan(
                                            text:
                                                'Consumed: ${snapshot.data![group.x.toInt()].dietaryEnergyConsumed}\n',
                                            style: const TextStyle(
                                              color: Color(0xffa7fe01),
                                              fontSize: 12,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                          TextSpan(
                                            text:
                                                'Difference: ${snapshot.data![group.x.toInt()].activeEnergyBurned + snapshot.data![group.x.toInt()].basalEnergyBurned - snapshot.data![group.x.toInt()].dietaryEnergyConsumed}',
                                            style: const TextStyle(
                                              color: Color(0xff00fff7),
                                              fontSize: 12,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: false,
                                    ),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: false,
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 32,
                                      getTitlesWidget: (value, titleMeta) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 16),
                                          child: Text(
                                            NumberFormat.compact()
                                                .format(value.toInt()),
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
                                              fontSize: 10,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  bottomTitles: const AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: false,
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                gridData: FlGridData(
                                  show: true,
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      strokeWidth: 0.4,
                                      dashArray: [8, 4],
                                    );
                                  },
                                  getDrawingVerticalLine: (value) {
                                    return FlLine(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      strokeWidth: 0.4,
                                      dashArray: [8, 4],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Table(
                            columnWidths: const {
                              0: FlexColumnWidth(),
                              1: FlexColumnWidth(),
                              2: FlexColumnWidth(),
                              3: FlexColumnWidth(),
                            },
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.middle,
                            children: [
                              const TableRow(
                                children: [
                                  TableCell(
                                    child: Text(
                                      'Date',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  TableCell(
                                    child: Text(
                                      'Burned',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  TableCell(
                                    child: Text(
                                      'Consumed',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  TableCell(
                                    child: Text(
                                      'Difference',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                              ...List<TableRow>.generate(
                                snapshot.data!.length,
                                (index) {
                                  return TableRow(
                                    children: [
                                      TableCell(
                                        child: Text(
                                          _scope.formatDateTime(
                                            snapshot.data![index].interval,
                                          ),
                                          maxLines: 1,
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      TableCell(
                                        child: Tooltip(
                                          message:
                                              'Active Energy: ${snapshot.data![index].activeEnergyBurned} kcal\nBasal Energy: ${snapshot.data![index].basalEnergyBurned} kcal',
                                          child: Text(
                                            '${snapshot.data![index].activeEnergyBurned + snapshot.data![index].basalEnergyBurned}',
                                            style: const TextStyle(
                                              color: Color(0xfff9104f),
                                              fontSize: 12,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      TableCell(
                                        child: Tooltip(
                                          message:
                                              'Dietary Energy: ${snapshot.data![index].dietaryEnergyConsumed} kcal',
                                          child: Text(
                                            '${snapshot.data![index].dietaryEnergyConsumed}',
                                            style: const TextStyle(
                                              color: Color(0xffa7fe01),
                                              fontSize: 12,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      TableCell(
                                        child: Tooltip(
                                          message:
                                              'Difference: ${snapshot.data![index].activeEnergyBurned + snapshot.data![index].basalEnergyBurned - snapshot.data![index].dietaryEnergyConsumed} kcal',
                                          child: Text(
                                            '${snapshot.data![index].activeEnergyBurned + snapshot.data![index].basalEnergyBurned - snapshot.data![index].dietaryEnergyConsumed}',
                                            style: const TextStyle(
                                              color: Color(0xff00fff7),
                                              fontSize: 12,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
