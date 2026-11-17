# Isar 3.1.0+1 compatibility fixture

`default.isar` was created on 2026-11-17 on Windows x64 using the original
`isar 3.1.0+1` Dart package, its original generated Mathani schemas, and
`isar_flutter_libs 3.1.0+1/windows/isar.dll`, before replacing these dependencies.
It contains synthetic data only: one record in each of the nine collections
opened by `IsarService`. It contains no user data, credentials or audio.

SHA-256: `9a6b49533e4669abd8b6fedde4025c3bd29a837a8bdaed0481da2ebcb8ea529a`.

`expected.json` is the JSON export made with the original engine before closing
the database. `schema.json` is the original schema export. `collection_ids.json`
records collection IDs from the original generated code in Git HEAD before this
migration. Keep these files frozen; do not regenerate them with Isar Community.

The migration test copies the fixture into a fresh temporary directory. It checks
all records, schema properties and indexes, original collection IDs, indexed
queries, backup preservation, and writing/reopening with the new engine. It also
checks that a separate invalid database file is preserved when opening fails.
Tests never open this fixture in place or access the user's application data.

Run: `flutter test --no-pub test/unit/database/isar_migration_test.dart`.
Native libraries are resolved from the installed `isar_community_flutter_libs`
package. Windows was exercised locally; Linux/macOS paths are provided for those
test runners. This does not replace an Android upgrade test on a real device.
