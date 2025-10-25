import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/auth_controller.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authStateProvider);

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: switch (state.status) {
            AuthStatus.needsSetup => _PinSetupView(key: const ValueKey('setup'), state: state),
            AuthStatus.locked => _PinUnlockView(key: const ValueKey('unlock'), state: state),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }
}

class _PinSetupView extends ConsumerStatefulWidget {
  const _PinSetupView({super.key, required this.state});

  final AuthState state;

  @override
  ConsumerState<_PinSetupView> createState() => _PinSetupViewState();
}

class _PinSetupViewState extends ConsumerState<_PinSetupView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleKey(String value) {
    if (widget.state.processing) return;
    if (value == 'backspace') {
      if (_controller.text.isNotEmpty) {
        setState(() {
          _controller.text =
              _controller.text.substring(0, _controller.text.length - 1);
        });
        HapticFeedback.selectionClick();
      }
      return;
    }
    if (_controller.text.length >= 4) return;
    setState(() {
      _controller.text += value;
    });
    HapticFeedback.selectionClick();
    if (_controller.text.length == 4) {
      ref.read(authStateProvider.notifier).submitSetupPin(_controller.text);
      setState(() => _controller.clear());
    }
  }

  @override
  void didUpdateWidget(covariant _PinSetupView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.state.awaitingConfirmation && oldWidget.state.awaitingConfirmation) {
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authStateProvider.notifier);
    final label = widget.state.awaitingConfirmation
        ? 'Confirm 4-digit PIN'
        : 'Create a 4-digit PIN';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text('Secure your wallet', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Set a PIN to unlock the app. You can opt-in to biometrics if your device supports it.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          _PinDots(
            pin: _controller.text,
            shakeId: widget.state.errorVersion,
            allLit: widget.state.status == AuthStatus.authenticated,
          ),
          const SizedBox(height: 24),
          _PinPad(
            onKey: _handleKey,
            backspaceEnabled: _controller.text.isNotEmpty,
            showBiometricKey: false,
          ),
          if (widget.state.error != null) ...[
            const SizedBox(height: 12),
            Text(widget.state.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          if (widget.state.biometricsAvailable)
            SwitchListTile.adaptive(
              value: widget.state.biometricsEnabled,
              onChanged: widget.state.processing
                  ? null
                  : (value) => auth.setBiometricPreference(value),
              title: const Text('Unlock with biometrics'),
              subtitle: const Text('Use Face ID/Touch ID after entering the PIN once'),
            ),
          const Spacer(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PinUnlockView extends ConsumerStatefulWidget {
  const _PinUnlockView({super.key, required this.state});
  final AuthState state;

  @override
  ConsumerState<_PinUnlockView> createState() => _PinUnlockViewState();
}

class _PinUnlockViewState extends ConsumerState<_PinUnlockView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleKey(String value) {
    if (widget.state.processing) return;
    if (value == 'backspace') {
      if (_controller.text.isNotEmpty) {
        setState(() {
          _controller.text =
              _controller.text.substring(0, _controller.text.length - 1);
        });
        HapticFeedback.selectionClick();
      }
      return;
    }
    if (_controller.text.length >= 4) return;
    setState(() {
      _controller.text += value;
    });
    HapticFeedback.selectionClick();
    if (_controller.text.length == 4) {
      ref.read(authStateProvider.notifier).unlockWithPin(_controller.text);
      setState(() => _controller.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authStateProvider.notifier);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text('Unlock', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Enter your PIN to access Expense Tracker.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          _PinDots(
            pin: _controller.text,
            shakeId: widget.state.errorVersion,
          ),
          const SizedBox(height: 24),
          _PinPad(
            onKey: _handleKey,
            backspaceEnabled: _controller.text.isNotEmpty,
            showBiometricKey: widget.state.canUseBiometric,
            onBiometricTap: () {
              if (!widget.state.processing) {
                auth.tryBiometricUnlock(force: true);
              }
            },
          ),
          if (widget.state.error != null) ...[
            const SizedBox(height: 12),
            Text(widget.state.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          if (widget.state.biometricsAvailable)
            SwitchListTile.adaptive(
              value: widget.state.biometricsEnabled,
              onChanged: widget.state.processing
                  ? null
                  : (value) {
                      HapticFeedback.selectionClick();
                      auth.setBiometricPreference(value);
                    },
              title: const Text('Use biometrics'),
            ),
          const Spacer(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
class _PinDots extends StatefulWidget {
  const _PinDots({required this.pin, required this.shakeId, this.allLit = false});

  final String pin;
  final int shakeId;
  final bool allLit;

  @override
  State<_PinDots> createState() => _PinDotsState();
}

class _PinDotsState extends State<_PinDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _offset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant _PinDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shakeId != oldWidget.shakeId && widget.shakeId > 0) {
      _controller.forward(from: 0);
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_offset.value, 0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          final filled = widget.allLit || index < widget.pin.length;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant.withOpacity(0.4),
            ),
          );
        }),
      ),
    );
  }
}

class _PinPad extends StatelessWidget {
  const _PinPad({
    required this.onKey,
    required this.backspaceEnabled,
    required this.showBiometricKey,
    this.onBiometricTap,
  });

  final ValueChanged<String> onKey;
  final bool backspaceEnabled;
  final bool showBiometricKey;
  final VoidCallback? onBiometricTap;

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      [showBiometricKey ? 'bio' : '', '0', 'backspace'],
    ];
    return Column(
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: row.map((label) {
            return _PinKey(
              label: label,
              onPressed: () {
                if (label == 'backspace') {
                  if (backspaceEnabled) onKey(label);
                } else if (label == 'bio') {
                  onBiometricTap?.call();
                } else if (label.isNotEmpty) {
                  onKey(label);
                }
              },
              disabled: (label == 'backspace' && !backspaceEnabled) || label.isEmpty,
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

class _PinKey extends StatelessWidget {
  const _PinKey({
    required this.label,
    required this.onPressed,
    this.disabled = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    IconData? icon;
    if (label == 'backspace') {
      icon = Icons.backspace_outlined;
    } else if (label == 'bio') {
      icon = Icons.fingerprint;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: 80,
        height: 60,
        child: ElevatedButton(
          onPressed: disabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
          child: icon != null
              ? Icon(icon)
              : Text(
                  label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
        ),
      ),
    );
  }
}
