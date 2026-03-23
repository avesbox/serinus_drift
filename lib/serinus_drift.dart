import 'package:drift/drift.dart';
import 'package:serinus/serinus.dart';

final _internalDbInstance = _InternalDbInstance();

class DriftModule<T extends GeneratedDatabase> extends Module {
  @override
  bool get isGlobal => true;

  final T database;

  DriftModule(this.database);

  @override
  Future<DynamicModule> registerAsync(ApplicationConfig config) async {
    _internalDbInstance.database = database;
    return DynamicModule(
      providers: [
        DatabaseManager(),
        Provider.forValue<T>(database, asType: T),
      ],
      exports: [Export.value<T>()],
    );
  }

  static DriftFeatureModule<T> forFeature<T extends GeneratedDatabase>({
    required List<DatabaseAccessor> Function(T database) daos,
  }) {
    return DriftFeatureModule<T>(daos);
  }
}

class _InternalDbInstance {
  GeneratedDatabase? database;

  _InternalDbInstance();
}

class DatabaseManager extends Provider with OnApplicationShutdown {
  @override
  Future<void> onApplicationShutdown() async {
    final db = _internalDbInstance.database;
    if (db != null) {
      await db.close();
    }
  }
}

class DriftFeatureModule<T extends GeneratedDatabase> extends Module {
  final List<DatabaseAccessor> Function(T database) init;

  DriftFeatureModule(this.init);

  @override
  Future<DynamicModule> registerAsync(ApplicationConfig config) async {
    final providers = <Provider>[];
    final exports = <Export>[];
    final database = _internalDbInstance.database;
    if (database == null) {
      throw StateError(
        'Drift database instance is not initialized. Make sure to register DriftModule before using DriftFeatureModule.',
      );
    }
    final accessors = init(database as T);
    for (final accessor in accessors) {
      final type = accessor.runtimeType;
      providers.add(Provider.forValue(accessor, asType: type));
      exports.add(Export(type));
    }
    return DynamicModule(providers: providers, exports: exports);
  }
}
