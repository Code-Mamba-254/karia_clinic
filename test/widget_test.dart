import 'package:clinic_app/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  testWidgets('shows the clinic login screen', (tester) async {
    await tester.pumpWidget(const ClinicApp());

    expect(find.text('Doctor Login'), findsOneWidget);
  });
}
