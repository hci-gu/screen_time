import '../api.dart';

class NetworkUtils {
  static Future<bool> hasNetworkConnection() async {
    try {
      await fetchQuestionnaires();
      return true;
    } catch (e) {
      final isNetworkError = _isNetworkError(e);
      return !isNetworkError;
    }
  }

  static bool isNetworkError(dynamic error) {
    return _isNetworkError(error);
  }

  static bool _isNetworkError(dynamic error) {
    final errorString = error.toString();
    return errorString.contains('SocketException') ||
        errorString.contains('Failed host lookup') ||
        errorString.contains('No address associated with hostname') ||
        errorString.contains('Connection timed out') ||
        errorString.contains('Network is unreachable') ||
        errorString.contains('ClientException') ||
        errorString.contains('Connection refused');
  }

  static String getErrorMessage(dynamic error, {String? customNetworkMessage}) {
    if (_isNetworkError(error)) {
      return customNetworkMessage ??
          'Ingen internetanslutning. Kontrollera din anslutning och försök igen.';
    } else {
      return 'Ett oväntat fel inträffade. Försök igen senare.';
    }
  }

  static String getErrorIcon(dynamic error) {
    return _isNetworkError(error) ? 'wifi_off' : 'error_outline';
  }
}
