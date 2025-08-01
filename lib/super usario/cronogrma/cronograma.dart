import 'dart:math';
import 'package:flutter/material.dart';
import 'package:login_app/super%20usario/cards/cards.dart';
import 'package:login_app/super%20usario/panel/panel_graficas.dart';
import 'package:login_app/super%20usario/tabla/home_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:login_app/services/api_service.dart';
import 'package:login_app/models/tarjeta.dart';

DateTime normalizeDate(DateTime date) {
  return DateTime.utc(date.year, date.month, date.day);
}

class PlannerScreen extends StatefulWidget {
  final String? processName;

  const PlannerScreen({super.key, this.processName});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final ApiService _apiService = ApiService();
  late Map<DateTime, List<Tarjeta>> _events;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final Map<String, Color> _memberColors = {};

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES');
    _selectedDay = normalizeDate(_focusedDay);
    _events = {};
    _loadEventsForProcess();
  }

  Future<void> _loadEventsForProcess() async {
    if (widget.processName == null) return;

    try {
      final List<Tarjeta> allCards = await _apiService.getCards(
        widget.processName!,
      );
      final Map<DateTime, List<Tarjeta>> eventsMap = {};

      for (final card in allCards) {
        if (card.fechaInicio != null) {
          final normalizedStartDay = normalizeDate(card.fechaInicio!);
          eventsMap.putIfAbsent(normalizedStartDay, () => []).add(card);
        }

        if (card.fechaVencimiento != null) {
          final normalizedEndDay = normalizeDate(card.fechaVencimiento!);
          if (!isSameDay(card.fechaInicio, card.fechaVencimiento)) {
            eventsMap.putIfAbsent(normalizedEndDay, () => []).add(card);
          }
        }
      }

      if (mounted) {
        setState(() {
          _events = eventsMap;
        });
      }
    } catch (e) {
      print("Error cargando eventos para el calendario: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar las tareas: ${e.toString()}'),
            backgroundColor: Colors.red[800],
          ),
        );
      }
    }
  }

  List<Tarjeta> _getEventsForDay(DateTime day) {
    return _events[normalizeDate(day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.red[800],
        elevation: 0,
        title: _buildHeader(),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => TableroScreen(processName: widget.processName,),
              ),
            );
          },
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.menu, color: Colors.white),
            onSelected: (String value) {
              if (value == 'cronograma') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlannerScreen(processName: widget.processName),
                  ),
                );
              } else if (value == 'panel') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PanelTrello(processName: widget.processName),
                  ),
                );
              } else if (value == 'tablas') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => KanbanTaskManager(processName: widget.processName),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'cronograma',
                child: Text('Cronograma'),
              ),
              const PopupMenuItem<String>(
                value: 'tablas',
                child: Text('Tablas'),
              ),
              const PopupMenuItem<String>(
                value: 'panel',
                child: Text('Panel'),
              ),
            ],
          ),
        ],
      ),
      body: TableCalendar<Tarjeta>(
        locale: 'es_ES',
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay)) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        headerVisible: false,
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: Colors.grey[800]),
          weekendStyle: TextStyle(color: Colors.grey[800]),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle: TextStyle(color: Colors.white),
          weekendTextStyle: TextStyle(color: Colors.white),
          todayTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          todayDecoration: BoxDecoration(
            color: Colors.red[700],
            shape: BoxShape.circle,
          ),
          selectedTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          selectedDecoration: BoxDecoration(
            color: Colors.red[600],
            shape: BoxShape.circle,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) => Container(),
          defaultBuilder: (context, date, events) => 
              _buildDayCell(date, _getEventsForDay(date)),
          todayBuilder: (context, date, events) => 
              _buildDayCell(date, _getEventsForDay(date), isToday: true),
          selectedBuilder: (context, date, events) => 
              _buildDayCell(date, _getEventsForDay(date), isSelected: true),
        ),
      ),
    );
  }

  Widget _buildDayCell(
    DateTime date,
    List<Tarjeta> events, {
    bool isToday = false,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: isToday ? Border.all(color: Colors.red[800]!, width: 1.5) : null,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6.0, left: 6.0),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: isSelected ? Colors.red[800] : Colors.grey[800],
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: events.isEmpty
                ? Container()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4.0,
                      vertical: 2.0,
                    ),
                    itemCount: events.length,
                    itemBuilder: (context, index) => 
                        _buildEventItem(events[index], date),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DateFormat.yMMMM('es_ES').format(_focusedDay),
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.chevron_left,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () => setState(
                () => _focusedDay = DateTime(
                  _focusedDay.year,
                  _focusedDay.month - 1,
                ),
              ),
            ),
            InkWell(
              onTap: () => setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = _focusedDay;
              }),
              child: Text(
                'Hoy',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () => setState(
                () => _focusedDay = DateTime(
                  _focusedDay.year,
                  _focusedDay.month + 1,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventItem(Tarjeta event, DateTime cellDate) {
    final bool isEndDate = event.fechaVencimiento != null &&
        isSameDay(cellDate, event.fechaVencimiento);
    int? delayDays;
    if (isEndDate &&
        event.estado == EstadoTarjeta.hecho &&
        event.fechaCompletado != null &&
        event.fechaVencimiento != null &&
        event.fechaCompletado!.isAfter(event.fechaVencimiento!)) {
      delayDays = event.fechaCompletado!.difference(event.fechaVencimiento!).inDays;
    }

    return InkWell(
      onTap: () => _showTaskDetailsDialog(event),
      borderRadius: BorderRadius.circular(4.0),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: _getTaskColor(event.estado, isEndDate),
              size: 14,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.titulo,
                    style: TextStyle(color: Colors.white, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (delayDays != null && delayDays > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        '+${delayDays} día(s) de retraso',
                        style: TextStyle(
                          color: Colors.red[300],
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (event.miembro.isNotEmpty) _buildAvatar(event.miembro),
          ],
        ),
      ),
    );
  }

  void _showTaskDetailsDialog(Tarjeta card) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            card.titulo,
            style: TextStyle(
              color: Colors.red[800],
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (card.descripcion.isNotEmpty) ...[
                  _buildDetailRow(
                    Icons.description,
                    "Descripción",
                    card.descripcion,
                  ),
                  Divider(color: Colors.grey[300]),
                ],
                _buildDetailRow(
                  Icons.person,
                  "Asignado a",
                  card.miembro.isNotEmpty ? card.miembro : "N/A",
                ),
                Divider(color: Colors.grey[300]),
                _buildDetailRow(
                  Icons.flag,
                  "Estado",
                  card.estado.toString().split('.').last.replaceAll('_', ' '),
                ),
                Divider(color: Colors.grey[300]),
                if (card.fechaInicio != null)
                  _buildDetailRow(
                    Icons.play_arrow,
                    "Fecha de Inicio",
                    DateFormat.yMMMMd('es_ES').format(card.fechaInicio!),
                  ),
                if (card.fechaVencimiento != null)
                  _buildDetailRow(
                    Icons.event_busy,
                    "Fecha de Vencimiento",
                    DateFormat.yMMMMd('es_ES').format(card.fechaVencimiento!),
                  ),
                if (card.fechaCompletado != null)
                  _buildDetailRow(
                    Icons.check_circle,
                    "Fecha de Finalización",
                    DateFormat.yMMMMd('es_ES').format(card.fechaCompletado!),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Cerrar",
                style: TextStyle(color: Colors.red[800]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.red[800], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String member) {
    final initials = member.length >= 2
        ? member.substring(0, 2).toUpperCase()
        : member.toUpperCase();
    if (!_memberColors.containsKey(member)) {
      final random = Random(member.hashCode);
      _memberColors[member] = Color.fromARGB(
        255,
        random.nextInt(150) + 50,
        random.nextInt(150) + 50,
        random.nextInt(150) + 50,
      );
    }
    return CircleAvatar(
      radius: 10,
      backgroundColor: _memberColors[member],
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getTaskColor(EstadoTarjeta estado, bool isEndDate) {
    if (isEndDate && estado == EstadoTarjeta.hecho) return Colors.green;
    switch (estado) {
      case EstadoTarjeta.hecho:
        return Colors.green.withOpacity(0.5);
      case EstadoTarjeta.en_progreso:
        return Colors.blue;
      case EstadoTarjeta.pendiente:
        return Colors.orange;
    }
  }
}