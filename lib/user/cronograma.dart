import 'package:flutter/material.dart';

import 'package:login_app/user/models/task.dart';
import 'package:login_app/user/widgets/timeline_painter.dart';
import 'package:login_app/user/widgets/timeline_header_painter.dart';



class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final List<Task> tasks = Task.getExampleTasks();

  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  final double pixelsPerDay = 100.0;
  final double rowHeight = 60.0;
  final double taskNameColumnWidth = 200.0;

  late DateTime _minDate;
  late DateTime _maxDate;
  late int _totalDays;

  @override
  void initState() {
    super.initState();
    _calculateDateRange();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  void _calculateDateRange() {
    if (tasks.isEmpty) {
      _minDate = DateTime.now().subtract(const Duration(days: 7));
      _maxDate = DateTime.now().add(const Duration(days: 14));
    } else {
      _minDate =
          tasks.map((t) => t.startDate).reduce((a, b) => a.isBefore(b) ? a : b);
      _maxDate =
          tasks.map((t) => t.endDate).reduce((a, b) => a.isAfter(b) ? a : b);
      _minDate = _minDate.subtract(const Duration(days: 5));
      _maxDate = _maxDate.add(const Duration(days: 15));
    }
    _minDate = DateTime(_minDate.year, _minDate.month, _minDate.day);
    _maxDate = DateTime(_maxDate.year, _maxDate.month, _maxDate.day);
    _totalDays = _maxDate.difference(_minDate).inDays;
  }

  void _scrollToToday() {
    final today = DateTime.now();
    final daysFromMinDate = today.difference(_minDate).inDays.toDouble();
    final offset = daysFromMinDate * pixelsPerDay;
    if (_horizontalScrollController.hasClients) {
      _horizontalScrollController.jumpTo(
        offset -
            MediaQuery.of(context).size.width / 2 +
            taskNameColumnWidth / 2,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double totalCanvasWidth = _totalDays * pixelsPerDay;
    final double contentHeight = tasks.length * rowHeight;

    final double dateHeaderHeight = 40.0;
    final double totalScrollableHeight = dateHeaderHeight + contentHeight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cronograma Amigable',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold)), // Estilo para el título
        actions: [
          IconButton(
            icon: const Icon(Icons.today, color: Color.fromARGB(255, 245, 8, 8)), // Icono blanco
            onPressed: _scrollToToday,
            tooltip: 'Ir a hoy',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.lightBlue.shade100, // Fondo más suave
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(15.0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                height: dateHeaderHeight,
                child: Row(
                  children: [
                    Container(
                      width: taskNameColumnWidth,
                      decoration: BoxDecoration(
                        color: Colors.lightBlue
                            .shade200, // Color de fondo más distintivo
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(15.0)),
                        border: Border(
                            right: BorderSide(
                                color: Colors.lightBlue.shade300!, width: 1.0)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Actividades',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: SizedBox(
                          width: totalCanvasWidth + pixelsPerDay,
                          height: dateHeaderHeight,
                          child: CustomPaint(
                            painter: TimelineHeaderPainter(
                              // Usando el nuevo pintor
                              minDate: _minDate,
                              totalDays: _totalDays,
                              pixelsPerDay: pixelsPerDay,
                              dateHeaderHeight: dateHeaderHeight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: taskNameColumnWidth,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(15.0)),
                        border: Border(
                            right: BorderSide(
                                color: Colors.grey.shade200!, width: 1.0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        controller: _verticalScrollController,
                        itemCount: tasks.length,
                        itemExtent: rowHeight,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return Container(
                            height: rowHeight,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                    color: Colors.grey.shade100, width: 1.0),
                              ),
                            ),
                            child: Text(
                              task.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          controller: _verticalScrollController,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white, // Fondo del cronograma
                              borderRadius: const BorderRadius.only(
                                  bottomRight: Radius.circular(15.0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: totalCanvasWidth + pixelsPerDay,
                              height: contentHeight,
                              child: CustomPaint(
                                painter: TimelinePainter(
                                  tasks: tasks,
                                  minDate: _minDate,
                                  totalDays: _totalDays,
                                  pixelsPerDay: pixelsPerDay,
                                  rowHeight: rowHeight,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
