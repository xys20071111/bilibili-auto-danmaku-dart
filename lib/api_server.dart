import 'dart:io' show HttpServer, WebSocket, WebSocketTransformer;
import 'dart:convert';
import './utils/print_log.dart';

class WebSocketAPIServer {
  final List<WebSocket> _clientList = [];
  final List<WebSocket> _authedClientList = [];
  Function? auth;
  Function? getRoomId;
  Function? sendDanmaku;
  WebSocketAPIServer(String host, int port, Logger logger) {
    HttpServer.bind(host, port).then((server) {
      logger.log('WebSocket 服务器运行在 ws://$host:$port');
      server.listen((req) {
        WebSocketTransformer.upgrade(req).then((ws) {
          _clientList.add(ws);
          ws.listen((msg) {
            final msgJSON = jsonDecode(msg);
            if (msgJSON['cmd'] == 'AUTH') {
              if (auth!(msgJSON['data'])) {
                _authedClientList.add(ws);
                ws.add(jsonEncode({'cmd': 'AUTH', 'data': 'AUTHED'}));
              } else {
                ws.add(jsonEncode({'cmd': 'AUTH', 'data': 'FAILED'}));
              }
            }
            if (msgJSON['cmd'] == 'ROOMID') {
              if (_authedClientList.contains(ws)) {
                ws.add(getRoomId!());
              }
            }
            if (msgJSON['cmd'] == 'SEND') {
              if (_authedClientList.contains(ws)) {
                sendDanmaku!(msgJSON['data']);
              }
            }
          });
        });
      });
    });
  }
  void sendMsg(String msg) {
    final Map<String, dynamic> msgJSON = jsonDecode(msg);
    if (msgJSON.containsKey('info')) {
      msgJSON.addAll({'data': msgJSON['info']});
    }
    for (final clients in _clientList) {
      clients.add(jsonEncode(msgJSON));
    }
  }
}
