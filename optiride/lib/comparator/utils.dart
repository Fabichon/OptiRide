import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Formatte un montant en centimes vers une chaîne locale EUR,
/// ex: 4700 => "47,00 €" (espace insécable inclus).
String formatPriceEUR(int cents) {
  final euros = cents / 100.0;
  final f = NumberFormat.currency(locale: 'fr_FR', symbol: '€', decimalDigits: 2);
  return f.format(euros);
}

/// Tente l’ouverture du deeplink d’app, sinon fallback vers l’URL web.
Future<void> openDeepLinkOrWeb({required String appUri, required String webUrl}) async {
  // Suppression du deeplink Uber pour l'instant, ouverture du site web uniquement
  final web = Uri.tryParse(webUrl);
  if (web != null) {
    await launchUrl(web, mode: LaunchMode.externalApplication);
  }
}

/// Nom affiché humain pour un code plateforme.
String platformDisplayName(String code) {
  switch (code) {
    case 'uber':
      return 'Uber';
    case 'bolt':
      return 'Bolt';
    case 'heetch':
      return 'Heetch';
    case 'freenow':
      return 'FREE NOW';
    default:
      return code;
  }
}
