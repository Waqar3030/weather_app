import 'dart:developer';

import 'package:get_storage/get_storage.dart';
import 'package:weather_app/resources/local%20storage/local_storage_keys.dart';
import 'package:weather_app/utils/utils.dart';

class LocalStorage {
  static final getStorage = GetStorage();

  static Future init() async {
    await GetStorage.init();
    log("GetStorage initialized");
  }

  static saveJson({required String key, required value}) {
    var res = getStorage.write(key, value);
    log("Saved key: $key with value: $value");
    return res;
  }

  static readJson({required String key}) {
    var res = getStorage.read(key);
    log("Read key: $key, value: $res");
    return res;
  }

  static deleteJson({required String key}) {
    var res = getStorage.remove(key);
    log("Deleted key: $key");
    return res;
  }

  static saveAccessToken(String token) {
    getStorage.write(lsk.authToken, token);
    log("Access token saved: $token");
  }

  static getAccessToken() {
    var token = getStorage.read(lsk.authToken) ?? "";
    log("Access token retrieved: $token");
    return token;
  }

  static deleteAccessToken() {
    getStorage.remove(lsk.authToken);
    log("Access token deleted");
  }

  static clearAlldata() {
    getStorage.erase();
    log("All data cleared from storage");
  }

  static clearCredentials() {
    getStorage.remove(lsk.authToken);
    // getStorage.remove(lsk.password);
    // getStorage.remove(lsk.email);
    // getStorage.remove(lsk.remembermebool);
    Utils.logSuccess("Credentials cleared");
  }

  static writeIfNull(String key, bool value) {
    getStorage.writeIfNull(key, value);
    log("Write if null key: $key with value: $value");
  }
}
