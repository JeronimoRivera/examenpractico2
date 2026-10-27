import '../database/app_database.dart';
import '../models/baggage_event.dart';
import '../services/baggage_event_remote_service.dart';

class BaggageEventRepository {
  final BaggageEventRemoteService _servicioRemoto =
      BaggageEventRemoteService();
  final AppDatabase _baseDatos = AppDatabase();

  bool usandoDatosLocales = false;

  Future<List<BaggageEvent>> getEventsForBaggage(String baggageId) async {
    try {
      final eventos = await _servicioRemoto.getEvents();
      final eventosDelEquipaje = eventos
          .where((evento) => evento.baggageId == baggageId)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      for (final evento in eventosDelEquipaje) {
        await _baseDatos.guardarEvento(evento);
      }
      usandoDatosLocales = false;
      return eventosDelEquipaje;
    } catch (_) {
      usandoDatosLocales = true;
      return _baseDatos.eventosDeEquipaje(baggageId);
    }
  }

  Future<void> registerEvent(BaggageEvent event) async {
    await _servicioRemoto.saveEvent(event);
    await _baseDatos.guardarEvento(event);
  }
}
