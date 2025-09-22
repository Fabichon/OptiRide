import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optiride/main.dart';

void main() {
  testWidgets('Champs Départ/Destination accessibles par Keys', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OptiRideApp()));

    // Les champs doivent être présents avec leurs Keys stables
    final originFinder = find.byKey(const Key('originField'));
    final destinationFinder = find.byKey(const Key('destinationField'));

    expect(originFinder, findsOneWidget);
    expect(destinationFinder, findsOneWidget);

    // Et on peut y saisir du texte sans collision avec les labels
    await tester.enterText(originFinder, '10 Rue de Rivoli, Paris');
    await tester.enterText(destinationFinder, 'Tour Eiffel');

    expect(find.text('10 Rue de Rivoli, Paris'), findsOneWidget);
    expect(find.text('Tour Eiffel'), findsOneWidget);
  });
}
