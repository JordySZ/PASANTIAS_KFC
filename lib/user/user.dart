// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:login_app/user/cronograma.dart';
import 'package:login_app/user/panel/panel_graficas.dart';
import 'package:login_app/user/tabla/home_screen.dart';

enum EstadoTarjeta { hecho, enProceso, porHacer }

class Tarjeta {
  String titulo;
  String miembro;
  String tarea;
  String tiempo;
  DateTime? fechaInicio;
  DateTime? fechaVencimiento;
  EstadoTarjeta estado; // Nuevo campo para el estado

  Tarjeta({
    required this.titulo,
    this.miembro = '',
    this.tarea = '',
    this.tiempo = '',
    this.fechaInicio,
    this.fechaVencimiento,
    this.estado = EstadoTarjeta.porHacer, // Valor por defecto
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
        backgroundColor: const Color.fromARGB(221, 62, 60, 60),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.menu),
            onSelected: (String value) {
              if (value == 'cronograma') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TimelineScreen()),
                );
              } else if (value == 'panel') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PanelTrello()),
                );
              } else if (value == 'tablas') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => KanbanTaskManager()),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'cronograma',
                child: Text('Cronograma'),
              ),
              PopupMenuItem<String>(value: 'tablas', child: Text('Tablas')),
              PopupMenuItem<String>(value: 'panel', child: Text('Panel')),
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
                    onTituloEditado: (nuevoTitulo) =>
                        editarTituloLista(i, nuevoTitulo),
                    onAgregarTarjeta: (tarjeta) => agregarTarjeta(i, tarjeta),
                    agregandoTarjeta: indiceListaEditandoTarjeta == i,
                    mostrarCampoNuevaTarjeta: () => mostrarCampoNuevaTarjeta(i),
                    keyAgregarTarjeta: keysAgregarTarjeta[i],
                    onEstadoChanged: (indexTarjeta, newEstado) {
                      setState(() {
                        tarjetasPorLista[i][indexTarjeta].estado = newEstado;
                      });
                    },
                    onTarjetaActualizada: (indexLista, indexTarjeta, tarjetaActualizada) {
                      setState(() {
                        tarjetasPorLista[indexLista][indexTarjeta] = tarjetaActualizada;
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
  final Function(int indexTarjeta, EstadoTarjeta newEstado) onEstadoChanged;
  final Function(int indexLista, int indexTarjeta, Tarjeta tarjetaActualizada) onTarjetaActualizada;

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
    required this.onEstadoChanged,
    required this.onTarjetaActualizada,
  });

  @override
  State<ListaTrello> createState() => _ListaTrelloState();
}

class _ListaTrelloState extends State<ListaTrello> {
  Set<int> tarjetasEnHover = {};
  late bool editandoTituloLista;
  late TextEditingController _controllerTituloLista;
  late FocusNode _focusNodeTituloLista;
  final TextEditingController _controllerNuevaTarjeta = TextEditingController();
  final FocusNode _focusNodeNuevaTarjeta = FocusNode();

  String formatearRangoFechas(DateTime inicio, DateTime fin) {
    String formatearFecha(DateTime fecha) {
      final meses = [
        'ene',
        'feb',
        'mar',
        'abr',
        'may',
        'jun',
        'jul',
        'ago',
        'sep',
        'oct',
        'nov',
        'dic',
      ];
      return '${fecha.day} ${meses[fecha.month - 1]}';
    }

    return '${formatearFecha(inicio)} - ${formatearFecha(fin)}';
  }

  Color obtenerColorFecha(DateTime fechaVencimiento, EstadoTarjeta estado) {
    if (estado == EstadoTarjeta.hecho) return Colors.green;
    final hoy = DateTime.now();
    final venc = DateTime(
      fechaVencimiento.year,
      fechaVencimiento.month,
      fechaVencimiento.day,
    );
    final diferencia =
        venc.difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;
    if (diferencia < 0) return Colors.red;
    if (diferencia == 1 || diferencia == 0) return Colors.amber;
    return Colors.white70;
  }

  @override
  void initState() {
    super.initState();
    editandoTituloLista = false;
    _controllerTituloLista = TextEditingController(text: widget.titulo);
    _focusNodeTituloLista = FocusNode();
    _focusNodeTituloLista.addListener(() {
      if (!_focusNodeTituloLista.hasFocus && editandoTituloLista) {
        guardarTituloLista();
      }
    });
  }

