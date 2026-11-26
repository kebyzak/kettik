import 'package:flutter/material.dart';

import 'package:kettik/core/data/demo_data.dart';
import 'package:kettik/core/domain/game.dart';
import 'package:kettik/core/domain/money.dart';
import 'package:kettik/core/scope.dart';
import 'package:kettik/core/ui/format.dart';
import 'package:kettik/core/ui/parts.dart';
import 'package:kettik/core/ui/theme.dart';
import 'package:kettik/features/auth/sign_in.dart';
import 'package:kettik/features/booking/hold_screen.dart';

const _hourly = Tenge(33000);
const _slots = [(20, 0), (21, 0), (21, 30), (22, 0), (22, 30), (23, 0)];
const _bookedSlots = {(21, 0), (23, 0)};
const _durations = [(60, '1 час'), (90, '1,5 часа'), (120, '2 часа')];
const _levels = ['Любители', 'Средний', 'Сильный'];
const minSize = 6;
const maxSize = 22;

String formatFor(int size) {
  if (size % 3 == 0 && size >= 12) {
    return '${size ~/ 3}×${size ~/ 3}, три команды';
  }
  if (size.isEven) return '${size ~/ 2}×${size ~/ 2}';
  return '${size ~/ 2}×${size ~/ 2} с заменой';
}

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  (int, int)? _slot;
  var _duration = 1;
  var _size = 15;
  var _level = 0;

  DateTime _at(DateTime now, (int, int) s) =>
      DateTime(now.year, now.month, now.day, s.$1, s.$2);

  bool _open(DateTime now, (int, int) s) =>
      !_bookedSlots.contains(s) &&
      !_at(now, s).subtract(fundingCloseBeforeStart).isBefore(now);

  Future<void> _create(DateTime now, (int, int) slot) async {
    final me = await signIn(context);
    if (me == null || !mounted) return;
    final scope = AppScope.of(context);
    final start = _at(now, slot);
    final id = scope.store.create(
      organizer: me,
      venue: nis,
      start: start,
      end: start.add(Duration(minutes: _durations[_duration].$1)),
      rent: _rent,
      size: _size,
      format: formatFor(_size),
      level: _levels[_level],
      now: now,
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => HoldScreen(gameId: id, number: 1),
      ),
    );
  }

  Tenge get _rent => Tenge(_hourly.value * _durations[_duration].$1 ~/ 60);

  @override
  Widget build(BuildContext context) {
    final now = AppScope.of(context).now();
    final slot = _slot ?? _slots.where((s) => _open(now, s)).firstOrNull;
    final shares = splitRent(_rent, _size);
    final perPlayer = shares.first == shares.last
        ? formatTenge(shares.last)
        : 'от ${formatTenge(shares.last)}';
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(
              children: [
                Text('Собрать игру', style: display(22)),
                const Spacer(),
                Transform.translate(
                  offset: const Offset(12, 0),
                  child: const Back(
                    tooltip: 'Закрыть',
                    icon: Icons.close_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Sheet(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${nis.name} · поле 1', style: body(15, weight: 600)),
                  Text(
                    '${nis.address} · искусственная трава',
                    style: body(13, color: K.ink2),
                  ),
                ],
              ),
            ),
            _Label('${longDate(now)} · начало'),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.8,
              children: [
                for (final s in _slots)
                  _Choice(
                    label: hm(_at(now, s)),
                    selected: s == slot,
                    enabled: _open(now, s),
                    numeric: true,
                    onTap: () => setState(() => _slot = s),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _Segmented(
              labels: [for (final d in _durations) d.$2],
              selected: _duration,
              onSelect: (i) => setState(() => _duration = i),
            ),
            const SizedBox(height: 16),
            Sheet(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Игроков', style: body(15, weight: 600)),
                              Text(
                                '${formatFor(_size)} · первое место ваше',
                                style: body(13, color: K.ink2),
                              ),
                            ],
                          ),
                        ),
                        _Step(
                          Icons.remove_rounded,
                          'Меньше игроков',
                          _size > minSize
                              ? () => setState(() => _size--)
                              : null,
                        ),
                        SizedBox(
                          width: 48,
                          child: Text(
                            '$_size',
                            textAlign: TextAlign.center,
                            style: display(22),
                          ),
                        ),
                        _Step(
                          Icons.add_rounded,
                          'Больше игроков',
                          _size < maxSize
                              ? () => setState(() => _size++)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: ExcludeSemantics(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (var i = 0; i < _size; i++)
                            i == 0
                                ? Container(
                                    width: 24,
                                    height: 24,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: K.ink,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      'вы',
                                      style: display(9, color: K.sheet),
                                    ),
                                  )
                                : const SizedBox.square(
                                    dimension: 24,
                                    child: CustomPaint(
                                      painter: DashedCircle(K.dash),
                                    ),
                                  ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: K.line),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Аренда ${formatTenge(_rent)} : $_size',
                            style: body(15, color: K.ink2),
                          ),
                        ),
                        Text(perPlayer, style: display(15)),
                        Text(' с игрока', style: body(15, color: K.ink2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _Label('Уровень'),
            _Segmented(
              labels: _levels,
              selected: _level,
              onSelect: (i) => setState(() => _level = i),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (slot != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Сбор закроется в ${hm(fundingDeadline(createdAt: now, start: _at(now, slot)))}. '
                  'Не соберёмся — все получат деньги обратно.',
                  style: body(13, color: K.ink2),
                ),
              ),
            PillButton(
              slot == null
                  ? 'На сегодня свободного времени нет'
                  : 'Создать и оплатить · ${formatTenge(shares.first)}',
              onPressed: slot == null ? null : () => _create(now, slot),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: Text(text, style: display(13, weight: 500, color: K.ink2)),
  );
}

class _Step extends StatelessWidget {
  const _Step(this.icon, this.tooltip, this.onPressed);

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton.filled(
    tooltip: tooltip,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      backgroundColor: K.chalk,
      foregroundColor: K.ink,
      disabledBackgroundColor: K.chalk,
    ),
    icon: Icon(icon),
  );
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.numeric = false,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final bool numeric;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? K.sheet : (enabled ? K.ink : K.dash);
    final style = (numeric ? display(13) : body(15, weight: 600)).copyWith(
      color: fg,
      decoration: enabled ? null : TextDecoration.lineThrough,
    );
    return Semantics(
      selected: selected,
      enabled: enabled,
      label: enabled ? null : '$label, занято',
      child: Material(
        color: selected ? K.ink : (enabled ? K.sheet : Colors.transparent),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: enabled ? onTap : null,
          child: Center(child: Text(label, style: style)),
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: K.sheet,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: SizedBox(
              height: 40,
              child: _Choice(
                label: labels[i],
                selected: i == selected,
                enabled: true,
                onTap: () => onSelect(i),
              ),
            ),
          ),
      ],
    ),
  );
}
