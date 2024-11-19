import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:ouisync_app/app/cubits/cubits.dart' show RepoCubit;
import 'package:ouisync_app/app/models/models.dart'
    show LocalSecretMode, LocalSecretKeyAndSalt, RepoEntry, RepoLocation;
import 'package:ouisync/ouisync.dart' show AccessMode, File, Repository;
import 'package:ouisync_app/app/utils/share_token.dart';

import '../utils.dart' show BlocBaseExtension, TestDependencies, testApp;

void main() {
  late TestDependencies deps;

  final String originRepoName = 'origin';
  final String lockedRepoName = 'locked repo';
  final String readRepoName = 'read repo';

  final String readTokenString =
      'https://ouisync.net/r#AwEgOdW98iaOedPg8CG3J7szV_-lMFH9OSgBSRz6C6w3CBcgx5QxWXk3jhFd8rx1zObVJZd0OVc3EQD_YuRReKDLE5M?name=uno';

  late Repository originRepo;
  late RepoEntry lockedRepoEntry;

  setUp(() async {
    deps = await TestDependencies.create();

    final reposDir = await deps.reposCubit.settings.getDefaultRepositoriesDir();

    final originRepoLocation = RepoLocation.fromParts(
      dir: reposDir,
      name: originRepoName,
    );

    final lockedRepoLocation = RepoLocation.fromParts(
      dir: reposDir,
      name: lockedRepoName,
    );

    final readRepoLocation = RepoLocation.fromParts(
      dir: reposDir,
      name: readRepoName,
    );

    await deps.reposCubit.createRepository(
      location: originRepoLocation,
      setLocalSecret: LocalSecretKeyAndSalt.random(),
      localSecretMode: LocalSecretMode.randomStored,
    );

    lockedRepoEntry = await deps.reposCubit.createRepository(
      location: lockedRepoLocation,
      setLocalSecret: LocalSecretKeyAndSalt.random(),
      localSecretMode: LocalSecretMode.randomStored,
    );

    await lockedRepoEntry.cubit?.lock();

    final readTokenResult = await parseShareToken(
      deps.reposCubit,
      readTokenString,
    );
    final readToken = (readTokenResult as ShareTokenValid);
    await deps.reposCubit.createRepository(
      location: readRepoLocation,
      setLocalSecret: LocalSecretKeyAndSalt.random(),
      localSecretMode: LocalSecretMode.randomStored,
      token: readToken.value,
    );

    originRepo = await Repository.open(
      deps.session,
      store: originRepoLocation.path,
    );

    final newFile = await File.create(originRepo, '/file.txt');
    await newFile.write(0, 'Hello world!'.codeUnits);
    await newFile.close();
  });

  tearDown(() async {
    await lockedRepoEntry.close();
    await originRepo.close();
    await deps.dispose();
  });

  testWidgets(
    'move file to a blind/locked repo and confirm that MOVE button is disabled',
    (tester) => tester.runAsync(
      () async {
        await loadAppFonts();

        await tester.pumpWidget(testApp(deps.createMainPage()));
        await tester.pumpAndSettle();

        expect(find.text(originRepoName), findsOne);
        expect(find.text(lockedRepoName), findsOne);
        expect(find.text(readRepoName), findsOne);

        final originRepoCubit = deps.reposCubit.repos
            .firstWhere((r) => r.name == originRepoName)
            .cubit!;

        await tester.tap(find.text(originRepoName));
        await _waitForNavigationIntoRepoToEnd(deps, tester, originRepoCubit);

        final fileVert = find.byKey(ValueKey('file_vert'));
        expect(fileVert, findsOne);

        await tester.tap(fileVert);
        await tester.pumpAndSettle();

        final moveListTile = find.widgetWithText(ListTile, 'Move');
        expect(moveListTile, findsOne);

        await tester.tap(moveListTile);
        await tester.pumpAndSettle();

        final backButton = find.widgetWithIcon(
          IconButton,
          Icons.arrow_back_rounded,
        );
        expect(backButton, findsOne);

        await tester.tap(backButton);
        await tester.pumpAndSettle();

        final lockedRepoCubit = deps.reposCubit.repos
            .firstWhere((r) => r.name == lockedRepoName)
            .cubit!;

        await tester.tap(find.text(lockedRepoName));
        await _waitForNavigationIntoRepoToEnd(
          deps,
          tester,
          lockedRepoCubit,
        );

        final currentRepoEntry = deps.reposCubit.currentRepo;
        expect(currentRepoEntry?.accessMode, equals(AccessMode.blind));

        final moveButton = find.descendant(
          of: find.byKey(ValueKey('move_entry')),
          matching: find.byWidgetPredicate(
            (widget) => widget is RawMaterialButton,
          ),
        );
        expect(moveButton, findsOne);
        expect(tester.widget<RawMaterialButton>(moveButton).enabled, false);
      },
    ),
  );

  testWidgets(
    'move file to a read repo and confirm that MOVE button is disabled',
    (tester) => tester.runAsync(
      () async {
        await loadAppFonts();

        await tester.pumpWidget(testApp(deps.createMainPage()));
        await tester.pumpAndSettle();

        expect(find.text(originRepoName), findsOne);
        expect(find.text(lockedRepoName), findsOne);
        expect(find.text(readRepoName), findsOne);

        final originRepoCubit = deps.reposCubit.repos
            .firstWhere((r) => r.name == originRepoName)
            .cubit!;

        await tester.tap(find.text(originRepoName));
        await _waitForNavigationIntoRepoToEnd(deps, tester, originRepoCubit);

        final fileVert = find.byKey(ValueKey('file_vert'));
        expect(fileVert, findsOne);

        await tester.tap(fileVert);
        await tester.pumpAndSettle();

        final moveListTile = find.widgetWithText(ListTile, 'Move');
        expect(moveListTile, findsOne);

        await tester.tap(moveListTile);
        await tester.pumpAndSettle();

        final backButton = find.widgetWithIcon(
          IconButton,
          Icons.arrow_back_rounded,
        );
        expect(backButton, findsOne);

        await tester.tap(backButton);
        await tester.pumpAndSettle();

        final readRepoCubit = deps.reposCubit.repos
            .firstWhere((r) => r.name == readRepoName)
            .cubit!;

        await tester.tap(find.text(readRepoName));
        await _waitForNavigationIntoRepoToEnd(
          deps,
          tester,
          readRepoCubit,
        );

        final currentRepoEntry = deps.reposCubit.currentRepo;
        expect(currentRepoEntry?.accessMode, equals(AccessMode.read));

        final moveButton = find.descendant(
          of: find.byKey(ValueKey('move_entry')),
          matching: find.byWidgetPredicate(
            (widget) => widget is RawMaterialButton,
          ),
        );
        expect(moveButton, findsOne);
        expect(tester.widget<RawMaterialButton>(moveButton).enabled, false);
      },
    ),
  );
}

Future<void> _waitForNavigationIntoRepoToEnd(
  TestDependencies deps,
  WidgetTester tester,
  RepoCubit repo,
) async {
  await deps.reposCubit.waitUntil((_) =>
      !deps.reposCubit.isLoading &&
      deps.reposCubit.currentRepo?.name == repo.name);
  await tester.pump();

  await deps.reposCubit.currentRepo?.cubit?.waitUntil(
      (_) => deps.reposCubit.currentRepo?.cubit?.state.isLoading == false);
  await tester.pumpAndSettle();
  await tester.pump(Duration(seconds: 1));
}