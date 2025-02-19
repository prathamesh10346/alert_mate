import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class WifiService {
  Future<Map<String, String>> fetchWifiInfo() async {
    try {
      final info = NetworkInfo();
      final connectivity = await (Connectivity().checkConnectivity());

      bool hasLocationPermission = await Permission.location.isGranted;
      if (!hasLocationPermission) {
        await Permission.location.request();
      }

      var wifiName = await info.getWifiName() ?? 'Unknown';
      var wifiBSSID = await info.getWifiBSSID() ?? 'Unknown';
      var wifiIP = await info.getWifiIP() ?? 'Unknown';
      var wifiSubmask = await info.getWifiSubmask() ?? 'Unknown';
      var wifiGateway = await info.getWifiGatewayIP() ?? 'Unknown';
      var wifiBroadcast = await info.getWifiBroadcast() ?? 'Unknown';

      String connectionStatus = 'Not Connected';
      switch (connectivity) {
        case ConnectivityResult.wifi:
          connectionStatus = 'Connected to WiFi';
          break;
        case ConnectivityResult.mobile:
          connectionStatus = 'Connected to Mobile Data';
          break;
        case ConnectivityResult.none:
          connectionStatus = 'No Connection';
          break;
        default:
          connectionStatus = 'Unknown Connection Status';
      }

      return {
        'WiFi Name (SSID)': wifiName.replaceAll('"', ''),
        'BSSID': wifiBSSID,
        'IP Address': wifiIP,
        'Gateway IP': wifiGateway,
        'Subnet Mask': wifiSubmask,
        'Broadcast Address': wifiBroadcast,
        'Connection Status': connectionStatus,
      };
    } catch (e) {
      print('Error fetching WiFi info: $e');
      return {
        'WiFi Name (SSID)': 'Not available',
        'BSSID': 'Not available',
        'IP Address': 'Not available',
        'Gateway IP': 'Not available',
        'Subnet Mask': 'Not available',
        'Broadcast Address': 'Not available',
        'Connection Status': 'Error fetching status',
      };
    }
  }
}