import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:bilibili_live_bot_dart/config.dart';
import 'package:brotli/brotli.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import './fetch_room_info_error.dart';
import './danmaku_protocol.dart';
import './utils/print_log.dart';

class DanmakuReceiver {
  final List<Function> _danmakuMsg = [];
  final List<Function> _gift = [];
  final List<Function> _giftCombo = [];
  final List<Function> _spuerChat = [];
  final List<Function> _guard = [];
  final List<Function> _liveStart = [];
  final List<Function> _liveEnd = [];
  final List<Function> _broadcast = [];

  WebSocketChannel? ws;
  int roomId = 0;
  DanmakuReceiver(Config config, Logger logger) {
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
              logger.log('??????????????????????????????????????????');
              Timer.periodic(Duration(seconds: 30), (timer) {
                ws?.sink.add(packetEncode(1, 2, '??????????????????'));
              });
              break;
            case DanmakuType.data:
              switch (protocol) {
                case DanmakuProtocol.json:
                  // ?????????????????????????????????????????????
                  break;
                case DanmakuProtocol.brotli:
                  final data =
                      Uint8List.fromList(brotli.decode(payload.toList()));
                  final dataBytes = ByteData.view(data.buffer);
                  var offset = 0;
                  while (offset < data.length) {
                    final length = dataBytes.getUint32(0);
                    final dataJSONString = utf8.decode(
                        data.getRange(offset + 16, offset + length).toList());
                    for (final handler in _broadcast) {
                      handler(dataJSONString);
                    }
                    final dataJSON = jsonDecode(dataJSONString);
                    final cmd = dataJSON['cmd'].toString().split(':')[0];
                    if (dataJSON['info'] != null) {
                      dataJSON['data'] = dataJSON['info'];
                    }
                    if (cmd == 'SEND_GIFT') {
                      for (final handler in _gift) {
                        Future.microtask(() => handler(
                            giftName: dataJSON['data']['giftName'],
                            uname: dataJSON['data']['uname']));
                      }
                    }
                    if (cmd == 'COMBO_SEND') {
                      for (final handler in _giftCombo) {
                        Future.microtask(() => handler(
                            giftName: dataJSON['data']['gift_name'],
                            uname: dataJSON['data']['uname'],
                            count: dataJSON['data']['combo_num'],
                            price: dataJSON['data']['price'] /
                                1000 *
                                dataJSON['data']['super_gift_num']));
                      }
                    }
                    if (cmd == 'GUARD_BUY') {
                      for (final handler in _guard) {
                        Future.microtask(() => handler(
                            uname: dataJSON['data']['username'],
                            giftName: dataJSON['data']['gift_name']));
                      }
                    }
                    if (cmd == 'LIVE') {
                      for (final handler in _liveStart) {
                        Future.microtask(() => handler());
                      }
                    }
                    if (cmd == 'PREPARING') {
                      for (final handler in _liveEnd) {
                        Future.microtask(() => handler());
                      }
                    }
                    if (cmd == 'SUPER_CHAT_MESSAGE') {
                      for (final handler in _liveEnd) {
                        Future.microtask(() => handler(
                            uname: dataJSON['data']['user_info']['uname'],
                            price: dataJSON['data']['price']));
                      }
                    }
                    if (cmd == 'DANMU_MSG') {
                      for (final handler in _danmakuMsg) {
                        Future.microtask(() => handler(
                            uname: dataJSON['data'][2][1],
                            uid: dataJSON['data'][2][0],
                            text: dataJSON['data'][1]));
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
    final packetHeader = ByteData(16);
    packetHeader.setInt32(0, totalLength);
    packetHeader.setInt16(4, 16);
    packetHeader.setUint16(6, protocol);
    packetHeader.setUint32(8, type);
    packetHeader.setUint32(12, 1);
    final packet = BytesBuilder();
    packet.add(packetHeader.buffer.asInt8List());
    packet.add(utf8Payload);
    return packet.toBytes();
  }

  //??????????????????
  void onGift(Function handler) {
    _gift.add(handler);
  }

  //??????????????????
  void onGiftCombo(Function handler) {
    _giftCombo.add(handler);
  }

  //?????????????????????
  void onGuard(Function handler) {
    _guard.add(handler);
  }

  //??????????????????
  void onLiveStart(Function handler) {
    _liveStart.add(handler);
  }

  //??????????????????
  void onLiveEnd(Function handler) {
    _liveEnd.add(handler);
  }

  //??????????????????
  void onSuperChat(Function handler) {
    _spuerChat.add(handler);
  }

  //??????????????????
  void onDanmaku(Function handler) {
    _danmakuMsg.add(handler);
  }

  //????????????????????????
  void onBroadcast(Function handler) {
    _broadcast.add(handler);
  }
}
