import 'dart:async';
import 'dart:math';

import 'package:bilibili_live_bot_dart/config.dart';
import 'package:http/http.dart' as http;

class DanmakuSender {
  Config config;
  DanmakuSender(this.config);
  void send(String text) {
    if (text.length > 19) {
      send(text.substring(0, 19));
      Future.delayed(Duration(seconds: 2), () => send(text.substring(19)));
      return;
    }
    final headers = <String, String>{
      'Cookie':
          'buvid3=${config.verify.buvid3}; SESSDATA=${config.verify.sessdata}; bili_jct=${config.verify.csrf};',
      'User-Agent':
          'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.4951.64 Safari/537.36',
      "Referer": "https://live.bilibili.com",
    };
    final request = http.MultipartRequest(
        'POST', Uri.parse('https://api.live.bilibili.com/msg/send'));
    request.headers.addAll(headers);
    request.fields['color'] = '5816798';
    request.fields['bubble'] = '0';
    request.fields['mode'] = '1';
    request.fields['fontsize'] = '24';
    request.fields['roomid'] = config.roomId.toString();
    request.fields['csrf'] = config.verify.csrf;
    request.fields['csrf_token'] = config.verify.csrf;
    request.fields['rnd'] = Random().nextInt(100000000).toString();
    request.fields['msg'] = text;
    request.send();
  }
}
