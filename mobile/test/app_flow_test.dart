import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kettik/app.dart';
import 'package:kettik/data/demo_data.dart';
import 'package:kettik/data/games_store.dart';

void main() {
  late DateTime now;
  late GamesStore store;

  Future<void> start(WidgetTester t) async {
    // A phone, not the default 800×600 test window.
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    now = DateTime(2026, 11, 25, 19, 40);
    store = GamesStore(demoGames(), me: demoMe);
    await t.pumpWidget(KettikApp(store: store, now: () => now));
  }

  // Screens with a running timer never settle, so step the clock instead.
  Future<void> step(WidgetTester t) async {
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('taking the last place and paying confirms the game', (t) async {
    await start(t);
    await t.tap(find.text('Манеж Alem').first);
    await step(t);
    await t.tap(find.textContaining('Занять №12'));
    await step(t);
    expect(find.text('Место №12 за вами'), findsOneWidget);

    await t.tap(find.textContaining('Оплатить'));
    await step(t);
    expect(find.text('Игра состоится'), findsOneWidget);
  });

  testWidgets('an unpaid hold shows on the feed until it is paid', (t) async {
    await start(t);
    await t.tap(find.text('NIS Mangilik Arena'));
    await step(t);
    await t.tap(find.textContaining('Занять №14'));
    await step(t);

    await t.tap(find.byTooltip('Назад к игре'));
    await step(t);
    await t.tap(find.byTooltip('Назад'));
    await step(t);
    expect(find.textContaining('Место №14 держим ещё'), findsOneWidget);

    await t.tap(find.textContaining('Место №14 держим ещё'));
    await step(t);
    await t.tap(find.textContaining('Оплатить'));
    await step(t);
    expect(find.text('Вы в составе · №14'), findsOneWidget);

    await t.tap(find.byTooltip('Назад'));
    await step(t);
    expect(find.textContaining('держим ещё'), findsNothing);
  });

  testWidgets('a hold that runs out frees the place', (t) async {
    await start(t);
    await t.tap(find.text('NIS Mangilik Arena'));
    await step(t);
    await t.tap(find.textContaining('Занять №14'));
    await step(t);

    now = now.add(const Duration(minutes: 11));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Время вышло'), findsOneWidget);
    expect(find.textContaining('Оплатить'), findsNothing);
  });

  testWidgets('the share per player follows the squad size', (t) async {
    await start(t);
    await t.tap(find.text('Собрать'));
    await step(t);
    expect(find.textContaining('3 300 ₸'), findsWidgets);

    await t.tap(find.byTooltip('Больше игроков'));
    await t.pump();
    expect(find.textContaining('от 3 093 ₸'), findsWidgets);
  });

  testWidgets('profile lists my games', (t) async {
    await start(t);
    await t.tap(find.text('Профиль'));
    await step(t);
    expect(find.text('Мои игры'), findsOneWidget);
    expect(find.text('Spartak Indoor'), findsWidgets);
  });

  testWidgets('a confirmed game of mine opens as a ticket with my number', (t) async {
    await start(t);
    await t.tap(find.text('Профиль'));
    await step(t);
    await t.tap(find.textContaining('21:30 · место №4'));
    await step(t);
    expect(find.text('Номер'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('21:30'), findsOneWidget);
  });
}
