import 'package:url_launcher/url_launcher.dart';
import '../models/provider_id.dart';

class DeeplinkService {
  Future<bool> openProviderApp(ProviderId provider, {String? pickup, String? destination}) async {
    final uri = Uri.parse(provider.deeplinkScheme);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri);
    }
    return false;
  }
}
