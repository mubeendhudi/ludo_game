import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

/// Which of the 9 grid slots carry a dot, per face (1..6).
const List<List<int>> _kFaces = [
  [4],
  [0, 8],
  [0, 4, 8],
  [0, 2, 6, 8],
  [0, 2, 4, 6, 8],
  [0, 2, 3, 5, 6, 8],
];

/// One player's dice. Spins while [rolling]; glows and is tappable only when [ready].
class DiceWidget extends StatefulWidget {
  const DiceWidget({
    super.key,
    required this.face,
    required this.rolling,
    required this.ready,
    required this.color,
    required this.size,
    required this.onTap,
  });

  final int face;
  final bool rolling;
  final bool ready;
  final Color color;
  final double size;
  final VoidCallback onTap;

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  final _rng = Random();
  Timer? _timer;
  int _shown = 1;

  @override
  void initState() {
    super.initState();
    _shown = widget.face;
    if (widget.rolling) _startRoll();
  }

  @override
  void didUpdateWidget(covariant DiceWidget old) {
    super.didUpdateWidget(old);
    if (widget.rolling && !old.rolling) {
      _startRoll();
    } else if (!widget.rolling) {
      if (old.rolling) _stopRoll();
      _shown = widget.face;
    }
  }

  void _startRoll() {
    _spin.repeat();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 85), (_) {
      if (mounted) setState(() => _shown = _rng.nextInt(6) + 1);
    });
  }

  void _stopRoll() {
    _timer?.cancel();
    _spin.stop();
    _spin.reset();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final on = _kFaces[_shown - 1].toSet();
    final dot = Container(
      width: s * .15,
      height: s * .15,
      decoration:
      const BoxDecoration(color: Color(0xFF111111), shape: BoxShape.circle),
    );

    final face = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: s,
      height: s,
      padding: EdgeInsets.all(s * .1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s * .2),
        border: Border.all(color: widget.color, width: 4),
        boxShadow: [
          BoxShadow(
            color: widget.ready ? widget.color : Colors.black54,
            blurRadius: widget.ready ? 16 : 4,
            spreadRadius: widget.ready ? 2 : 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var r = 0; r < 3; r++)
            Expanded(
              child: Row(
                children: [
                  for (var c = 0; c < 3; c++)
                    Expanded(
                      child: Center(child: on.contains(r * 3 + c) ? dot : null),
                    ),
                ],
              ),
            ),
        ],
      ),
    );

    return Semantics(
      button: true,
      enabled: widget.ready,
      label: 'Roll dice',
      child: GestureDetector(
        onTap: widget.ready ? widget.onTap : null,
        child: RotationTransition(turns: _spin, child: face),
      ),
    );
  }
}