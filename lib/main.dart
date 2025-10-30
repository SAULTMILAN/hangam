import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => HangmanState(),
      child: const HangmanApp(),
    ),
  );
}

class HangmanApp extends StatelessWidget {
  const HangmanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Hangman (No Drawing)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const HangmanScreen(),
    );
  }
}

/// -----------------------------
/// STATE (Provider / ChangeNotifier)
/// -----------------------------
class HangmanState extends ChangeNotifier {
  static const int maxWrong = 6;

  // Uppercase word bank with no spaces.
  final List<String> _wordBank = const [
    'HAPPY',
    'PYTHON',
    'JAVASCRIPT',
    'NETWORK',
    'REFLECT',
    'TORONTO',
    'COLLEGE',
    'PROGRAM',
    'SUCCESS',
    'WALMART',
    'PACKET',
    'ROUTER',
    'SWITCH',
    'FREEDOM',
    'PROJECT',
    'GITHUB',
    'FLUTTER',
    'SERVER',
    'LINUX',
    'WINDOWS',
  ];

  late String _secret;
  String _lastSecret = '';
  final Set<String> _guessed = {}; // all unique guesses
  final Set<String> _wrong = {};   // unique wrong guesses
  bool _gameOver = false;
  bool _win = false;
  int _round = 1;

  HangmanState() {
    _pickNewWord();
  }

  // Getters for UI
  String get secret => _secret;
  int get wrongCount => _wrong.length;
  int get wrongLeft => maxWrong - _wrong.length;
  bool get isGameOver => _gameOver;
  bool get isWin => _win;
  int get round => _round;
  List<String> get guessedSorted => _guessed.toList()..sort();

  /// Public API: handle a letter guess (A-Z)
  void guess(String rawLetter) {
    if (_gameOver) return;
    final letter = rawLetter.toUpperCase();
    if (!_isAlphabet(letter)) return;

    // If already guessed, ignore (wrong counts only once)
    if (_guessed.contains(letter)) return;

    _guessed.add(letter);

    if (_secret.contains(letter)) {
      // reveal handled by getter
    } else {
      _wrong.add(letter); // Set => counts once
    }

    // End checks
    if (_isFullyRevealed()) {
      _gameOver = true;
      _win = true;
    } else if (_wrong.length >= maxWrong) {
      _gameOver = true;
      _win = false;
    }

    notifyListeners();
  }

  /// Reveal status per character, e.g., "H _ P P Y"
  List<String> get revealedChars {
    return _secret.split('').map((ch) {
      if (ch == '-') return '-';
      return _guessed.contains(ch) ? ch : '_';
    }).toList();
  }

  /// Start a new round, ensuring a different word than the last one
  void playAgain() {
    _round += 1;
    _pickNewWord();
    notifyListeners();
  }

  void _pickNewWord() {
    final pool = _wordBank.where((w) => w != _lastSecret).toList();
    final rng = Random();
    _secret = (pool.isNotEmpty ? pool : _wordBank)[rng.nextInt(pool.isNotEmpty ? pool.length : _wordBank.length)];
    _lastSecret = _secret;
    _guessed.clear();
    _wrong.clear();
    _gameOver = false;
    _win = false;
  }

  bool _isFullyRevealed() {
    for (final ch in _secret.split('')) {
      if (ch == '-') continue;
      if (!_guessed.contains(ch)) return false;
    }
    return true;
  }

  bool _isAlphabet(String s) {
    if (s.length != 1) return false;
    final code = s.codeUnitAt(0);
    return code >= 65 && code <= 90; // A-Z
  }
}

