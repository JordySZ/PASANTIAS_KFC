// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:login_app/user/cronogrma.dart';
class Tarjeta {
  String titulo;
  String miembro;
  String tarea;
  String tiempo;
  DateTime? fechaInicio;
  DateTime? fechaVencimiento;
  String recordatorio;
  bool completado; // Nuevo campo para estado completado

  Tarjeta({
    required this.titulo,
    this.miembro = '',
    this.tarea = '',
    this.tiempo = '',
    this.fechaInicio,
    this.fechaVencimiento,
    this.recordatorio = '',
    this.completado = false,
  });
}

class TableroScreen extends StatefulWidget {
  @override
  State<TableroScreen> createState() => _TableroScreenState();
}

class _TableroScreenState extends State<TableroScreen> {
  List<String> listas = ['Lista de tareas', 'En proceso', 'Hecho'];
  List<List<Tarjeta>> tarjetasPorLista = [[], [], []];
  List<GlobalKey> keysAgregarTarjeta = [];
  int? indiceListaEditandoTarjeta;

  @override
  void initState() {
    super.initState();
    keysAgregarTarjeta = List.generate(listas.length, (_) => GlobalKey());
  }

  void agregarListaNueva() {
    setState(() {
      listas.add('Nueva lista');
      tarjetasPorLista.add([]);
      keysAgregarTarjeta.add(GlobalKey());
    });
  }

  void editarTituloLista(int index, String nuevoTitulo) {
    setState(() {
      listas[index] = nuevoTitulo;
    });
  }

  void agregarTarjeta(int indexLista, Tarjeta tarjeta) {
    setState(() {
      tarjetasPorLista[indexLista].add(tarjeta);
      indiceListaEditandoTarjeta = null;
    });
  }

  void mostrarCampoNuevaTarjeta(int indexLista) {
    setState(() {
      indiceListaEditandoTarjeta = indexLista;
    });
  }

  void ocultarEdicion() {
    if (indiceListaEditandoTarjeta != null) {
      setState(() {
        indiceListaEditandoTarjeta = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003C6C),
       appBar: AppBar(
        title: const Text('Mi Tablero Trello'),
        backgroundColor: Colors.black87,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.menu),
            onSelected: (String value) {
              if (value == 'cronograma') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyApp()),
                );
              }
              // Aquí puedes agregar navegación para 'tablas' y 'panel' cuando lo necesites
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'cronograma',
                child: Text('Cronograma'),
              ),
              PopupMenuItem<String>(
                value: 'tablas',
                child: Text('Tablas'),
              ),
              PopupMenuItem<String>(
                value: 'panel',
                child: Text('Panel'),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: ocultarEdicion,
            child: Container(color: Colors.transparent),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < listas.length; i++)
                  ListaTrello(
                    key: ValueKey(i),
                    indexLista: i,
                    titulo: listas[i],
                    tarjetas: tarjetasPorLista[i],
                    onTituloEditado: (nuevoTitulo) => editarTituloLista(i, nuevoTitulo),
                    onAgregarTarjeta: (tarjeta) => agregarTarjeta(i, tarjeta),
                    agregandoTarjeta: indiceListaEditandoTarjeta == i,
                    mostrarCampoNuevaTarjeta: () => mostrarCampoNuevaTarjeta(i),
                    keyAgregarTarjeta: keysAgregarTarjeta[i],
                    onToggleCompletado: (indexTarjeta) {
                      setState(() {
                        final tarjeta = tarjetasPorLista[i][indexTarjeta];
                        tarjeta.completado = !tarjeta.completado;
                      });
                    },
                  ),
                BotonAgregarLista(onAgregar: agregarListaNueva),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ListaTrello extends StatefulWidget {
  final int indexLista;
  final String titulo;
  final List<Tarjeta> tarjetas;
  final ValueChanged<String> onTituloEditado;
  final ValueChanged<Tarjeta> onAgregarTarjeta;
  final bool agregandoTarjeta;
  final VoidCallback mostrarCampoNuevaTarjeta;
  final GlobalKey keyAgregarTarjeta;
  final Function(int indexTarjeta) onToggleCompletado;

  const ListaTrello({
    super.key,
    required this.indexLista,
    required this.titulo,
    required this.tarjetas,
    required this.onTituloEditado,
    required this.onAgregarTarjeta,
    required this.agregandoTarjeta,
    required this.mostrarCampoNuevaTarjeta,
    required this.keyAgregarTarjeta,
    required this.onToggleCompletado,
  });

  @override
  State<ListaTrello> createState() => _ListaTrelloState();
}

class _ListaTrelloState extends State<ListaTrello> {
  Set<int> tarjetasEnHover = {};
  late bool editandoTitulo;
  late TextEditingController _controllerTitulo;
  late FocusNode _focusNodeTitulo;
  final TextEditingController _controllerNuevaTarjeta = TextEditingController();
  final FocusNode _focusNodeNuevaTarjeta = FocusNode();

