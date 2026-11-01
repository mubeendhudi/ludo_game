import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ludo_constants.dart';
import '../models/ludo_state.dart';

/// Thrown internally when a game is abandoned while an async step is still waiting.
class _Cancelled implements Exception {
  const _Cancelled();
}

final ludoProvider =
NotifierProvider<LudoNotifier, LudoState>(LudoNotifier.new);

class LudoNotifier extends Notifier<LudoState> {
  final _rng = Random();
  int _gid = 0; // bumped on every new game, so stale timers do nothing
  int _sixes = 0;
  int _v = 0; // last rolled value

  @override
  LudoState build() => LudoState.initial();

  // ---------------------------------------------------------------- setup

  void setMode(int c, PlayerMode m) {
    final modes = [...state.modes];
    modes[c] = m;
    state = state.copyWith(modes: modes);
  }

  /// Starts a game with the current modes. Returns an error message, or null on success.
  String? start() {
    final active = state.modes.where((m) => m != PlayerMode.off).length;
    final humans = state.modes.where((m) => m == PlayerMode.human).length;
    if (active < 2) return 'Pick at least 2 players.';
    if (humans < 1) {
      return 'At least one colour must be a human Player (not all Computer).';
    }
    _gid++;
    _sixes = 0;
    final first = state.modes.indexWhere((m) => m != PlayerMode.off);
    state = LudoState.initial(modes: state.modes).copyWith(cur: first);
    final cpu = state.modes[first] == PlayerMode.cpu;
    _nextTurn(
      true,
      msg: '${kNames[first]} starts!${cpu ? '' : ' Tap your dice.'}',
    );
    return null;
  }

  /// Back to the setup screen (modes are kept).
  void newGame() {
    _gid++;
    state = LudoState.initial(modes: state.modes);
  }

  // ----------------------------------------------------------------- flow

  Future<void> _wait(int ms, int g) async {
    await Future<void>.delayed(Duration(milliseconds: ms));
    if (g != _gid) throw const _Cancelled();
  }

  void _nextTurn(bool extra, {String? msg}) {
    var cur = state.cur;
    if (!extra) {
      _sixes = 0;
      do {
        cur = (cur + 1) % 4;
      } while (state.modes[cur] == PlayerMode.off);
    }
    final cpu = state.modes[cur] == PlayerMode.cpu;
    state = state.copyWith(
      cur: cur,
      phase: Phase.roll,
      movable: const <int>{},
      movingIdx: -1,
      message: msg ??
          (extra
              ? '${kNames[cur]} rolls again!'
              : '${kNames[cur]}’s turn${cpu ? '' : ' — tap your dice'}'),
    );
    if (cpu) {
      final g = _gid;
      Future<void>.delayed(const Duration(milliseconds: 850), () {
        if (g == _gid) roll();
      });
    }
  }

  /// Rolls the current player's dice (called by the UI for humans, by the timer for CPU).
  Future<void> roll() async {
    if (state.phase != Phase.roll) return;
    final g = _gid;
    try {
      final c = state.cur;
      state = state.copyWith(phase: Phase.rolling);
      HapticFeedback.selectionClick();
      await _wait(650, g);

      final v = _rng.nextInt(6) + 1;
      _v = v;
      final faces = [...state.faces];
      faces[c] = v;
      state = state.copyWith(faces: faces);
      _sixes = v == 6 ? _sixes + 1 : 0;

      if (_sixes == 3) {
        state = state.copyWith(
            message: '${kNames[c]} rolled three 6s — turn lost!');
        await _wait(1300, g);
        _nextTurn(false);
        return;
      }

      final mv = _movable(c, v);
      if (mv.isEmpty) {
        state = state.copyWith(
            message: '${kNames[c]} rolled $v — no move possible');
        await _wait(1000, g);
        _nextTurn(false);
        return;
      }
      if (state.modes[c] == PlayerMode.cpu) {
        await _wait(500, g);
        await _doMove(_choose(mv), g);
        return;
      }
      if (mv.length == 1) {
        state = state.copyWith(message: 'You rolled $v');
        await _wait(400, g);
        await _doMove(mv.first, g);
        return;
      }
      state = state.copyWith(
        phase: Phase.move,
        movable: mv.toSet(),
        message: '${kNames[c]} rolled $v — tap a glowing token',
      );
    } on _Cancelled {
      return;
    }
  }

  /// Called when the human taps a glowing token.
  Future<void> moveToken(int i) async {
    if (state.phase != Phase.move || !state.movable.contains(i)) return;
    try {
      await _doMove(i, _gid);
    } on _Cancelled {
      return;
    }
  }

