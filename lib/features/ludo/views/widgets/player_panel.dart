import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ludo_constants.dart';
import '../../data/models/ludo_state.dart';
import '../../data/providers/ludo_provider.dart';
import 'dice_widget.dart';

/// One player's card with their own dice. Only the current player's card is lit up,
/// and only a human current player can tap the dice.
class PlayerPanel extends ConsumerWidget {
  const PlayerPanel({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(ludoProvider);
    final c = index;
    final color = kColors[c];
    final active = s.isActive(c);
    final on = s.isCurrent(c);
    final ready = s.canRoll(c);
    final rolling = on && s.phase == Phase.rolling;
    final cpu = s.modes[c] == PlayerMode.cpu;
    final done = s.finished(c);

    final status = ready
        ? 'Tap dice to roll'
        : (on && cpu ? 'Playing…' : '');

    final info = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          kNames[c],
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        Text(
          cpu ? 'Computer' : 'Player',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 28),
          child: Text(
            status,
            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 4; i++)
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsetsDirectional.only(end: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < done ? color : Colors.black45,
                  border: Border.all(color: Colors.white54, width: 1),
                ),
              ),
          ],
        ),
      ],
    );

    final dice = DiceWidget(
      face: s.faces[c],
      rolling: rolling,
      ready: ready,
      color: color,
      size: 58,
      onTap: () => ref.read(ludoProvider.notifier).roll(),
    );

    return Visibility(
      visible: active,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: AnimatedOpacity(
        opacity: on ? 1 : .45,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF18233A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color, width: 2),
            boxShadow: on
                ? [BoxShadow(color: color, blurRadius: 18, spreadRadius: 1)]
                : const [],
          ),
          child: Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: 6),
              dice,
            ],
          ),
        ),
      ),
    );
  }
}