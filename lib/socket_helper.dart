library socket_helper;
import 'package:socket_io_client/socket_io_client.dart' as IO;
//вспомогательный класс для работы с сокетом
class SocketHelper{
  IO.Socket _socket;
  SocketHelper(String url, Map<String, Function> functionsForSubscribe) {
    _socket = IO.io(url, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    _socket.connect();
    functionsForSubscribe.forEach((key, value) {
      subscribeEvent(key, value);
    });
  }
  void subscribeEvent(String event, Function callbackF) {
    _socket.on(event, callbackF);
  }
  void emitEvent(String event,  Map <String, dynamic> data) {
    _socket.emit(event, data);
  }
}