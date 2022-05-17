import 'dart:convert';
import 'dart:io';

class Logger {
  late File _logFile;
  late IOSink _logFileWrite;
  Logger(String logFilePath) {
    _logFile = File(logFilePath);
    _logFileWrite = _logFile.openWrite(mode: FileMode.write, encoding: utf8);
  }
  void log(String text) {
    final now = DateTime.now();
    print('$now $text');
    _logFileWrite.writeln('$now $text');
  }
}
