import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mathani/core/errors/failures.dart';
import 'package:mathani/data/models/ayah.dart';
import 'package:mathani/domain/repositories/quran_repository.dart';
import 'package:mathani/presentation/providers/quran_provider.dart';

class _Repository implements QuranRepository {
  final pending = <String, Completer<Either<Failure, List<Ayah>>>>{};
  @override
  Future<Either<Failure, List<Ayah>>> searchAyahs(String query) =>
      (pending[query] = Completer<Either<Failure, List<Ayah>>>()).future;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('an obsolete search cannot overwrite the latest result', () async {
    final repository = _Repository();
    final provider = QuranProvider(repository: repository);
    final old = provider.search('old');
    final latest = provider.search('latest');
    repository.pending['latest']!.complete(Right([Ayah()..ayahNumber = 2]));
    await latest;
    expect(provider.searchResults.single.ayahNumber, 2);
    repository.pending['old']!.complete(Right([Ayah()..ayahNumber = 1]));
    await old;
    expect(provider.searchResults.single.ayahNumber, 2);
    provider.dispose();
  });

  test('clearing search invalidates pending requests', () async {
    final repository = _Repository();
    final provider = QuranProvider(repository: repository);
    final work = provider.search('old');
    provider.clearSearch();
    expect(provider.searchResults, isEmpty);
    repository.pending['old']!.complete(Right([Ayah()..ayahNumber = 1]));
    await work;
    expect(provider.searchResults, isEmpty);
    provider.dispose();
  });
}
