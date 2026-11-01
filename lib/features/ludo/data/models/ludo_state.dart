import 'package:flutter/foundation.dart';

enum PlayerMode { off, human, cpu }

enum Phase { idle, roll, rolling, move, anim, over }

@immutable
class LudoState {
  const LudoState({
    required this.modes,
    required this.pcs,
    required this.cur,
    required this.faces,
    required this.phase,
    required this.movable,
    required this.message,
    this.movingIdx = -1,
    this.winner,
  });

  factory LudoState.initial({List<PlayerMode>? modes}) => LudoState(
    modes: modes ??
        const [
          PlayerMode.human,
          PlayerMode.cpu,
          PlayerMode.cpu,
          PlayerMode.cpu,
        ],
    pcs: List.generate(4, (_) => List.filled(4, -1)),
    cur: 0,
    faces: const [3, 4, 5, 6],
    phase: Phase.idle,
    movable: const <int>{},
    message: 'Welcome!',
  );

  /// Per colour: off / human / computer.
  final List<PlayerMode> modes;

  /// pcs[colour][piece] = progress (-1 yard, 0..50 track, 51..55 home column, 56 finished).
  final List<List<int>> pcs;

  /// Colour whose turn it is.
  final int cur;

  /// Last rolled face shown on each player's own dice.
  final List<int> faces;
  final Phase phase;

  /// Pieces of the current player that may be tapped.
  final Set<int> movable;
  final String message;
  final int movingIdx;
  final int? winner;

  bool isActive(int c) => modes[c] != PlayerMode.off;

  /// Only the current human player's dice is tappable, and only before rolling.
  bool canRoll(int c) =>
      phase == Phase.roll && cur == c && modes[c] == PlayerMode.human;

  bool isCurrent(int c) =>
      isActive(c) && cur == c && phase != Phase.idle && phase != Phase.over;

  int finished(int c) => pcs[c].where((p) => p == 56).length;

  LudoState copyWith({
    List<PlayerMode>? modes,
    List<List<int>>? pcs,
    int? cur,
    List<int>? faces,
    Phase? phase,
    Set<int>? movable,
    String? message,
    int? movingIdx,
    int? winner,
  }) =>
      LudoState(
        modes: modes ?? this.modes,
        pcs: pcs ?? this.pcs,
        cur: cur ?? this.cur,
        faces: faces ?? this.faces,
        phase: phase ?? this.phase,
        movable: movable ?? this.movable,
        message: message ?? this.message,
        movingIdx: movingIdx ?? this.movingIdx,
        winner: winner ?? this.winner,
      );
}