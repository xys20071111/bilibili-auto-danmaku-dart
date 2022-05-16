import 'dart:convert';

import 'package:bilibili_live_bot_dart/api_server.dart';
import 'package:bilibili_live_bot_dart/danmaku_receiver.dart';
import 'package:bilibili_live_bot_dart/config.dart';
import 'package:bilibili_live_bot_dart/send_danmaku.dart';
import 'package:bilibili_live_bot_dart/utils/print_log.dart';

void main(List<String> arguments) {
  assert(arguments.length == 1);
  final config = Config(arguments[0]);
  final danmakuReceiver = DanmakuReceiver(config);
  final danmakuSender = DanmakuSender(config);
  final webSocketAPIServer =
      WebSocketAPIServer('127.0.0.1', config.apiConfig.port);
  webSocketAPIServer.auth = (String token) {
    return token == config.apiConfig.token;
  };
  // API事件回调
  webSocketAPIServer.getRoomId =
      () => jsonEncode({'cmd': 'ROOMID', 'data': config.roomId});
  webSocketAPIServer.sendDanmaku = (text) => danmakuSender.send(text);
  // 弹幕事件回调
  danmakuReceiver.onGift(({giftName = '', uname = ''}) {
    danmakuSender.send(config.danmakus.gift
        .replaceAll('{name}', uname)
        .replaceAll('{gift}', giftName));
    printLog('$uname 投喂了 $giftName');
  });
  danmakuReceiver
      .onGiftCombo(({giftName = '', uname = '', count = 0, price = 0.0}) {
    danmakuSender.send(config.danmakus.giftTotal
        .replaceAll('{name}', uname)
        .replaceAll('{gift}', giftName)
        .replaceAll('{count}', count));
    printLog('$uname 投喂了 $count 个 $giftName ,价格 $price');
  });
  danmakuReceiver.onLiveStart(() {
    danmakuSender.send(config.danmakus.liveStart);
    printLog('直播开始');
  });
  danmakuReceiver.onLiveEnd(() {
    danmakuSender.send(config.danmakus.liveEnd);
    printLog('直播结束');
  });
  danmakuReceiver.onDanmaku(({uname = '', uid = 0, text = ''}) {
    printLog('$uid $uname $text');
  });
  danmakuReceiver.onGuard(({uname = '', giftName = ''}) {
    danmakuSender.send(config.danmakus.guard
        .replaceAll('{name}', uname)
        .replaceAll('{type}', giftName));
    printLog('$uname 开通了 $giftName');
  });
  danmakuReceiver.onSuperChat(({uname = '', price = 0.0}) {
    danmakuSender.send(config.danmakus.sc.replaceAll('{name}', uname));
    printLog('$uname 购买了醒目留言，价格 $price');
  });
  danmakuReceiver.onBroadcast((msg) {
    webSocketAPIServer.sendMsg(msg);
  });
}
