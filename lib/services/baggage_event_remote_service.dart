import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/baggage_event.dart';

class BaggageEventRemoteService {
  Future<List<BaggageEvent>> getEvents() async {
    final documentos = await FirebaseFirestore.instance
        .collection('baggage_events')
        .get();
    return documentos.docs
        .map((documento) => BaggageEvent.fromJson(documento.data()))
        .toList();
  }

  Future<void> saveEvent(BaggageEvent event) async {
    await FirebaseFirestore.instance
        .collection('baggage_events')
        .doc(event.id)
        .set(event.toJson());
  }
}
