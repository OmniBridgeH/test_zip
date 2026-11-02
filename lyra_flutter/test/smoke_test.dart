import 'package:flutter_test/flutter_test.dart';
import 'package:lyra/main.dart' as app;

void main() {
  testWidgets('app boots', (tester) async {
    app.main();
    await tester.pump();
  });
}