  String formatearRangoFechas(DateTime inicio, DateTime fin) {
    String formatearFecha(DateTime fecha) {
      final meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
      return '${fecha.day} ${meses[fecha.month - 1]}';
    }

    return '${formatearFecha(inicio)} - ${formatearFecha(fin)}';
  }

  Color obtenerColorFecha(DateTime fechaVencimiento, bool completado) {
    if (completado) return Colors.green; // Verde si completado
    final hoy = DateTime.now();
    final venc = DateTime(fechaVencimiento.year, fechaVencimiento.month, fechaVencimiento.day);
    final diferencia = venc.difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;
    if (diferencia < 0) return Colors.red;
    if (diferencia == 1 || diferencia == 0) return Colors.amber;
    return Colors.white70;
  }

  @override
  void initState() {
    super.initState();
    editandoTitulo = false;
    _controllerTitulo = TextEditingController(text: widget.titulo);
    _focusNodeTitulo = FocusNode();
    _focusNodeTitulo.addListener(() {
      if (!_focusNodeTitulo.hasFocus && editandoTitulo) {
        guardarTitulo();
      }
    });
  }

  @override
  void dispose() {
    _controllerTitulo.dispose();
    _focusNodeTitulo.dispose();
    _controllerNuevaTarjeta.dispose();
    _focusNodeNuevaTarjeta.dispose();
    super.dispose();
  }

  void guardarTitulo() {
    setState(() {
      editandoTitulo = false;
      widget.onTituloEditado(_controllerTitulo.text.trim());
      _focusNodeTitulo.unfocus();
    });
  }

  void activarEdicionTitulo() {
    setState(() {
      editandoTitulo = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodeTitulo.requestFocus();
      _controllerTitulo.selection = TextSelection(baseOffset: 0, extentOffset: _controllerTitulo.text.length);
    });
  }

  void agregarTarjeta() {
    final texto = _controllerNuevaTarjeta.text.trim();
    if (texto.isEmpty) return;
    widget.onAgregarTarjeta(Tarjeta(titulo: texto));
    _controllerNuevaTarjeta.clear();
    _focusNodeNuevaTarjeta.unfocus();
  }

