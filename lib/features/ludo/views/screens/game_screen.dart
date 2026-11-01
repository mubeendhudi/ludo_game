import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ludo_constants.dart';
import '../../data/models/ludo_state.dart';
import '../../data/providers/ludo_provider.dart';
import '../widgets/ludo_board.dart';
import '../widgets/player_panel.dart';

/// Portrait (phones): Blue/Yellow dice above the board, Red/Green dice below.
/// Wide (tablet/landscape): Blue/Red dice on the left, Yellow/Green on the right.
class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<Phase>(
      ludoProvider.select((s) => s.phase),
          (prev, next) {
        if (next == Phase.over) _showWinner(context, ref);
      },
    );

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) ref.read(ludoProvider.notifier).newGame();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ludo Classic'),
          backgroundColor: Colors.transparent,
        ),
        body: SafeArea(
          child: Column(
            children: [
              const _MessageBar(),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) =>
                  box.maxWidth > box.maxHeight * 1.15
                      ? const _WideLayout()
                      : const _PortraitLayout(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWinner(BuildContext context, WidgetRef ref) {
    final w = ref.read(ludoProvider).winner ?? 0;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('🏆 ${kNames[w]} wins!'),
        content: const Text('All four tokens made it home. Great game!'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).popUntil((r) => r.isFirst),
            child: const Text('Menu'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(ludoProvider.notifier).start();
            },
            child: const Text('Rematch'),
          ),
        ],
      ),
    );
  }
}

class _MessageBar extends ConsumerWidget {
  const _MessageBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final msg = ref.watch(ludoProvider.select((s) => s.message));
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF18233A),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(msg, textAlign: TextAlign.center),
    );
  }
}

class _PortraitLayout extends StatelessWidget {
  const _PortraitLayout();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Expanded(child: PlayerPanel(index: 0)), // Blue
              SizedBox(width: 10),
              Expanded(child: PlayerPanel(index: 1)), // Yellow
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Center(child: LudoBoard()),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Row(
            children: [
              Expanded(child: PlayerPanel(index: 3)), // Red
              SizedBox(width: 10),
              Expanded(child: PlayerPanel(index: 2)), // Green
            ],
          ),
        ),
      ],
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          SizedBox(
            width: 210,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                PlayerPanel(index: 0), // Blue (top-left)
                PlayerPanel(index: 3), // Red (bottom-left)
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: LudoBoard()),
            ),
          ),
          SizedBox(
            width: 210,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                PlayerPanel(index: 1), // Yellow (top-right)
                PlayerPanel(index: 2), // Green (bottom-right)
              ],
            ),
          ),
        ],
      ),
    );
  }
}