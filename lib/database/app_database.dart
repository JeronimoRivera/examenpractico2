import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/baggage_event.dart';

part 'app_database.g.dart';

class BaggageEventEntries extends Table {
  TextColumn get id => text()();
  TextColumn get baggageId => text()();
  TextColumn get type => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [BaggageEventEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_abrirConexion());

  @override
  int get schemaVersion => 1;

  Future<void> guardarEvento(BaggageEvent evento) {
    return into(baggageEventEntries).insertOnConflictUpdate(
      BaggageEventEntriesCompanion.insert(
        id: evento.id,
        baggageId: evento.baggageId,
        type: evento.type,
        createdAt: evento.createdAt,
      ),
    );
  }

  Future<List<BaggageEvent>> eventosDeEquipaje(String baggageId) async {
    final filas = await (select(baggageEventEntries)
          ..where((evento) => evento.baggageId.equals(baggageId))
          ..orderBy([(evento) => OrderingTerm.asc(evento.createdAt)]))
        .get();
    return filas
        .map(
          (fila) => BaggageEvent(
            id: fila.id,
            baggageId: fila.baggageId,
            type: fila.type,
            createdAt: fila.createdAt,
          ),
        )
        .toList();
  }
}

LazyDatabase _abrirConexion() {
  return LazyDatabase(() async {
    final directorio = await getApplicationDocumentsDirectory();
    return NativeDatabase(File(p.join(directorio.path, 'baggage.sqlite')));
  });
}
