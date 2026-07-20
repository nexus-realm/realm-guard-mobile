/// Données saisies pour créer ou modifier un TOTP.
///
/// Value object découplant l'UI/les ViewModels des colonnes Drift. Conçu pour
/// être rempli aussi bien par le formulaire manuel que (plus tard) par le scan
/// d'un QR `otpauth://`.
class TotpDraft {
  const TotpDraft({
    required this.label,
    required this.secret,
    this.account,
    this.digits = 6,
    this.period = 30,
    this.algorithm = 'SHA1',
    this.profileId,
    this.favorite = false,
  });

  final String label;
  final String secret;
  final String? account;
  final int digits;
  final int period;
  final String algorithm;
  final int? profileId;
  final bool favorite;
}
