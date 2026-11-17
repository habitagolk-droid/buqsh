import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_cash/common/widgets/custom_button_widget.dart';
import 'package:six_cash/theme/light_theme.dart';

void main() {
  testWidgets('BUQSH primary button renders with the shared theme',
      (WidgetTester tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: light,
        home: Scaffold(
          body: CustomButtonWidget(
            buttonText: 'متابعة',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('متابعة'), findsOneWidget);
    await tester.tap(find.text('متابعة'));
    expect(tapped, isTrue);
  });
}
