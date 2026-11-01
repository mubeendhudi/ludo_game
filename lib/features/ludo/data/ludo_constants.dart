import 'dart:ui';

/// Player order is clockwise, matching the board: Blue (top-left), Yellow (top-right),
/// Green (bottom-right), Red (bottom-left).
const List<String> kNames = ['Blue', 'Yellow', 'Green', 'Red'];

const List<Color> kColors = [
  Color(0xFF2563EB),
  Color(0xFFEAB308),
  Color(0xFF16A34A),
  Color(0xFFDC2626),
];

/// Index on the 52-cell main track where each colour enters the board.
const List<int> kStart = [0, 13, 26, 39];

/// Star squares (the four start squares are safe too).
const List<int> kStarCells = [8, 21, 34, 47];
const Set<int> kSafe = {0, 8, 13, 21, 26, 34, 39, 47};

/// Top-left cell of each 6x6 yard on the 15x15 grid.
const List<Offset> kYardOrigin = [
  Offset(0, 0),
  Offset(9, 0),
  Offset(9, 9),
  Offset(0, 9),
];

/// Piece progress: -1 = in yard, 0..50 = main track, 51..55 = home column, 56 = finished.
const int kYard = -1;
const int kLastTrack = 50;
const int kFinished = 56;

/// 52-cell main track (clockwise, starting at Blue's start cell). Cell coordinates, not pixels.
final List<Offset> kPath = _buildPath();

List<Offset> _buildPath() {
  final p = <Offset>[];
  void a(int x, int y) => p.add(Offset(x.toDouble(), y.toDouble()));
  for (var x = 1; x <= 5; x++) {
    a(x, 6);
  }
  for (var y = 5; y >= 0; y--) {
    a(6, y);
  }
  a(7, 0);
  a(8, 0);
  for (var y = 1; y <= 5; y++) {
    a(8, y);
  }
  for (var x = 9; x <= 14; x++) {
    a(x, 6);
  }
  a(14, 7);
  a(14, 8);
  for (var x = 13; x >= 9; x--) {
    a(x, 8);
  }
  for (var y = 9; y <= 14; y++) {
    a(8, y);
  }
  a(7, 14);
  a(6, 14);
  for (var y = 13; y >= 9; y--) {
    a(6, y);
  }
  for (var x = 5; x >= 0; x--) {
    a(x, 8);
  }
  a(0, 7);
  a(0, 6);
  return p;
}

/// The 5 coloured cells leading to the centre, per colour.
final List<List<Offset>> kHome = [
  [for (var x = 1; x <= 5; x++) Offset(x.toDouble(), 7)],
  [for (var y = 1; y <= 5; y++) Offset(7, y.toDouble())],
  [for (var x = 13; x >= 9; x--) Offset(x.toDouble(), 7)],
  [for (var y = 13; y >= 9; y--) Offset(7, y.toDouble())],
];

/// Absolute track index of piece progress [p] for colour [c] (only valid for 0..50).
int absIndex(int c, int p) => (kStart[c] + p) % 52;

/// Centre of a token in board-cell units (0..15) for colour [c], piece [i], progress [p].
Offset tokenPos(int c, int i, int p) {
  if (p < 0) {
    final o = kYardOrigin[c];
    return Offset(o.dx + (i % 2 == 0 ? 2 : 4), o.dy + (i < 2 ? 2 : 4));
  }
  if (p <= kLastTrack) {
    return kPath[absIndex(c, p)] + const Offset(.5, .5);
  }
  if (p < kFinished) {
    return kHome[c][p - 51] + const Offset(.5, .5);
  }
  const d = [Offset(-.75, 0), Offset(0, -.75), Offset(.75, 0), Offset(0, .75)];
  final s = (i - 1.5) * .22;
  final dd = d[c];
  return Offset(
    7.5 + dd.dx + (dd.dx != 0 ? 0 : s),
    7.5 + dd.dy + (dd.dy != 0 ? 0 : s),
  );
}