  @override
  void dispose() {
    _controllerTituloLista.dispose();
    _focusNodeTituloLista.dispose();
    _controllerNuevaTarjeta.dispose();
    _focusNodeNuevaTarjeta.dispose();
    super.dispose();
  }

  void guardarTituloLista() {
    setState(() {
      editandoTituloLista = false;
      widget.onTituloEditado(_controllerTituloLista.text.trim());
      _focusNodeTituloLista.unfocus();
    });
  }

  void activarEdicionTituloLista() {
    setState(() {
      editandoTituloLista = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodeTituloLista.requestFocus();
      _controllerTituloLista.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controllerTituloLista.text.length,
      );
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
    // Controladores locales para el modal
    final tituloController = TextEditingController(text: tarjeta.titulo); // ¡Nuevo controlador para el título!
    final miembroController = TextEditingController(text: tarjeta.miembro);
    final tiempoController = TextEditingController(text: tarjeta.tiempo);
    DateTime? fechaInicio = tarjeta.fechaInicio;
    DateTime? fechaVencimiento = tarjeta.fechaVencimiento;
    EstadoTarjeta estadoActual = tarjeta.estado;

    final List<Widget> mensajesAlert = [];

    if (fechaVencimiento != null) {
      final hoy = DateTime.now();
      final venc = DateTime(
        fechaVencimiento.year,
        fechaVencimiento.month,
        fechaVencimiento.day,
      );
      final diff =
          venc.difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;
      if (diff < 0 && estadoActual != EstadoTarjeta.hecho) {
        mensajesAlert.add(
          const Text("⚠️ Plazo vencido", style: TextStyle(color: Colors.red)),
        );
      } else if ((diff == 1 || diff == 0) &&
          estadoActual != EstadoTarjeta.hecho) {
        mensajesAlert.add(
          const Text("⚠️ Vence pronto", style: TextStyle(color: Colors.amber)),
        );
      }
    }

    if (estadoActual == EstadoTarjeta.hecho) {
      mensajesAlert.add(
        const Text("✅ Cumplido", style: TextStyle(color: Colors.green)),
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              backgroundColor: Colors.black87,
              // Título del modal ahora es un TextField editable
              title: TextField(
                controller: tituloController,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20, // Ajusta el tamaño si es necesario
                ),
                decoration: InputDecoration(
                  hintText: 'Título de la tarjeta',
                  hintStyle: TextStyle(color: Colors.white54, fontWeight: FontWeight.normal),
                  border: InputBorder.none, // Elimina el borde del TextField
                  isDense: true, // Reduce el espacio vertical
                  contentPadding: EdgeInsets.zero, // Elimina padding interno
                ),
                maxLines: null, // Permite múltiples líneas
                keyboardType: TextInputType.multiline, // Habilita el teclado multilínea
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...mensajesAlert,
                    SizedBox(height: 8),
                    buildTextField("👤 Miembro", miembroController),
                    buildTiempoField("⏱ Tiempo", tiempoController),
                    buildEstadoDropdown(estadoActual, (newValue) {
                      setStateModal(() {
                        estadoActual = newValue;
                      });
                    }),
                    buildDatePicker(
                      "📅 Fecha de inicio",
                      (picked) => setStateModal(() => fechaInicio = picked),
                      fechaInicio,
                    ),
                    buildDatePicker(
                      "⏳ Fecha de vencimiento",
                      (picked) => setStateModal(() => fechaVencimiento = picked),
                      fechaVencimiento,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Crea una nueva Tarjeta con los datos actualizados
                    Tarjeta tarjetaActualizada = Tarjeta(
                      titulo: tituloController.text.trim(), // ¡Guarda el título editado!
                      miembro: miembroController.text,
                      tarea: tarjeta.tarea, // tarea no se edita en este modal
                      tiempo: tiempoController.text,
                      fechaInicio: fechaInicio,
                      fechaVencimiento: fechaVencimiento,
                      estado: estadoActual,
                    );
                    widget.onTarjetaActualizada(widget.indexLista, indexTarjeta, tarjetaActualizada);
                    Navigator.of(context).pop();
                  },
                  child: const Text("Guardar"),
                ),
              ],
            );
          },
        );
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
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white38),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget buildTiempoField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: "$label (horas)",
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white38),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
        ),
      )
      );
    }

  Widget buildEstadoDropdown(
      EstadoTarjeta estadoActual, Function(EstadoTarjeta) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Estado:",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          DropdownButton<EstadoTarjeta>(
            value: estadoActual,
            dropdownColor: Colors.black87,
            style: const TextStyle(color: Colors.white),
            onChanged: (EstadoTarjeta? newValue) {
              if (newValue != null) {
                onChanged(newValue);
              }
            },
            items: <EstadoTarjeta>[
              EstadoTarjeta.hecho,
              EstadoTarjeta.enProceso,
              EstadoTarjeta.porHacer
            ].map<DropdownMenuItem<EstadoTarjeta>>((EstadoTarjeta value) {
              String text;
              Color color;
              switch (value) {
                case EstadoTarjeta.hecho:
                  text = "Hecho";
                  color = Colors.green;
                  break;
                case EstadoTarjeta.enProceso:
                  text = "En proceso";
                  color = Colors.amber;
                  break;
                case EstadoTarjeta.porHacer:
                  text = "Por hacer";
                  color = Colors.grey;
                  break;
              }
              return DropdownMenuItem<EstadoTarjeta>(
                value: value,
                child: Text(
                  text,
                  style: TextStyle(color: color),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget buildDatePicker(
    String label,
    Function(DateTime) onDatePicked,
    DateTime? fechaActual,
  ) {
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
          child: const Text(
            "Elegir",
            style: TextStyle(color: Colors.blueAccent),
          ),
        ),
      ],
    );
  }

  Color _getColorForEstado(EstadoTarjeta estado) {
    switch (estado) {
      case EstadoTarjeta.hecho:
        return Colors.green;
      case EstadoTarjeta.enProceso:
        return Colors.amber;
      case EstadoTarjeta.porHacer:
        return Colors.grey;
    }
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
          editandoTituloLista
              ? TextField(
                  controller: _controllerTituloLista,
                  focusNode: _focusNodeTituloLista,
                  autofocus: true,
                  onSubmitted: (_) => guardarTituloLista(),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(border: InputBorder.none),
                )
              : GestureDetector(
                  onTap: activarEdicionTituloLista,
                  child: Text(
                    widget.titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
                onTap: () => mostrarModalTarjeta(index), // Abre el modal con el título editable
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
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
                      // Línea de color de estado en la parte superior de la tarjeta
                      Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: _getColorForEstado(tarjeta.estado),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Círculo interactivo que aparece al hacer hover
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: enHover ? 24 : 0,
                                  height: 24,
                                  margin: const EdgeInsets.only(right: 8, top: 2),
                                  child: enHover
                                      ? GestureDetector(
                                          onTap: () {
                                            EstadoTarjeta nuevoEstado;
                                            if (tarjeta.estado == EstadoTarjeta.hecho) {
                                              nuevoEstado = EstadoTarjeta.porHacer;
                                            } else {
                                              nuevoEstado = EstadoTarjeta.hecho;
                                            }
                                            widget.onEstadoChanged(index, nuevoEstado);
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: _getColorForEstado(tarjeta.estado),
                                                width: 2,
                                              ),
                                              color: tarjeta.estado == EstadoTarjeta.hecho ? Colors.green : Colors.transparent,
                                            ),
                                            child: Center(
                                              child: tarjeta.estado == EstadoTarjeta.hecho
                                                  ? Icon(Icons.check, size: 16, color: Colors.white)
                                                  : null,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                Expanded(
                                  child: Text( // El título de la tarjeta ya no es editable aquí, solo en el modal
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
                              Text(
                                "👤 ${tarjeta.miembro}",
                                style: const TextStyle(color: Colors.white70),
                              ),
                            if (tarjeta.tiempo.isNotEmpty)
                              Text(
                                "⏱ ${tarjeta.tiempo} horas",
                                style: const TextStyle(color: Colors.white70),
                              ),
                            if (tarjeta.fechaInicio != null &&
                                tarjeta.fechaVencimiento != null)
                              Text(
                                "📅 ${formatearRangoFechas(tarjeta.fechaInicio!, tarjeta.fechaVencimiento!)}",
                                style: TextStyle(
                                  color: obtenerColorFecha(
                                    tarjeta.fechaVencimiento!,
                                    tarjeta.estado,
                                  ),
                                  fontWeight: FontWeight.w500,
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
                          child: const Text(
                            'Guardar',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : TextButton.icon(
                  onPressed: widget.mostrarCampoNuevaTarjeta,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Añadir',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onAgregar,
        icon: const Icon(Icons.add),
        label: const Text('Otra lista'),
      ),
    );
  }
}