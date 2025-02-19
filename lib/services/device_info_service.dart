import 'dart:convert';

import 'package:alert_mate/services/cache_info_service.dart';
import 'package:alert_mate/services/location_service.dart';
import 'package:alert_mate/services/phone_service.dart';
import 'package:alert_mate/services/wifi_service.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:http/http.dart' as http;

class DeviceInfoService {
  final CacheInfoService _cacheInfoService = CacheInfoService();
  Future<Map<String, String>> getDeviceInformation() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      var androidInfo = await deviceInfo.androidInfo;
      WifiService wifiService = WifiService();
      Map<String, String> wifiInfo = await wifiService.fetchWifiInfo();
      Map<String, String> cacheInfo =
          await _cacheInfoService.getCacheAndCookieInfo();
      // Fetch location information
      LocationService locationService = LocationService();
      Map<String, String> locationInfo =
          await locationService.fetchLocationDetails();
  

      Map<String, String> simDetails =
          await PhoneService().getPhoneAndBatteryInfo();
      var ipResponse = await http.get(Uri.parse('https://ipapi.co/json/'));
      var locationData = jsonDecode(ipResponse.body);
      var location =
          "${locationData['city']}, ${locationData['region']}, ${locationData['country_name']}";
      var ipDetails = {
        "IP Address": locationData['ip'],
        "City": locationData['city'],
        "Region": locationData['region'],
        "Country": locationData['country_name'],
        "ISP": locationData['org'],
        "Timezone": locationData['timezone']
      };

      return {
        "Device Model": androidInfo.model,
        "Manufacturer": androidInfo.manufacturer,
        "Android Version": androidInfo.version.release,
        "SDK Version": androidInfo.version.sdkInt.toString(),
       
        "Phone Code": androidInfo.version.codename,
        "Build ID": androidInfo.id,
        "Build Type": androidInfo.type,
        "Build Tags": androidInfo.tags,
        "Build Time": DateTime.fromMillisecondsSinceEpoch(
                androidInfo.version.securityPatch != null
                    ? DateTime.parse(androidInfo.version.securityPatch!)
                        .millisecondsSinceEpoch
                    : 0)
            .toString(),
        "Security Patch": androidInfo.version.securityPatch ?? "Unknown",
        "Build Fingerprint": androidInfo.fingerprint,
        "System Features": androidInfo.systemFeatures.join(", "),
        "Supported ABIs": androidInfo.supportedAbis.join(", "),
        "Display": androidInfo.display,
        "Hardware": androidInfo.hardware,
        "Host": androidInfo.host,
        "Product": androidInfo.product,
       
        "Location": location,
        ...wifiInfo, // Add WiFi information
        ...locationInfo,
        ...simDetails,
        ...cacheInfo,
      };
    } catch (e) {
      print("Error getting device information: $e");
      return {"Error": "Failed to get device information"};
    }
  }
}
