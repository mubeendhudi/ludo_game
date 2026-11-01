import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ludo_constants.dart';
import '../../data/models/ludo_state.dart';
import '../../data/providers/ludo_provider.dart';
import 'board_painter.dart';

class _Tk {
  _Tk(this.c, this.i, Offset pos)
      : x = pos.dx,
        y = pos.dy;

  final int c;
  final int i;
  double x;
  double y;
  double scale = 1;
  int z = 0;
}

/// The Ludo board: painted background + animated tokens on top.
class LudoBoard extends ConsumerWidget {
  const LudoBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(ludoProvider);
    final notifier = ref.read(ludoProvider.notifier);

    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF1D58A), width: 5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(150),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: LayoutBuilder(
            builder: (context, box) {
              final u = box.maxWidth / 15;

              // Collect tokens and group those sharing a cell so they can be fanned out.
              final groups = <String, List<_Tk>>{};
              for (var c = 0; c < 4; c++) {
                if (s.modes[c] == PlayerMode.off) continue;
                for (var i = 0; i < 4; i++) {
                  final pos = tokenPos(c, i, s.pcs[c][i]);
                  groups
                      .putIfAbsent('${pos.dx}_${pos.dy}', () => [])
                      .add(_Tk(c, i, pos));
                }
              }
              final all = <_Tk>[];
              for (final g in groups.values) {
                final n = g.length;
                for (var j = 0; j < n; j++) {
                  final t = g[j];
                  if (n > 1) {
                    t.x += (j - (n - 1) / 2) * .32;
                    t.y += (j - (n - 1) / 2) * .1;
                    t.scale = .78;
                  }
                  final mine = t.c == s.cur;
                  t.z = mine && s.movingIdx == t.i
                      ? 2
                      : (mine && s.movable.contains(t.i) ? 1 : 0);
                  all.add(t);
                }
              }
              all.sort((a, b) {
                final z = a.z.compareTo(b.z);
                return z != 0 ? z : (a.c * 4 + a.i).compareTo(b.c * 4 + b.i);
              });

              final slot = u; // tap target = one cell
              return Stack(
                children: [
                  const Positioned.fill(
                    child: CustomPaint(painter: BoardPainter()),
                  ),
                  for (final t in all)
                    AnimatedPositioned(
                      key: ValueKey('tk${t.c}_${t.i}'),
                      duration: const Duration(milliseconds: 170),
                      curve: Curves.linear,
                      left: t.x * u - slot / 2,
                      top: t.y * u - slot / 2,
                      width: slot,
                      height: slot,
                      child: _tokenTap(s, notifier, t, u),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _tokenTap(LudoState s, LudoNotifier notifier, _Tk t, double u) {
    final canTap =
        s.phase == Phase.move && t.c == s.cur && s.movable.contains(t.i);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: canTap ? () => notifier.moveToken(t.i) : null,
      child: AnimatedScale(
        scale: t.scale,
        duration: const Duration(milliseconds: 150),
        child: Center(
          child: PieceView(color: kColors[t.c], size: u * .705, pulse: canTap),
        ),
      ),
    );
  }
}

/// A single Ludo token. Pulses with a white glow when it can be moved.
class PieceView extends StatefulWidget {
  const PieceView({
    super.key,
    required this.color,
    required this.size,
    this.pulse = false,
  });

  final Color color;
  final double size;
  final bool pulse;

  @override
  State<PieceView> createState() => _PieceViewState();
}

class _PieceViewState extends State<PieceView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant PieceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse) {
      if (!_ctrl.isAnimating) _ctrl.repeat(reverse: true);
    } else {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    final piece = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-.3, -.4),
          radius: .9,
          colors: [
            Color.lerp(c, Colors.white, .55)!,
            c,
            Color.lerp(c, Colors.black, .35)!,
          ],
          stops: const [0, .5, 1],
        ),
        border: Border.all(color: Colors.white, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(140),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
          if (widget.pulse)
            const BoxShadow(color: Colors.white, blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: Center(
        child: Container(
          width: widget.size * .48,
          height: widget.size * .48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withAlpha(150), width: 1.6),
          ),
        ),
      ),
    );

    if (!widget.pulse) return piece;
    return ScaleTransition(
      scale: Tween<double>(begin: 1, end: 1.25).animate(_ctrl),
      child: piece,
    );
  }
}