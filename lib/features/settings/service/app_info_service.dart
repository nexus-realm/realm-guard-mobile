import 'package:package_info_plus/package_info_plus.dart';

/// Informations d'identité de l'application affichées dans « À propos ».
class AppInfo {
  const AppInfo({
    required this.appName,
    required this.version,
    required this.buildNumber,
    required this.packageName,
  });

  final String appName;
  final String version;
  final String buildNumber;
  final String packageName;
}

/// Fournit les métadonnées de build via `package_info_plus`.
class AppInfoService {
  const AppInfoService();

  Future<AppInfo> load() async {
    final info = await PackageInfo.fromPlatform();
    return AppInfo(
      appName: info.appName,
      version: info.version,
      buildNumber: info.buildNumber,
      packageName: info.packageName,
    );
  }
}
