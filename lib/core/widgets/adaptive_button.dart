import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum AdaptiveButtonStyle { primary, secondary, text, danger }

class AdaptiveButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AdaptiveButtonStyle style;
  final IconData? icon; // optional leading icon

  const AdaptiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = AdaptiveButtonStyle.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      // ----- Cupertino
      final child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: _iosTextColor(style)),
            const SizedBox(width: 6),
          ],
          Text(label, style: TextStyle(color: _iosTextColor(style))),
        ],
      );

      switch (style) {
        case AdaptiveButtonStyle.primary:
          return CupertinoButton.filled(onPressed: onPressed, child: child);
        case AdaptiveButtonStyle.secondary:
          return CupertinoButton(
            onPressed: onPressed,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: CupertinoColors.systemGrey5,
            borderRadius: BorderRadius.circular(8),
            child: child,
          );
        case AdaptiveButtonStyle.text:
          return CupertinoButton(
            onPressed: onPressed,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: child,
          );
        case AdaptiveButtonStyle.danger:
          return CupertinoButton(
            onPressed: onPressed,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: CupertinoColors.systemRed,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: CupertinoColors.white),
                  const SizedBox(width: 6),
                ],
                Text(label, style: const TextStyle(color: CupertinoColors.white)),
              ],
            ),
          );
      }
    } else {
      // ----- Material
      final Widget content = icon == null
          ? Text(label)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 6),
                Text(label),
              ],
            );

      switch (style) {
        case AdaptiveButtonStyle.primary:
          return FilledButton(onPressed: onPressed, child: content);
        case AdaptiveButtonStyle.secondary:
          return OutlinedButton(onPressed: onPressed, child: content);
        case AdaptiveButtonStyle.text:
          return TextButton(onPressed: onPressed, child: content);
        case AdaptiveButtonStyle.danger:
          return FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: content,
          );
      }
    }
  }

  Color _iosTextColor(AdaptiveButtonStyle s) {
    switch (s) {
      case AdaptiveButtonStyle.primary:
        return CupertinoColors.white;
      case AdaptiveButtonStyle.secondary:
        return CupertinoColors.black;
      case AdaptiveButtonStyle.text:
        return CupertinoColors.activeBlue;
      case AdaptiveButtonStyle.danger:
        return CupertinoColors.white;
    }
  }
}
