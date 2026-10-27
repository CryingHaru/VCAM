import 'dart:async';
import 'dart:io';
import 'package:multicast_dns/multicast_dns.dart';

class VcamDiscovery {
  static Stream<({String host, int port})> discover() async* {
    final discovered = <String>{};
    final controller = StreamController<({String host, int port})>();

    RawDatagramSocket? udpSocket;
    Timer? probeTimer;
    MDnsClient? mdns;

    void notify(String host, int port) {
      final key = '$host:$port';
      if (!discovered.contains(key)) {
        discovered.add(key);
        if (!controller.isClosed) {
          controller.add((host: host, port: port));
        }
      }
    }

    try {
      udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      udpSocket.broadcastEnabled = true;

      udpSocket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = udpSocket?.receive();
          if (datagram != null) {
            final text = String.fromCharCodes(datagram.data).trim();
            if (text.startsWith('VCAM_BEACON:')) {
              final portStr = text.substring('VCAM_BEACON:'.length);
              final port = int.tryParse(portStr) ?? 8080;
              notify(datagram.address.address, port);
            }
          }
        }
      });

      void sendProbe() {
        try {
          final payload = 'VCAM_DISCOVER'.codeUnits;
          udpSocket?.send(payload, InternetAddress('255.255.255.255'), 8089);
        } catch (_) {}
      }

      sendProbe();
      probeTimer = Timer.periodic(const Duration(seconds: 1), (_) => sendProbe());
    } catch (_) {}

    Future<void> runMdns() async {
      try {
        mdns = MDnsClient();
        await mdns!.start();
        await for (final ptr in mdns!.lookup<PtrResourceRecord>(
          ResourceRecordQuery.serverPointer('_http._tcp.local'),
        )) {
          if (!ptr.domainName.toLowerCase().contains('vcam')) continue;
          await for (final srv in mdns!.lookup<SrvResourceRecord>(
            ResourceRecordQuery.service(ptr.domainName),
          )) {
            await for (final ip in mdns!.lookup<IPAddressResourceRecord>(
              ResourceRecordQuery.addressIPv4(srv.target),
            )) {
              notify(ip.address.address, srv.port);
            }
          }
        }
      } catch (_) {}
    }

    runMdns();

    controller.onCancel = () {
      probeTimer?.cancel();
      udpSocket?.close();
      mdns?.stop();
    };

    yield* controller.stream;
  }
}
