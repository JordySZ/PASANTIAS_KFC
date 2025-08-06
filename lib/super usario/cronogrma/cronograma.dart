import 'dart:math';
import 'package:flutter/material.dart';
import 'package:login_app/super%20usario/cards/cards.dart';
import 'package:login_app/super%20usario/panel/panel_graficas.dart';
import 'package:login_app/super%20usario/tabla/home_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async'; // Añade este import para usar Timer
import 'package:login_app/services/api_service.dart';
import 'package:login_app/models/tarjeta.dart';

// Enum para gestionar los estados del filtro de forma clara.
enum StatusFilter { todos, hecho, en_progreso, pendiente }

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
  final Map<String, Color> _memberColors = {};
 late Timer _refreshTimer; // Timer para el refresco automático
  StatusFilter _selectedStatusFilter = StatusFilter.todos;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES');
    _selectedDay = normalizeDate(_focusedDay);
    _events = {};
    _loadEventsForProcess();
    
    // Configurar el timer para refrescar cada 10 segundos
    _refreshTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (mounted) {
        _loadEventsForProcess();
      }
    });
  }

  @override
  void dispose() {
    // Cancelar el timer cuando el widget se destruya para evitar fugas de memoria
    _refreshTimer.cancel();
    super.dispose();
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

  List<Tarjeta> _getFilteredEventsForDay(DateTime day) {
    final dailyEvents = _events[normalizeDate(day)] ?? [];
    if (_selectedStatusFilter == StatusFilter.todos) {
      return dailyEvents;
    }
    return dailyEvents.where((event) {
      switch (_selectedStatusFilter) {
        case StatusFilter.hecho:
          return event.estado == EstadoTarjeta.hecho;
        case StatusFilter.en_progreso:
          return event.estado == EstadoTarjeta.en_progreso;
        case StatusFilter.pendiente:
          return event.estado == EstadoTarjeta.pendiente;
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      color: Colors.red[800],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildChip(StatusFilter.todos, 'Todos'),
            _buildChip(StatusFilter.hecho, 'Hecho'),
            _buildChip(StatusFilter.en_progreso, 'En Proceso'),
            _buildChip(StatusFilter.pendiente, 'Pendiente'),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(StatusFilter filter, String label) {
    final bool isSelected = _selectedStatusFilter == filter;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          if (selected) {
            setState(() {
              _selectedStatusFilter = filter;
            });
          }
        },
        backgroundColor: Colors.red[700],
        selectedColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.red[900] : Colors.white70,
          fontWeight: FontWeight.bold,
        ),
        checkmarkColor: Colors.red[900],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        toolbarHeight: 90,
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
                builder: (_) => TableroScreen(processName: widget.processName),
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
                    builder:
                        (context) =>
                            PlannerScreen(processName: widget.processName),
                  ),
                );
              } else if (value == 'panel') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            PanelTrello(processName: widget.processName),
                  ),
                );
              } else if (value == 'tablas') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            KanbanTaskManager(processName: widget.processName),
                  ),
                );
              }
            },
            itemBuilder:
                (BuildContext context) => [
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
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: _buildFilterChips(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar<Tarjeta>(
      
          locale: 'es_ES',
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          rowHeight: 70.0,
          eventLoader: _getFilteredEventsForDay,
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
            setState(() {
              _focusedDay = focusedDay;
            });
          },
          headerVisible: false,
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.bold,
            ),
            weekendStyle: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.bold,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) => Container(),
            defaultBuilder:
                (context, date, _) =>
                    _buildDayCell(date, _getFilteredEventsForDay(date)),
            todayBuilder:
                (context, date, _) => _buildDayCell(
                  date,
                  _getFilteredEventsForDay(date),
                  isToday: true,
                ),
            selectedBuilder:
                (context, date, _) => _buildDayCell(
                  date,
                  _getFilteredEventsForDay(date),
                  isSelected: true,
                ),
            outsideBuilder:
                (context, date, _) => Container(
                  margin: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
          ),
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
      margin: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: isSelected ? Colors.red.withOpacity(0.1) : Colors.white,
        border:
            isToday ? Border.all(color: Colors.red[800]!, width: 2.0) : null,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 8.0),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: isSelected ? Colors.red[800] : Colors.grey[800],
                  fontSize: 14,
                  fontWeight:
                      isToday || isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                ),
              ),
            ),
          ),
          Expanded(
            child:
                events.isEmpty
                    ? Container()
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4.0,
                        vertical: 2.0,
                      ),
                      itemCount: events.length,
                      itemBuilder:
                          (context, index) =>
                              _buildEventItem(events[index], date),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,

      // MODIFICACIÓN 1: Cambiamos la alineación a 'center'
      crossAxisAlignment: CrossAxisAlignment.center,

      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '"Pequeños progresos suman grandes resultados."',

            // MODIFICACIÓN 2: Añadimos la alineación del texto
            textAlign: TextAlign.center,

            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(height: 8),

        Row(
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
                  icon: Icon(Icons.chevron_left, color: Colors.white, size: 28),
                  onPressed:
                      () => setState(
                        () =>
                            _focusedDay = DateTime(
                              _focusedDay.year,
                              _focusedDay.month - 1,
                            ),
                      ),
                ),
                InkWell(
                  onTap:
                      () => setState(() {
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
                  onPressed:
                      () => setState(
                        () =>
                            _focusedDay = DateTime(
                              _focusedDay.year,
                              _focusedDay.month + 1,
                            ),
                      ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventItem(Tarjeta event, DateTime cellDate) {
    final bool isEndDate =
        event.fechaVencimiento != null &&
        isSameDay(cellDate, event.fechaVencimiento);
    int? delayDays;
    if (isEndDate &&
        event.estado == EstadoTarjeta.hecho &&
        event.fechaCompletado != null &&
        event.fechaVencimiento != null &&
        event.fechaCompletado!.isAfter(event.fechaVencimiento!)) {
      delayDays =
          event.fechaCompletado!.difference(event.fechaVencimiento!).inDays;
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
              Icons.circle,
              color: _getTaskColor(event.estado, isEndDate),
              size: 10,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.titulo,
                    style: TextStyle(color: Colors.white, fontSize: 12),
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
              child: Text("Cerrar", style: TextStyle(color: Colors.red[800])),
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
    final initials =
        member.length >= 2
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
        return Colors.green.withOpacity(0.7);
      case EstadoTarjeta.en_progreso:
        return Colors.blue;
      case EstadoTarjeta.pendiente:
        return Colors.orange;
    }
  }
}
