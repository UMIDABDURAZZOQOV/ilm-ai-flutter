import 'core/config/phone_qa.dart';
import 'main.dart' as app;

void main() {
  requirePhoneQaConfiguration(const String.fromEnvironment('API_URL'));
  app.main();
}
