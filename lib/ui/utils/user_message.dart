import 'package:front_end_flutter/data/remote/api_client.dart';

class UserMessage {
  static String from(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return 'No pudimos completar la acción. Revisa tu conexión y vuelve a intentarlo.';
  }
}
