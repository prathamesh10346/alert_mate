import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CacheInfoService {
  Future<Map<String, String>> getCacheAndCookieInfo() async {
    try {
      // Get app cache directory size
      final appDir = await getApplicationDocumentsDirectory();
      final appCacheDir = await getTemporaryDirectory();

      int totalCacheSize = await _calculateDirSize(appCacheDir);
      int totalAppSize = await _calculateDirSize(appDir);

      // Get cookies using WebView
      final WebViewController controller = WebViewController();
      final cookies = await controller
          .runJavaScriptReturningResult('document.cookie') as String;

      // Get shared preferences
      final prefs = await SharedPreferences.getInstance();
      final prefKeys = prefs.getKeys();
      int prefsCount = prefKeys.length;

      return {
        'Total Cache Size':
            '${(totalCacheSize / 1024 / 1024).toStringAsFixed(2)} MB',
        'Total App Storage':
            '${(totalAppSize / 1024 / 1024).toStringAsFixed(2)} MB',
        'Cookie Count': cookies.split(';').length.toString(),
        'Shared Preferences Count': prefsCount.toString(),
        'Cache Directory': appCacheDir.path,
        'Documents Directory': appDir.path,
      };
    } catch (e) {
      print('Error getting cache and cookie info: $e');
      return {'Error': 'Failed to get cache and cookie information: $e'};
    }
  }

  Future<int> _calculateDirSize(Directory dir) async {
    int totalSize = 0;
    try {
      if (dir.existsSync()) {
        dir
            .listSync(recursive: true, followLinks: false)
            .forEach((FileSystemEntity entity) {
          if (entity is File) {
            totalSize += entity.lengthSync();
          }
        });
      }
    } catch (e) {
      print('Error calculating directory size: $e');
    }
    return totalSize;
  }
}
