import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Komponen dasar Flutter SI-GORAY berjalan',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('SI-GORAY Petugas Gerbang'),
          ),
        ),
      );

      expect(
        find.text('SI-GORAY Petugas Gerbang'),
        findsOneWidget,
      );
    },
  );
}
