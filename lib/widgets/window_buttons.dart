import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';

class CustomWindowButtons extends StatelessWidget {
  const CustomWindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux)) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    
    final buttonColors = WindowButtonColors(
      iconNormal: colorScheme.onSurface,
      mouseOver: colorScheme.surfaceContainerHighest,
      mouseDown: colorScheme.surfaceContainer,
      iconMouseOver: colorScheme.primary,
      iconMouseDown: colorScheme.primary,
    );

    final closeButtonColors = WindowButtonColors(
      mouseOver: colorScheme.errorContainer,
      mouseDown: colorScheme.error,
      iconNormal: colorScheme.onSurface,
      iconMouseOver: colorScheme.onErrorContainer,
      iconMouseDown: colorScheme.onError,
    );

    return Row(
      children: [
        MinimizeWindowButton(colors: buttonColors),
        MaximizeWindowButton(colors: buttonColors),
        CloseWindowButton(colors: closeButtonColors),
      ],
    );
  }
}
