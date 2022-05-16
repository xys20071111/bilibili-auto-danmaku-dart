import 'dart:convert';
import 'dart:io';

class Credential {
  String csrf = '';
  String sessdata = '';
  String buvid3 = '';
  int uid = 0;
  Credential(this.csrf, this.sessdata, this.buvid3, this.uid);
}

class DanmakuTemplate {
  String liveStart = '';
  String liveEnd = '';
  String gift = '';
  String giftTotal = '';
  String guard = '';
  String sc = '';
  String advertisement = '';
  DanmakuTemplate(this.liveStart, this.liveEnd, this.gift, this.giftTotal,
      this.guard, this.sc, this.advertisement);
}

class APIServerConfig {
  int port;
  String token;
  APIServerConfig(this.port, this.token);
}

class Config {
  late int roomId;
  late Credential verify;
  late DanmakuTemplate danmakus;
  late int coldDownTime;
  late int advertiseingColdDown;
  late APIServerConfig apiConfig;
  Config(String configPath) {
    final configFile = File(configPath);
    final configJSON = jsonDecode(configFile.readAsStringSync());
    roomId = configJSON['room_id'];
    verify = Credential(
        configJSON['verify']['csrf'],
        configJSON['verify']['sessdata'],
        configJSON['verify']['buvid3'],
        configJSON['verify']['uid']);
    danmakus = DanmakuTemplate(
        configJSON['danmakus']['live_start'],
        configJSON['danmakus']['live_end'],
        configJSON['danmakus']['gift'],
        configJSON['danmakus']['gift_total'],
        configJSON['danmakus']['guard'],
        configJSON['danmakus']['sc'],
        configJSON['danmakus']['advertisment']);
    coldDownTime = configJSON['cold_down_time'];
    advertiseingColdDown = configJSON['advertising_cold_down'];
    apiConfig =
        APIServerConfig(configJSON['api']['port'], configJSON['api']['token']);
  }
}
