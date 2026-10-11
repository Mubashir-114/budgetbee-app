import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/constants/app_colors.dart';
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
