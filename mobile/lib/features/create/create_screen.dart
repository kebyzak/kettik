import 'package:material_ui/material_ui.dart';

import 'package:kettik/core/data/games_store.dart';
import 'package:kettik/core/domain/game.dart';
import 'package:kettik/core/domain/money.dart';
import 'package:kettik/core/scope.dart';
import 'package:kettik/core/ui/format.dart';
import 'package:kettik/core/ui/parts.dart';
import 'package:kettik/core/ui/theme.dart';
import 'package:kettik/features/auth/sign_in.dart';
import 'package:kettik/features/booking/hold_screen.dart';
import 'package:kettik/core/ui/words.dart';

const _durations = [60, 90, 120];
const _days = 7;
const minSize = 6;
const maxSize = 22;

int _teamsFor(int size) => size % 3 == 0 && size >= 12 ? 3 : 2;

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  List<Pitch>? _pitches;
  var _pitch = 0;
  var _day = 0;
  var _duration = 1;
  List<Slot>? _slots;
  DateTime? _start;
  var _size = 15;
  var _level = 0;
  Rejection? _loadFailed;

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime _date(int i) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + i);
  }

  Future<void> _load() async {
    final store = context.getInheritedWidgetOfExactType<AppScope>()!.store;
    try {
      final pitches = _pitches ?? await store.pitches();
      final slots = pitches.isEmpty
          ? const <Slot>[]
          : await store.slots(
              pitches[_pitch].fieldId,
              _date(_day),
              _durations[_duration],
            );
      if (!mounted) return;
      setState(() {
        _pitches = pitches;
        _slots = slots;
      });
    } on BookingRejected catch (e) {
      if (mounted) setState(() => _loadFailed = e.reason);
    }
  }

  void _choose(VoidCallback change) {
    setState(() {
      change();
      _slots = null;
      _loadFailed = null;
    });
    _load();
  }

  Future<void> _create(Slot slot) async {
    final me = await signIn(context);
    if (me == null || !mounted) return;
    final store = AppScope.of(context).store;
    final String id;
    try {
      id = await store.create(
        fieldId: _pitches![_pitch].fieldId,
        start: slot.start,
        end: slot.end,
        size: _size,
        teams: _teamsFor(_size),
        level: Level.values[_level],
      );
    } on BookingRejected catch (e) {
      if (!mounted) return;
      tell(context, e.reason);
      setState(() => _start = null);
      _load();
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => HoldScreen(gameId: id, number: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = AppScope.of(context).now();
    final l = context.l10n;
    final pitches = _pitches;
    if (pitches == null || pitches.isEmpty) {
      return _Loading(
        failed: _loadFailed,
        empty: pitches != null,
        retry: () => _choose(() {}),
      );
    }
    final open = [
      for (final s in _slots ?? const <Slot>[])
        if (now.isBefore(fundingDeadline(createdAt: now, start: s.start))) s,
    ];
    final slot =
        open.where((s) => s.start == _start).firstOrNull ?? open.firstOrNull;
    final shares = splitRent(slot?.rent ?? const Tenge(0), _size);
    final perPlayer = shares.first == shares.last
        ? formatTenge(shares.last)
        : l.fromAmount(formatTenge(shares.last));
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(
              children: [
                Text(l.createGame, style: display(22)),
                const Spacer(),
                Transform.translate(
                  offset: const Offset(12, 0),
                  child: Back(tooltip: l.close, icon: Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < pitches.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PitchTile(
                  pitches[i],
                  selected: i == _pitch,
                  onTap: () => _choose(() => _pitch = i),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _days,
                separatorBuilder: (context, i) => const SizedBox(width: 8),
                itemBuilder: (context, i) => SizedBox(
                  width: 96,
                  child: _Choice(
                    label: switch (i) {
                      0 => l.today,
                      1 => l.tomorrow,
                      _ => shortDay(l, _date(i)),
                    },
                    selected: i == _day,
                    enabled: true,
                    onTap: () => _choose(() => _day = i),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _Segmented(
              labels: [l.duration60, l.duration90, l.duration120],
              selected: _duration,
              onSelect: (i) => _choose(() => _duration = i),
            ),
            _Label(l.startOn(longDate(l, _date(_day)))),
            if (_loadFailed case final failed?)
              Text(rejectionText(l, failed), style: body(15, color: K.ink2))
            else if (_slots == null)
              const Center(child: CircularProgressIndicator(color: K.ink))
            else if (open.isEmpty)
              Text(l.noSlotsToday, style: body(15, color: K.ink2))
            else
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.8,
                children: [
                  for (final s in open)
                    _Choice(
                      label: hm(s.start),
                      selected: s == slot,
                      enabled: true,
                      numeric: true,
                      onTap: () => setState(() => _start = s.start),
                    ),
                ],
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
                            context.l10n.rentSplit(
                              formatTenge(slot?.rent ?? const Tenge(0)),
                              _size,
                            ),
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
                    hm(fundingDeadline(createdAt: now, start: slot.start)),
                  ),
                  style: body(13, color: K.ink2),
                ),
              ),
            PillButton(
              slot == null
                  ? context.l10n.noSlotsToday
                  : context.l10n.createAndPay(formatTenge(shares.first)),
              onPressed: slot == null ? null : () => _create(slot),
            ),
          ],
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({
    required this.failed,
    required this.empty,
    required this.retry,
  });

  final Rejection? failed;
  final bool empty;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(context.l10n.createGame, style: display(22)),
                const Spacer(),
                Back(tooltip: context.l10n.close, icon: Icons.close_rounded),
              ],
            ),
            const Spacer(),
            Center(
              child: failed == null && !empty
                  ? const CircularProgressIndicator(color: K.ink)
                  : Text(
                      failed == null
                          ? context.l10n.noVenues
                          : rejectionText(context.l10n, failed!),
                      textAlign: TextAlign.center,
                      style: body(15, color: K.ink2),
                    ),
            ),
            const Spacer(),
            if (failed != null || empty)
              PillButton(context.l10n.tryAgainShort, onPressed: retry),
          ],
        ),
      ),
    ),
  );
}

class _PitchTile extends StatelessWidget {
  const _PitchTile(this.pitch, {required this.selected, required this.onTap});

  final Pitch pitch;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Sheet(
          ring: selected ? K.ink : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${pitch.venue.name} · ${pitch.field}',
                style: body(15, weight: 600),
              ),
              Text(pitch.venue.address, style: body(13, color: K.ink2)),
            ],
          ),
        ),
      ),
    ),
  );
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
