import 'package:bilibili_live_bot_dart/danmaku_receiver.dart';
import 'package:bilibili_live_bot_dart/config.dart';
import 'package:bilibili_live_bot_dart/send_danmaku.dart';

void main(List<String> arguments) {
  assert(arguments.length == 1);
  final config = Config(arguments[0]);
  final danmakuReceiver = DanmakuReceiver(config);
  final danmakuSender = DanmakuSender(config);
  danmakuReceiver.onGift(({giftName = '', uname = ''}) {
    print(giftName);
    print(uname);
    danmakuSender.send(config.danmakus.gift
        .replaceAll('{name}', uname)
        .replaceAll('{gift}', giftName));
  });
}