/// -----------------------------
/// UI
/// -----------------------------
class HangmanScreen extends StatelessWidget {
  const HangmanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HangmanState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hangman – No Drawing'),
        centerTitle: true,
      ),
      body: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Stats row
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _pill('Wrong left', state.wrongLeft.toString()),
                _pill('Wrong made', state.wrongCount.toString()),
                _pill('Round', state.round.toString()),
              ],
            ),
            const SizedBox(height: 18),

            // Word display
            _WordDisplay(revealed: state.revealedChars),

            const SizedBox(height: 12),

            // Game status (now also shows final guessed letters)
            _GameStatus(),

            const SizedBox(height: 8),

            // Guessed letters (live) — only while playing
            if (!state.isGameOver) _GuessedList(),

            const SizedBox(height: 12),

            // Keyboard
            const Expanded(child: _KeyboardGrid()),

            // Controls
            const SizedBox(height: 12),
            _ControlsBar(),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, String value) {
    return Chip(
      labelPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      side: const BorderSide(color: Colors.white24),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _WordDisplay extends StatelessWidget {
  const _WordDisplay({required this.revealed});
  final List<String> revealed;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.displaySmall?.copyWith(
          letterSpacing: 6,
          fontWeight: FontWeight.w800,
        );

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Wrap(
          alignment: WrapAlignment.center,
          runSpacing: 8,
          spacing: 8,
          children: revealed
              .map((ch) => Container(
                    width: 34,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.only(bottom: 4),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.white24, width: 2),
                      ),
                    ),
                    // Show underscores visibly so the slots aren't blank
                    child: Text(ch == '_' ? '_' : ch, style: style),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _GameStatus extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<HangmanState>();

    if (!state.isGameOver) {
      return const Text(
        'Guess letters using the on-screen keyboard.',
        textAlign: TextAlign.center,
      );
    }

    final guessed = state.guessedSorted;
    final guessedText = guessed.isEmpty ? '—' : guessed.join(', ');

    return Column(
      children: [
        Text(
          state.isWin ? 'YOU WON!' : 'YOU LOST!',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: state.isWin ? Colors.greenAccent : Colors.redAccent,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Word: ${state.secret}',
          style: const TextStyle(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Guessed letters: $guessedText',
          textAlign: TextAlign.center,
        ),
        // If you also want the wrong count here, uncomment below:
        // const SizedBox(height: 2),
        // Text('Wrong guesses made: ${state.wrongCount}'),
      ],
    );
  }
}

class _GuessedList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final guessed = context.watch<HangmanState>().guessedSorted;
    final content = guessed.isEmpty ? '—' : guessed.join(', ');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Guessed letters: ',
            style: TextStyle(color: Colors.white70)),
        Text(
          content,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _KeyboardGrid extends StatelessWidget {
  const _KeyboardGrid();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HangmanState>();
    final letters = List.generate(26, (i) => String.fromCharCode(65 + i));
    final isOver = state.isGameOver;

    return GridView.count(
      crossAxisCount: 7,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (final ch in letters)
          _LetterKey(
            letter: ch,
            disabled: isOver || state.guessedSorted.contains(ch),
            correct: state.secret.contains(ch) &&
                state.guessedSorted.contains(ch),
            wrong: !state.secret.contains(ch) &&
                state.guessedSorted.contains(ch),
          ),
      ],
    );
  }
}

class _LetterKey extends StatelessWidget {
  const _LetterKey({
    required this.letter,
    required this.disabled,
    required this.correct,
    required this.wrong,
  });

  final String letter;
  final bool disabled;
  final bool correct;
  final bool wrong;

  @override
  Widget build(BuildContext context) {
    final state = context.read<HangmanState>();
    final bg = correct
        ? Colors.green.withOpacity(.25)
        : wrong
            ? Colors.red.withOpacity(.25)
            : null;

    return ElevatedButton(
      onPressed: disabled ? null : () => state.guess(letter),
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        disabledBackgroundColor: (correct
                ? Colors.green.withOpacity(.15)
                : wrong
                    ? Colors.red.withOpacity(.15)
                    : Colors.white10)
            .withOpacity(.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: Text(
        letter,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ControlsBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: () => context.read<HangmanState>().playAgain(),
          icon: const Icon(Icons.refresh),
          label: const Text('Play Again (new word)'),
        ),
        const SizedBox(width: 12),
        // Reveal button for testing; remove before submitting if not allowed
        OutlinedButton.icon(
          onPressed: () {
            final word = context.read<HangmanState>().secret;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Secret: $word')),
            );
          },
          icon: const Icon(Icons.visibility_outlined),
          label: const Text('Reveal (test)'),
        ),
      ],
    );
  }
}
