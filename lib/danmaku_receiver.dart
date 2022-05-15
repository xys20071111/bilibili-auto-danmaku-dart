import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:bilibili_live_bot_dart/config.dart';
import 'package:brotli/brotli.dart';
import 'package:buffer/buffer.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import './fetch_room_info_error.dart';
import './danmaku_protocol.dart';

class DanmakuReceiver {
  List<Function> danmakuMsg = [];
  List<Function> gift = [];
  List<Function> giftCombo = [];
  List<Function> spuerChat = [];
  List<Function> guard = [];

  WebSocketChannel? ws;
  int roomId = 0;
  DanmakuReceiver(Config config) {
    final headers = <String, String>{
      'Cookie':
          'buvid3=${config.verify.buvid3}; SESSDATA=${config.verify.sessdata}; bili_jct=${config.verify.csrf};',
      'User-Agent':
          'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.4951.64 Safari/537.36'
    };
    http
        .get(
            Uri.parse(
                'https://api.live.bilibili.com/room/v1/Room/room_init?id=${config.roomId}'),
            headers: headers)
        .then((value) async {
      final dataJSON = jsonDecode(value.body);
      if (dataJSON['code'] != 0) {
        throw FetchRoomInfoError(dataJSON['message']);
      }
      final roomInfoJSON = jsonDecode((await http.get(
              Uri.parse(
                  'https://api.live.bilibili.com/room/v1/Danmu/getConf?room_id=${dataJSON['data']['room_id']}&platform=pc&player=web'),
              headers: headers))
          .body);
      roomId = dataJSON['data']['room_id'];
      ws = WebSocketChannel.connect(Uri.parse(
          'wss://${roomInfoJSON['data']['host_server_list'][0]['host']}:${roomInfoJSON['data']['host_server_list'][0]['wss_port']}/sub'));
      final authJSONString = jsonEncode({
        'roomid': roomId,
        'protover': 3,
        'platform': 'web',
        'uid': config.verify.uid,
        'key': roomInfoJSON['data']['token']
      });
      final authPacket = packetEncode(1, DanmakuType.auth, authJSONString);
      ws?.sink.add(authPacket);
      ws?.stream.listen(
        (event) {
          final data = Uint8List.fromList(event);
          final dataBytes = ByteData.view(data.buffer);
          final totalLength = dataBytes.getInt32(0);
          final protocol = dataBytes.getInt16(6);
          final type = dataBytes.getInt32(8);
          final payload = data.getRange(16, totalLength);
          switch (type) {
            case DanmakuType.authReply:
              print('认证成功，已连接到弹幕服务器');
              Timer.periodic(Duration(seconds: 30), (timer) {
                ws?.sink.add(packetEncode(1, 2, '陈睿你妈死了'));
              });
              break;
            case DanmakuType.data:
              switch (protocol) {
                case DanmakuProtocol.json:
                  // 系统广播一类的，这些数据没啥用
                  break;
                case DanmakuProtocol.brotli:
                  final data =
                      Uint8List.fromList(brotli.decode(payload.toList()));
                  final dataBytes = ByteData.view(data.buffer);
                  var offset = 0;
                  while (offset < data.length) {
                    final length = dataBytes.getUint32(0);
                    final dataJSON = jsonDecode(utf8.decode(
                        data.getRange(offset + 16, offset + length).toList()));
                    if (dataJSON['cmd'] == 'SEND_GIFT') {
                      for (final handler in gift) {
                        Future.microtask(() {
                          handler(
                              giftName: dataJSON['data']['giftName'],
                              uname: dataJSON['data']['uname']);
                        });
                      }
                    }
                    offset += length;
                  }
                  break;
              }
              break;
          }
        },
      );
    });
  }
  Uint8List packetEncode(int protocol, int type, String payload) {
    final utf8Payload = utf8.encode(payload);
    final totalLength = 16 + utf8Payload.length;
    final packet =
        ByteDataWriter(bufferLength: totalLength, endian: Endian.big);
    packet.writeInt32(totalLength);
    packet.writeInt16(16);
    packet.writeUint16(protocol);
    packet.writeUint32(type);
    packet.writeUint32(1);
    packet.write(utf8Payload);
    return packet.toBytes();
  }

  void onGift(Function handler) {
    gift.add(handler);
  }
}
