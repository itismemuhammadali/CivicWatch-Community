import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class HorizontalGraphList extends StatefulWidget {
  const HorizontalGraphList({super.key});

  @override
  State<HorizontalGraphList> createState() => _HorizontalGraphListState();
}

class _HorizontalGraphListState extends State<HorizontalGraphList> {
  int selectedIndex = 0;

  // Sample data for the graph
  final List<_ChartData> chartData = [
    _ChartData('Dec 8', 412),
    _ChartData('Dec 15', 1330),
    _ChartData('Dec 22', 4370),
    _ChartData('Dec 29', 16330),
    _ChartData('Jan 6', 25660),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: kWhiteColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kGreyColor),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = 0;
                    });
                  },
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: selectedIndex == 0 ? kPrimaryColor : kWhiteColor,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: selectedIndex == 0
                            ? kTransparentColor
                            : kGreyColor,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    child: Text(
                      "Daily",
                      style: TextStyle(
                        fontSize: 12,
                        color: selectedIndex == 0 ? kWhiteColor : kBlackColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
              Space.horizontal(14),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = 1;
                    });
                  },
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: selectedIndex == 1 ? kPrimaryColor : kWhiteColor,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: selectedIndex == 1
                            ? kTransparentColor
                            : kGreyColor,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    child: Text(
                      "Weekly",
                      style: TextStyle(
                        fontSize: 12,
                        color: selectedIndex == 1 ? kWhiteColor : kBlackColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
              Space.horizontal(14),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = 2;
                    });
                  },
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: selectedIndex == 2 ? kPrimaryColor : kWhiteColor,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: selectedIndex == 2
                            ? kTransparentColor
                            : kGreyColor,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    child: Text(
                      "Monthly",
                      style: TextStyle(
                        fontSize: 12,
                        color: selectedIndex == 2 ? kWhiteColor : kBlackColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
              Space.horizontal(14),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = 3;
                    });
                  },
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: selectedIndex == 3 ? kPrimaryColor : kWhiteColor,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: selectedIndex == 3
                            ? kTransparentColor
                            : kGreyColor,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    child: Text(
                      "Year",
                      style: TextStyle(
                        fontSize: 12,
                        color: selectedIndex == 3 ? kWhiteColor : kBlackColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Space.vertical(16),
        // Syncfusion Graph
        Container(
          decoration: BoxDecoration(
            color: kWhiteColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kGreyColor),
          ),
          padding: EdgeInsets.all(16),
          child: SfCartesianChart(
            primaryXAxis: CategoryAxis(),
            primaryYAxis: NumericAxis(
              labelAlignment: LabelAlignment.end,
              opposedPosition: true,
              majorGridLines: MajorGridLines(width: 0),
            ),
            series: <CartesianSeries<_ChartData, String>>[
              AreaSeries<_ChartData, String>(
                dataSource: chartData,
                xValueMapper: (data, _) => data.x,
                yValueMapper: (data, _) => data.y,
                gradient: LinearGradient(
                  colors: [Colors.blue.shade300, Colors.blue.shade700],
                  stops: [0.0, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChartData {
  final String x;
  final int y;

  _ChartData(this.x, this.y);
}
