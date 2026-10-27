import 'package:flutter/material.dart';

import '../models/baggage.dart';
import '../models/baggage_event.dart';
import '../repositories/baggage_event_repository.dart';

class BaggageDetailPage extends StatefulWidget {
  const BaggageDetailPage({
    super.key,
    required this.baggage,
  });

  final Baggage baggage;

  @override
  State<BaggageDetailPage> createState() => _BaggageDetailPageState();
}

class _BaggageDetailPageState extends State<BaggageDetailPage> {
  final BaggageEventRepository _repositorio = BaggageEventRepository();
  final List<BaggageEvent> _eventos = [];
  bool _usandoDatosLocales = false;

  static const _secuencia = [
    'CHECKED_IN',
    'SECURITY',
    'LOADED',
    'IN_TRANSIT',
    'DELIVERED',
  ];

  @override
  void initState() {
    super.initState();
    _cargarEventos();
  }

  Future<void> _cargarEventos() async {
    final eventos =
        await _repositorio.getEventsForBaggage(widget.baggage.id);
    if (!mounted) return;
    setState(() {
      _eventos
        ..clear()
        ..addAll(eventos);
      _usandoDatosLocales = _repositorio.usandoDatosLocales;
    });
  }

  Future<void> _registrarSiguienteEvento() async {
    final ultimoEvento = _eventos.isEmpty
        ? null
        : _eventos.reduce(
            (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
          );
    final indiceActual =
        ultimoEvento == null ? -1 : _secuencia.indexOf(ultimoEvento.type);
    if (ultimoEvento != null && indiceActual == -1) return;
    final siguienteIndice = indiceActual + 1;
    if (siguienteIndice < 0 || siguienteIndice >= _secuencia.length) return;

    final siguienteTipo = _secuencia[siguienteIndice];
    if (siguienteTipo == 'LOADED') {
      final eventosSeguridad =
          _eventos.where((evento) => evento.type == 'SECURITY').toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (eventosSeguridad.isEmpty) return;
      final faltante = eventosSeguridad.first.createdAt
          .add(const Duration(minutes: 10))
          .difference(DateTime.now());
      if (faltante > Duration.zero) {
        final minutos = (faltante.inSeconds / 60).ceil();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Faltan aprox. $minutos ${minutos == 1 ? 'minuto' : 'minutos'} para poder cargar el equipaje',
            ),
          ),
        );
        return;
      }
    }

    final ahora = DateTime.now();
    final evento = BaggageEvent(
      id: '${widget.baggage.id}_${ahora.millisecondsSinceEpoch}',
      baggageId: widget.baggage.id,
      type: siguienteTipo,
      createdAt: DateTime.now(),
    );
    try {
      await _repositorio.registerEvent(evento);
      await _cargarEventos();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo registrar el evento')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.baggage.id)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _BaggageHeader(
            baggage: widget.baggage,
            estado: _eventos.isEmpty
                ? 'Sin eventos'
                : _eventos
                    .reduce(
                      (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
                    )
                    .type,
          ),
          const SizedBox(height: 24),
          Text(
            'Historial de eventos',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 14),
          if (_usandoDatosLocales)
            const Text('Sin conexión: mostrando datos locales'),
          if (_eventos.isEmpty)
            const Text('Este equipaje aun no tiene eventos.')
          else
            ..._eventos.map(
              (evento) => ListTile(
                title: Text(evento.type),
                subtitle: Text(evento.createdAt.toString()),
              ),
            ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _registrarSiguienteEvento,
            icon: const Icon(Icons.add),
            label: const Text('Registrar primer evento'),
          ),
        ],
      ),
    );
  }
}

class _BaggageHeader extends StatelessWidget {
  const _BaggageHeader({required this.baggage, required this.estado});

  final Baggage baggage;
  final String estado;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.luggage,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        baggage.id,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Chip(label: Text(estado)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            Row(
              children: [
                Expanded(
                  child: _InfoField(
                    label: 'Pasajero',
                    value: baggage.passenger,
                  ),
                ),
                Expanded(
                  child: _InfoField(
                    label: 'Vuelo',
                    value: baggage.flight,
                  ),
                ),
                Expanded(
                  child: _InfoField(
                    label: 'Destino',
                    value: baggage.destination,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  const _InfoField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