  Future<void> _doMove(int i, int g) async {
    final c = state.cur;
    final v = _v;
    state = state.copyWith(
        phase: Phase.anim, movable: const <int>{}, movingIdx: i);

    var cap = false;
    var home = false;

    if (state.pcs[c][i] < 0) {
      _setPos(c, i, 0);
      HapticFeedback.lightImpact();
      await _wait(280, g);
    } else {
      for (var k = 0; k < v; k++) {
        _setPos(c, i, state.pcs[c][i] + 1);
        HapticFeedback.selectionClick();
        await _wait(175, g);
      }
    }

    final np = state.pcs[c][i];
    if (np <= kLastTrack) {
      final a = absIndex(c, np);
      if (!kSafe.contains(a)) {
        final pcs = _copy(state.pcs);
        for (var o = 0; o < 4; o++) {
          if (o == c || state.modes[o] == PlayerMode.off) continue;
          for (var j = 0; j < 4; j++) {
            final q = pcs[o][j];
            if (q >= 0 && q <= kLastTrack && absIndex(o, q) == a) {
              pcs[o][j] = kYard;
              cap = true;
            }
          }
        }
        if (cap) {
          state = state.copyWith(
              pcs: pcs, message: '${kNames[c]} captured a token!');
          HapticFeedback.heavyImpact();
        }
      } else {
        state = state.copyWith(message: '${kNames[c]} is safe on star! ⭐️');
      }
    }
    if (np == kFinished) {
      home = true;
      state = state.copyWith(message: '${kNames[c]} reached home!');
      HapticFeedback.mediumImpact();
    }
    state = state.copyWith(movingIdx: -1);

    if (state.pcs[c].every((p) => p == kFinished)) {
      state = state.copyWith(
        phase: Phase.over,
        winner: c,
        message: '🏆 ${kNames[c]} wins!',
      );
      return;
    }
    await _wait(cap || home ? 650 : 200, g);
    _nextTurn(v == 6 || cap || home);
  }

  // ---------------------------------------------------------------- rules

  List<List<int>> _copy(List<List<int>> pcs) => [
    for (final l in pcs) [...l]
  ];

  void _setPos(int c, int i, int p) {
    final pcs = _copy(state.pcs);
    pcs[c][i] = p;
    state = state.copyWith(pcs: pcs);
  }

  /// Pieces that can move with roll [d]. Pieces in the yard are identical, so they count once.
  List<int> _movable(int c, int d) {
    final r = <int>[];
    var yard = false;
    for (var i = 0; i < 4; i++) {
      final p = state.pcs[c][i];
      if (p < 0) {
        if (d == 6 && !yard) {
          r.add(i);
          yard = true;
        }
      } else if (p + d <= kFinished) {
        r.add(i);
      }
    }
    return r;
  }

  /// True if an opponent is 1..6 cells behind absolute track cell [a].
  bool _danger(int c, int a) {
    for (var o = 0; o < 4; o++) {
      if (o == c || state.modes[o] == PlayerMode.off) continue;
      for (final q in state.pcs[o]) {
        if (q >= 0 && q <= kLastTrack) {
          final k = (a - absIndex(o, q) + 52) % 52;
          if (k >= 1 && k <= 6) return true;
        }
      }
    }
    return false;
  }

  /// Simple CPU brain: finish > capture > leave yard > enter home column > safe squares,
  /// and avoid ending next to an opponent.
  int _choose(List<int> mv) {
    final c = state.cur;
    var best = mv.first;
    var bs = -1e9;
    for (final i in mv) {
      final p = state.pcs[c][i];
      final np = p < 0 ? 0 : p + _v;
      var s = np * .6 + _rng.nextDouble();
      if (np == kFinished) s += 100;
      if (p < 0) s += 55;
      if (np > kLastTrack && np < kFinished) s += 45;
      if (np <= kLastTrack) {
        final a = absIndex(c, np);
        if (kSafe.contains(a)) {
          s += 28;
        } else {
          for (var o = 0; o < 4; o++) {
            if (o == c || state.modes[o] == PlayerMode.off) continue;
            for (final q in state.pcs[o]) {
              if (q >= 0 && q <= kLastTrack && absIndex(o, q) == a) s += 85;
            }
          }
          if (_danger(c, a)) s -= 30;
        }
        if (p >= 0 &&
            !kSafe.contains(absIndex(c, p)) &&
            _danger(c, absIndex(c, p))) {
          s += 22; // run away from danger
        }
      }
      if (s > bs) {
        bs = s;
        best = i;
      }
    }
    return best;
  }
}