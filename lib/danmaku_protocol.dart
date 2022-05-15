class DanmakuProtocol {
  static const json = 0;
  static const heartbeat = 1;
  static const zip = 2;
  static const brotli = 3;
}

class DanmakuType {
  static const int heartbeat = 2;
  static const int heartbeatReply = 3;
  static const int data = 5;
  static const int auth = 7;
  static const int authReply = 8;
}