  void mostrarModalTarjeta(int indexTarjeta) {
    Tarjeta tarjeta = widget.tarjetas[indexTarjeta];
    final miembroController = TextEditingController(text: tarjeta.miembro);
    final tiempoController = TextEditingController(text: tarjeta.tiempo);
    final recordatorioController = TextEditingController(text: tarjeta.recordatorio);
    DateTime? fechaInicio = tarjeta.fechaInicio;
    DateTime? fechaVencimiento = tarjeta.fechaVencimiento;
    final List<Widget> mensajesAlert = [];

    if (fechaVencimiento != null) {
      final hoy = DateTime.now();
      final venc = DateTime(fechaVencimiento.year, fechaVencimiento.month, fechaVencimiento.day);
      final diff = venc.difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;
      if (diff < 0) {
        mensajesAlert.add(const Text("⚠️ Plazo vencido", style: TextStyle(color: Colors.red)));
      } else if (diff == 1 || diff == 0) {
        mensajesAlert.add(const Text("⚠️ Vence pronto", style: TextStyle(color: Colors.amber)));
      }
    }

    if (tarjeta.completado) {
      mensajesAlert.add(const Text("✅ Cumplido", style: TextStyle(color: Colors.green)));
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateModal) {
          return AlertDialog(
            backgroundColor: Colors.black87,
            title: Text(tarjeta.titulo, style: const TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...mensajesAlert,
                  SizedBox(height: 8),
                  buildTextField("👤 Miembro", miembroController),
                  buildTextField("⏱ Tiempo estimado", tiempoController),
                  buildTextField("🔔 Recordatorio", recordatorioController),
                  buildDatePicker("📅 Fecha de inicio", (picked) => setStateModal(() => fechaInicio = picked), fechaInicio),
                  buildDatePicker("⏳ Fecha de vencimiento", (picked) => setStateModal(() => fechaVencimiento = picked), fechaVencimiento),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancelar", style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    tarjeta.miembro = miembroController.text;
                    tarjeta.tiempo = tiempoController.text;
                    tarjeta.recordatorio = recordatorioController.text;
                    tarjeta.fechaInicio = fechaInicio;
                    tarjeta.fechaVencimiento = fechaVencimiento;
                  });
                  Navigator.of(context).pop();
                },
                child: const Text("Guardar"),
              )
            ],
          );
        });
      },
    );
  }

  Widget buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
        ),
      ),
    );
  }

  Widget buildDatePicker(String label, Function(DateTime) onDatePicked, DateTime? fechaActual) {
    return Row(
      children: [
        Expanded(
          child: Text(
            "$label: ${fechaActual != null ? fechaActual.toLocal().toString().split(' ')[0] : 'No seleccionada'}",
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        TextButton(
          onPressed: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: fechaActual ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (pickedDate != null) onDatePicked(pickedDate);
          },
          child: const Text("Elegir", style: TextStyle(color: Colors.blueAccent)),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          editandoTitulo
              ? TextField(
                  controller: _controllerTitulo,
                  focusNode: _focusNodeTitulo,
                  autofocus: true,
                  onSubmitted: (_) => guardarTitulo(),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(border: InputBorder.none),
                )
              : GestureDetector(
                  onTap: activarEdicionTitulo,
                  child: Text(
                    widget.titulo,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
          const SizedBox(height: 10),
         ...widget.tarjetas.asMap().entries.map((entry) {
  final index = entry.key;
  final tarjeta = entry.value;
  final enHover = tarjetasEnHover.contains(index);

  return MouseRegion(
    onEnter: (_) => setState(() => tarjetasEnHover.add(index)),
    onExit: (_) => setState(() => tarjetasEnHover.remove(index)),
    child: GestureDetector(
      onTap: () => mostrarModalTarjeta(index),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(6),
          border: enHover
              ? Border.all(color: Colors.white, width: 2)
              : Border.all(color: Colors.transparent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: enHover || tarjeta.completado ? 24 : 0, // Mostrar círculo si está en hover o completado
      height: 24,
      margin: const EdgeInsets.only(right: 8, top: 2),
      child: (enHover || tarjeta.completado)
          ? GestureDetector(
              onTap: () {
                widget.onToggleCompletado(index);
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white),
                  color: tarjeta.completado ? Colors.green : Colors.transparent,
                ),
                child: tarjeta.completado
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            )
          : null,
    ),
    Expanded(
      child: Text(
        tarjeta.titulo,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        softWrap: true,
        maxLines: null,
        overflow: TextOverflow.visible,
      ),
    ),
  ],
),
            if (tarjeta.miembro.isNotEmpty)
              Text("👤 ${tarjeta.miembro}",
                  style: const TextStyle(color: Colors.white70)),
            if (tarjeta.tiempo.isNotEmpty)
              Text("⏱ ${tarjeta.tiempo}",
                  style: const TextStyle(color: Colors.white70)),
            if (tarjeta.fechaInicio != null &&
                tarjeta.fechaVencimiento != null)
              Text(
                "📅 ${formatearRangoFechas(tarjeta.fechaInicio!, tarjeta.fechaVencimiento!)}",
                style: TextStyle(
                  color: obtenerColorFecha(
                      tarjeta.fechaVencimiento!, tarjeta.completado),
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}),


          const SizedBox(height: 5),
          widget.agregandoTarjeta
              ? Container(
                  key: widget.keyAgregarTarjeta,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[700],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _controllerNuevaTarjeta,
                        focusNode: _focusNodeNuevaTarjeta,
                        autofocus: true,
                        onSubmitted: (_) => agregarTarjeta(),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Título de la tarjeta',
                          hintStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton(
                          onPressed: agregarTarjeta,
                          child: const Text('Guardar', style: TextStyle(color: Colors.white)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white70),
                          ),
                        ),
                      )
                    ],
                  ),
                )
              : TextButton.icon(
                  onPressed: widget.mostrarCampoNuevaTarjeta,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Añadir', style: TextStyle(color: Colors.white)),
                )
        ],
      ),
    );
  }
}

class BotonAgregarLista extends StatelessWidget {
  final VoidCallback onAgregar;
  const BotonAgregarLista({super.key, required this.onAgregar});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.all(10),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: onAgregar,
        icon: const Icon(Icons.add),
        label: const Text('Otra lista'),
      ),
    );
  }
}
