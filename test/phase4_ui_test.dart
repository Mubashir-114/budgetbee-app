import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/theme_collection.dart';
import 'package:frontend/core/widgets/animated_progress_bar.dart';
import 'package:frontend/core/widgets/app_text_field.dart';
import 'package:frontend/core/widgets/living_wallet.dart';

void main() {
  testWidgets('Living Wallet renders with reduced motion enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: LivingWallet()),
        ),
      ),
    );

    expect(find.byType(LivingWallet), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(
      find.bySemanticsLabel(
        'An illustrated wallet with gently floating money tokens',
      ),
      findsOneWidget,
    );
  });

  test('Living Wallet maps every collection to its brand accent', () {
    const accents = {
      ThemeCollection.graphiteChampagne: Color(0xFFD6A668),
      ThemeCollection.obsidianJade: Color(0xFF38D5B0),
      ThemeCollection.arcticBlue: Color(0xFF4FA3F7),
    };

    for (final entry in accents.entries) {
      expect(
        LivingWallet.brandAccentFor(entry.key),
        entry.value,
        reason: '${entry.key.displayName} should use ${entry.value}',
      );
    }
  });

  testWidgets('Living Wallet repaints in place when collection changes', (
    tester,
  ) async {
    final collection = ValueNotifier(ThemeCollection.graphiteChampagne);
    addTearDown(collection.dispose);

    await tester.pumpWidget(
      ValueListenableBuilder<ThemeCollection>(
        valueListenable: collection,
        builder: (context, value, child) => MaterialApp(
          theme: AppTheme.buildTheme(value, Brightness.dark),
          themeAnimationDuration: Duration.zero,
          home: child,
        ),
        child: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: LivingWallet()),
        ),
      ),
    );

    final originalState = tester.state(find.byType(LivingWallet));
    final originalPainter = tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byType(LivingWallet),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter!;
    expect(
      LivingWallet.brandAccentFor(collection.value),
      const Color(0xFFD6A668),
    );

    collection.value = ThemeCollection.obsidianJade;
    await tester.pump();

    expect(tester.state(find.byType(LivingWallet)), same(originalState));
    final jadePainter = tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byType(LivingWallet),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter!;
    expect(
      LivingWallet.brandAccentFor(collection.value),
      const Color(0xFF38D5B0),
    );
    expect(jadePainter, isNot(same(originalPainter)));
    expect(jadePainter.shouldRepaint(originalPainter), isTrue);
  });

  testWidgets('password visibility control remains accessible', (tester) async {
    final controller = TextEditingController(text: 'secret12');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppTextField(
            controller: controller,
            label: 'Password',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
          ),
        ),
      ),
    );

    expect(tester.widget<EditableText>(find.byType(EditableText)).obscureText, isTrue);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(tester.widget<EditableText>(find.byType(EditableText)).obscureText, isFalse);
    expect(find.byTooltip('Hide password'), findsOneWidget);
  });

  testWidgets('animated financial progress exposes a percentage', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnimatedProgressBar(
            value: .72,
            color: AppColors.primary,
            backgroundColor: AppColors.dividerLight,
            semanticLabel: 'Budget used',
          ),
        ),
      ),
    );

    final progress = find.bySemanticsLabel('Budget used');
    expect(progress, findsOneWidget);
    expect(tester.getSemantics(progress).value, '72 percent');
    semantics.dispose();
  });
}
