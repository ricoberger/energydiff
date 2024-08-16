import 'package:flutter/material.dart';

import 'package:health/health.dart';
import 'package:intl/intl.dart';

import 'package:energydiff/utils.dart';

class Today extends StatefulWidget {
  const Today({super.key});

  @override
  State<Today> createState() => _TodayState();
}

class _TodayState extends State<Today> {
  final _now = DateTime.now();
  late Future<List<HealthDataPoint>> _futureFetchData;

  Future<List<HealthDataPoint>> _fetchData() async {
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

    final data = await Health().getHealthDataFromTypes(
      startTime: DateTime(_now.year, _now.month, _now.day, 0, 0, 0),
      endTime: DateTime(_now.year, _now.month, _now.day, 23, 59, 59),
      types: [
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.BASAL_ENERGY_BURNED,
        HealthDataType.DIETARY_ENERGY_CONSUMED,
      ],
    );

    return data;
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
                      Icons.today,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Today',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('dd.MM.yyyy').format(
                      DateTime.now(),
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FutureBuilder(
                future: _futureFetchData,
                builder: (
                  BuildContext context,
                  AsyncSnapshot<List<HealthDataPoint>> snapshot,
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

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Burned',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${getData(snapshot.data!, HealthDataType.ACTIVE_ENERGY_BURNED) + getData(snapshot.data!, HealthDataType.BASAL_ENERGY_BURNED)} kcal',
                                style: const TextStyle(
                                  color: Color(0xfff9104f),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Consumed',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${getData(snapshot.data!, HealthDataType.DIETARY_ENERGY_CONSUMED)} kcal',
                                style: const TextStyle(
                                  color: Color(0xffa7fe01),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Difference',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${getData(snapshot.data!, HealthDataType.ACTIVE_ENERGY_BURNED) + getData(snapshot.data!, HealthDataType.BASAL_ENERGY_BURNED) - getData(snapshot.data!, HealthDataType.DIETARY_ENERGY_CONSUMED)} kcal',
                                style: const TextStyle(
                                  color: Color(0xff00fff7),
                                  fontWeight: FontWeight.bold,
                                ),
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
