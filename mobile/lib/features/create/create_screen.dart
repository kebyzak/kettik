import 'package:material_ui/material_ui.dart';

import 'package:kettik/core/data/demo_data.dart';
import 'package:kettik/core/domain/game.dart';
import 'package:kettik/core/domain/money.dart';
import 'package:kettik/core/scope.dart';
import 'package:kettik/core/ui/format.dart';
import 'package:kettik/core/ui/parts.dart';
import 'package:kettik/core/ui/theme.dart';
import 'package:kettik/features/auth/sign_in.dart';
import 'package:kettik/features/booking/hold_screen.dart';
import 'package:kettik/core/ui/words.dart';

const _hourly = Tenge(33000);
const _slots = [(20, 0), (21, 0), (21, 30), (22, 0), (22, 30), (23, 0)];
const _bookedSlots = {(21, 0), (23, 0)};
const _durations = [60, 90, 120];
const minSize = 6;
const maxSize = 22;

int _teamsFor(int size) => size % 3 == 0 && size >= 12 ? 3 : 2;

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
      end: start.add(Duration(minutes: _durations[_duration])),
      rent: _rent,
      size: _size,
      teams: _teamsFor(_size),
      level: Level.values[_level],
      now: now,
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => HoldScreen(gameId: id, number: 1),
      ),
    );
  }

  Tenge get _rent => Tenge(_hourly.value * _durations[_duration] ~/ 60);

  @override
  Widget build(BuildContext context) {
    final now = AppScope.of(context).now();
    final slot = _slot ?? _slots.where((s) => _open(now, s)).firstOrNull;
    final shares = splitRent(_rent, _size);
    final perPlayer = shares.first == shares.last
        ? formatTenge(shares.last)
        : context.l10n.fromAmount(formatTenge(shares.last));
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(
              children: [
                Text(context.l10n.createGame, style: display(22)),
                const Spacer(),
                Transform.translate(
                  offset: const Offset(12, 0),
                  child: Back(
                    tooltip: context.l10n.close,
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
                  Text(
                    context.l10n.pitchOne(nis.name),
                    style: body(15, weight: 600),
                  ),
                  Text(
                    context.l10n.artificialTurf(nis.address),
                    style: body(13, color: K.ink2),
                  ),
                ],
              ),
            ),
            _Label(context.l10n.startOn(longDate(context.l10n, now))),
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
              labels: [
                context.l10n.duration60,
                context.l10n.duration90,
                context.l10n.duration120,
              ],
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
                              Text(
                                context.l10n.players,
                                style: body(15, weight: 600),
                              ),
                              Text(
                                context.l10n.firstPlaceYours(
                                  formatName(
                                    context.l10n,
                                    _size,
                                    _teamsFor(_size),
                                  ),
                                ),
                                style: body(13, color: K.ink2),
                              ),
                            ],
                          ),
                        ),
                        _Step(
                          Icons.remove_rounded,
                          context.l10n.fewerPlayers,
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
                          context.l10n.morePlayers,
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
                                      context.l10n.youShort,
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
                            context.l10n.rentSplit(formatTenge(_rent), _size),
                            style: body(15, color: K.ink2),
                          ),
                        ),
                        Text(perPlayer, style: display(15)),
                        Text(
                          context.l10n.perPlayer,
                          style: body(15, color: K.ink2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _Label(context.l10n.level),
            _Segmented(
              labels: [
                for (final v in Level.values) levelName(context.l10n, v),
              ],
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
                  context.l10n.fundingClosesAt(
                    hm(fundingDeadline(createdAt: now, start: _at(now, slot))),
                  ),
                  style: body(13, color: K.ink2),
                ),
              ),
            PillButton(
              slot == null
                  ? context.l10n.noSlotsToday
                  : context.l10n.createAndPay(formatTenge(shares.first)),
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
      label: enabled ? null : context.l10n.slotTaken(label),
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
