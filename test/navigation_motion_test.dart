import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/network/dio_client.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/core/widgets/ilm_bottom_navigation.dart';
import 'package:ilm_ai_flutter/core/widgets/ilm_navigation_icons.dart';
import 'package:ilm_ai_flutter/core/widgets/ilm_tab_view.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/skills/application/learning_preferences.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_extras_repository.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_repository.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/subject_home_screen.dart';
import 'subject_experience_test.dart' show FakeAuth;
import 'support/offline_preferences.dart';
import 'uiux_visual_review_test.dart' show reviewDio;

const _labels = ['Learn', 'Practice', 'Quests', 'League', 'Profile'];

class _RequestRecorder extends Interceptor {
  _RequestRecorder(this.requests);
  final List<String> requests;
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    requests.add(options.path);
    handler.next(options);
  }
}

final _items = [
  for (var i = 0; i < 5; i++)
    IlmNavigationDestination(
      icon: Icons.circle_outlined,
      label: _labels[i],
      motionIcon: IlmNavIcon.values[i],
    ),
];

class _Probe extends StatefulWidget {
  const _Probe(this.id, this.starts, {super.key});
  final int id;
  final List<int> starts;
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  final scroll = ScrollController();
  int presses = 0;
  @override
  void initState() {
    super.initState();
    widget.starts[widget.id]++;
  }

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    controller: scroll,
    children: [
      TextButton(
        onPressed: () => setState(() => presses++),
        child: Text('Action ${widget.id}: $presses'),
      ),
      for (var i = 0; i < 30; i++)
        SizedBox(height: 56, child: Text('Page ${widget.id}, row $i')),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final config = File('.dart_tool/package_config.json');
    final packages =
        (jsonDecode(config.readAsStringSync()) as Map)['packages'] as List;
    final flutter = packages.cast<Map>().singleWhere(
      (p) => p['name'] == 'flutter',
    );
    final sdk = Directory.fromUri(
      config.uri.resolve(flutter['rootUri'] as String),
    ).parent.parent;
    final loader = FontLoader('Roboto');
    for (final weight in ['regular', 'medium', 'bold']) {
      loader.addFont(
        Future.value(
          ByteData.sublistView(
            File(
              '${sdk.path}/bin/cache/artifacts/material_fonts/roboto-$weight.ttf',
            ).readAsBytesSync(),
          ),
        ),
      );
    }
    await loader.load();
  });

  for (final dark in [false, true]) {
    for (final reduced in [false, true]) {
      testWidgets(
        'navigation $dark/$reduced animates once and exposes one selected target',
        (tester) async {
          var selected = 0, changes = 0;
          late StateSetter update;
          final handle = tester.ensureSemantics();
          await tester.pumpWidget(
            MaterialApp(
              theme: buildAppTheme(dark ? darkColors : lightColors),
              home: MediaQuery(
                data: MediaQueryData(disableAnimations: reduced),
                child: StatefulBuilder(
                  builder: (context, set) {
                    update = set;
                    return Scaffold(
                      bottomNavigationBar: IlmBottomNavigation(
                        index: selected,
                        items: _items,
                        onChanged: (index) => set(() {
                          selected = index;
                          changes++;
                        }),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
          final before = tester.getCenter(
            find.byKey(const ValueKey('ilm-nav-selection')),
          );
          await tester.tap(find.text('League'));
          expect(selected, 3); // No callback delay while motion runs.
          await tester.pump();
          final first = tester.getCenter(
            find.byKey(const ValueKey('ilm-nav-selection')),
          );
          if (reduced) {
            expect(first.dx, greaterThan(before.dx));
            expect(
              tester
                  .widgetList<IlmNavigationIcon>(find.byType(IlmNavigationIcon))
                  .elementAt(3)
                  .progress,
              1,
            );
            await tester.pump(const Duration(milliseconds: 100));
            expect(
              tester.getCenter(find.byKey(const ValueKey('ilm-nav-selection'))),
              first,
            );
          } else {
            expect(first.dx, closeTo(before.dx, .1));
            await tester.pump(const Duration(milliseconds: 130));
            final midway = tester.getCenter(
              find.byKey(const ValueKey('ilm-nav-selection')),
            );
            expect(midway.dx, greaterThan(before.dx));
            expect(midway.dx, lessThan(800 * 3.5 / 5));
            final animated = tester
                .widgetList<IlmNavigationIcon>(find.byType(IlmNavigationIcon))
                .elementAt(3);
            expect(animated.progress, inExclusiveRange(0, 1));
          }
          await tester.pumpAndSettle();
          expect(
            tester.getSemantics(find.byKey(const ValueKey('ilm-nav-3'))).label,
            contains('League'),
          );
          await tester.tap(find.text('League'));
          expect(changes, 1); // Same destination does not refetch or replay.
          for (final i in [4, 0, 2, 1]) {
            update(() => selected = i);
            await tester.pump(const Duration(milliseconds: 30));
          }
          await tester.pumpAndSettle();
          expect(tester.binding.hasScheduledFrame, isFalse);
          expect(
            tester
                .widgetList<IlmNavigationIcon>(find.byType(IlmNavigationIcon))
                .elementAt(1)
                .progress,
            1,
          );
          expect(tester.takeException(), isNull);
          handle.dispose();
        },
      );
    }
  }

  for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
    for (final lang in ['uz', 'ru', 'en']) {
      final labels = lang == 'uz'
          ? ['O‘rganish', 'Mashq', 'Vazifalar', 'Liga', 'Profil']
          : lang == 'ru'
          ? ['Учиться', 'Практика', 'Задания', 'Лига', 'Профиль']
          : _labels;
      final items = [
        for (var i = 0; i < 5; i++)
          IlmNavigationDestination(
            icon: Icons.circle_outlined,
            label: labels[i],
            motionIcon: IlmNavIcon.values[i],
          ),
      ];
      for (final dark in [false, true]) {
        testWidgets(
          '320dp/200% $lang/$direction/$dark preserves targets, safe area and full semantics',
          (tester) async {
            tester.view.physicalSize = const Size(320, 568);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final handle = tester.ensureSemantics();
            var selected = 0;
            await tester.pumpWidget(
              MaterialApp(
                theme: buildAppTheme(dark ? darkColors : lightColors),
                home: Directionality(
                  textDirection: direction,
                  child: MediaQuery(
                    data: const MediaQueryData(
                      textScaler: TextScaler.linear(2),
                      padding: EdgeInsets.only(bottom: 24),
                    ),
                    child: StatefulBuilder(
                      builder: (context, set) => Scaffold(
                        bottomNavigationBar: IlmBottomNavigation(
                          index: selected,
                          items: items,
                          onChanged: (i) => set(() => selected = i),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            for (var i = 0; i < 5; i++) {
              final target = find.byKey(ValueKey('ilm-nav-$i'));
              final size = tester.getSize(target);
              expect(size.width, greaterThanOrEqualTo(48));
              expect(size.height, greaterThanOrEqualTo(48));
              final semantics = tester.getSemantics(target);
              expect(semantics.label, contains(labels[i]));
              tester.binding.platformDispatcher.onSemanticsActionEvent!(
                ui.SemanticsActionEvent(
                  nodeId: semantics.id,
                  type: ui.SemanticsAction.tap,
                  viewId: tester.view.viewId,
                ),
              );
              await tester.pumpAndSettle();
              expect(selected, i);
              expect(tester.takeException(), isNull);
            }
            expect(
              tester.getBottomRight(find.byKey(const ValueKey('ilm-nav-4'))).dy,
              lessThanOrEqualTo(544),
            );
            handle.dispose();
          },
        );
      }
    }
  }

  testWidgets(
    'tab transitions preserve scroll/state and accept only the current page',
    (tester) async {
      var selected = 0;
      final starts = [0, 0, 0];
      final keys = List.generate(3, (_) => GlobalKey<_ProbeState>());
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, set) => Scaffold(
              body: IlmTabView(
                index: selected,
                children: [
                  for (var i = 0; i < 3; i++) _Probe(i, starts, key: keys[i]),
                ],
              ),
              bottomNavigationBar: Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    TextButton(
                      onPressed: () => set(() => selected = i),
                      child: Text('Tab $i'),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      keys[0].currentState!.scroll.jumpTo(200);
      await tester.tap(find.text('Tab 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tab 2'));
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('Action 1: 0').hitTestable(), findsNothing);
      expect(find.semantics.byLabel('Action 1: 0'), findsNothing);
      for (final i in [2, 0, 1, 2, 0]) {
        await tester.tap(find.text('Tab $i'));
        await tester.pump(const Duration(milliseconds: 25));
      }
      await tester.pumpAndSettle();
      expect(starts, [1, 1, 1]);
      expect(keys[0].currentState!.scroll.offset, 200);
      expect(find.byType(_Probe), findsOneWidget);
      expect(tester.takeException(), isNull);
      handle.dispose();
    },
  );

  testWidgets(
    'reduced-motion tab switch is immediate without an outgoing page',
    (tester) async {
      var selected = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: StatefulBuilder(
              builder: (context, set) => Scaffold(
                body: IlmTabView(
                  index: selected,
                  children: const [Text('First page'), Text('Second page')],
                ),
                bottomNavigationBar: TextButton(
                  onPressed: () => set(() => selected = 1),
                  child: const Text('Switch'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Switch'));
      await tester.pump();
      expect(find.text('First page'), findsNothing);
      expect(find.text('Second page').hitTestable(), findsOneWidget);
      final opacity = tester.widget<Opacity>(
        find
            .ancestor(
              of: find.text('Second page'),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(opacity.opacity, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'real learning tabs keep loaded API data across animated navigation',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        PrefsKeys.language: 'en',
        'subject_7': 'biologiya',
        'class_7': '5',
      });
      final prefs = await PrefsService.create();
      final dio = reviewDio();
      final requests = <String>[];
      dio.interceptors.add(_RequestRecorder(requests));
      addTearDown(() => dio.close(force: true));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsServiceProvider.overrideWithValue(prefs),
            currentUserIdProvider.overrideWithValue(7),
            authControllerProvider.overrideWith(FakeAuth.new),
            dioProvider.overrideWithValue(dio),
            learningPreferencesProvider.overrideWithValue(
              OfflinePreferences(prefs),
            ),
            skillTreeRepositoryProvider.overrideWithValue(
              SkillTreeRepository(dio),
            ),
            skillExtrasRepositoryProvider.overrideWithValue(
              SkillExtrasRepository(dio, 'en'),
            ),
          ],
          child: MaterialApp(
            theme: buildAppTheme(lightColors),
            home: const SubjectHomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final name in ['Practice', 'Quests', 'League', 'Profile', 'Learn']) {
        await tester.tap(find.text(name).last);
        await tester.pumpAndSettle();
      }
      final count = requests.length;
      for (final name in ['Profile', 'Quests', 'League', 'Learn']) {
        await tester.tap(find.text(name).last);
        await tester.pumpAndSettle();
      }
      expect(requests.length, count);
      expect(find.text('0/20 XP'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final dark in [false, true]) {
    testWidgets('navigation vector golden ${dark ? 'dark' : 'light'}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 160);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      var selected = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(dark ? darkColors : lightColors),
          home: RepaintBoundary(
            key: key,
            child: StatefulBuilder(
              builder: (context, set) => Scaffold(
                bottomNavigationBar: IlmBottomNavigation(
                  index: selected,
                  items: _items,
                  onChanged: (i) => set(() => selected = i),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(key),
        matchesGoldenFile(
          'goldens/ilm_navigation_${dark ? 'dark' : 'light'}.png',
        ),
      );
      if (const bool.fromEnvironment('NAV_CAPTURE')) {
        final folder = Directory(
          '.dart_tool/navigation-review/${dark ? 'dark' : 'light'}',
        )..createSync(recursive: true);
        Future<void> save(int frame) async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 2);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await File(
              '${folder.path}/frame-${frame.toString().padLeft(3, '0')}.png',
            ).writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }

        var frame = 0;
        await save(frame++);
        for (final label in [
          'Practice',
          'Quests',
          'League',
          'Profile',
          'Learn',
        ]) {
          await tester.tap(find.text(label));
          await tester.pump();
          for (var tick = 0; tick < 20; tick++) {
            await tester.pump(const Duration(milliseconds: 20));
            await save(frame++);
          }
        }
      }
    });
  }
}
