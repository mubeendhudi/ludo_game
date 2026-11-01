import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ludo_constants.dart';
import '../../data/models/ludo_state.dart';
import '../../data/providers/ludo_provider.dart';
import 'game_screen.dart';

/// Choose who plays each colour. Needs 2+ players and at least 1 human.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  String? _error;

  void _start() {
    final err = ref.read(ludoProvider.notifier).start();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() => _error = null);
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const GameScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modes = ref.watch(ludoProvider.select((s) => s.modes));
    final notifier = ref.read(ludoProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎲', style: TextStyle(fontSize: 54)),
                  const SizedBox(height: 4),
                  const Text(
                    'Ludo Classic',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose who plays each colour.\nAt least 2 players, and at least 1 human Player.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 18),
                  for (var c = 0; c < 4; c++)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18233A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kColors[c], width: 1.5),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(radius: 11, backgroundColor: kColors[c]),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              kNames[c],
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          SegmentedButton<PlayerMode>(
                            showSelectedIcon: false,
                            style: const ButtonStyle(
                              visualDensity: VisualDensity.compact,
                            ),
                            segments: const [
                              ButtonSegment(
                                  value: PlayerMode.off, label: Text('Off')),
                              ButtonSegment(
                                  value: PlayerMode.human,
                                  label: Text('Player')),
                              ButtonSegment(
                                  value: PlayerMode.cpu, label: Text('CPU')),
                            ],
                            selected: {modes[c]},
                            onSelectionChanged: (v) =>
                                notifier.setMode(c, v.first),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    height: 28,
                    child: Center(
                      child: Text(
                        _error ?? '',
                        style: const TextStyle(color: Color(0xFFFCA5A5)),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _start,
                      child: const Text(
                        'Start game',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}