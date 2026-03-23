import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus_drift/serinus_drift.dart';
part 'serinus_drift.g.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

@DriftDatabase(tables: [Users])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}

@DriftAccessor(tables: [Users])
class UsersDao extends DatabaseAccessor<AppDatabase> with _$UsersDaoMixin {
  UsersDao(super.db);

  Future<List<User>> getAllUsers() => select(users).get();
  Future<int> insertUser(UsersCompanion user) => into(users).insert(user);
}

class AppModule extends Module {
  AppModule() : super(
    imports: [
      DriftModule(AppDatabase(NativeDatabase.memory())),
      DriftModule.forFeature<AppDatabase>(
        daos: (database) => [
          UsersDao(database)
        ], 
      ),
    ],
    controllers: [
      UserController()
    ]
  );
}

class UserController extends Controller {
  UserController() : super('/users') {
    
    on(Route.get('/'), (context) async {
      // Inject the feature-specific DAO!
      final usersDao = context.use<UsersDao>();
      // Inject the Drift database
      final db = context.use<AppDatabase>();
      
      // Perform your Drift queries
      final users = await db.select(db.users).get();
      final usersFromDao = await usersDao.getAllUsers();
      
      return {
        'users': users.map((u) => {'id': u.id, 'name': u.name}).toList(),
        'usersFromDao': usersFromDao.map((u) => {'id': u.id, 'name': u.name}).toList(),
      };
    });
    on(Route.post('/'), (RequestContext<Map<String, dynamic>> context) async {
      final usersDao = context.use<UsersDao>();
      final data = context.body;
      final name = data['name'].toString();
      final id = await usersDao.insertUser(UsersCompanion(name: Value(name)));
      return {'id': id, 'name': name};
    });
    
  }
}

Future<void> main() async {
  final app = await serinus.createApplication(
    entrypoint: AppModule(),
  );
  await app.serve();
}