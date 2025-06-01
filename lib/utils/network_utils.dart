import 'dart:io';
import 'package:flutter/foundation.dart';
import '../config/env_config.dart';
import '../services/log_service.dart';

class NetworkUtils {
  /// Try to resolve 'raspberrypi.local' to an IP address through alternative means
  static Future<String?> resolveRaspberryPiLocal() async {
    LogService.info('Attempting to resolve raspberrypi.local IP address');

    // First try normal lookup
    try {
      final addresses = await InternetAddress.lookup('raspberrypi.local');
      if (addresses.isNotEmpty) {
        final ip = addresses.first.address;
        LogService.info('Resolved raspberrypi.local to $ip via DNS');
        await EnvConfig.setResolvedRaspberryPiIP(ip);
        return ip;
      }
    } catch (e) {
      LogService.info('Normal DNS lookup failed: $e');
    }

    // Try common Raspberry Pi IP addresses on home networks
    List<String> commonIps = [
      '192.168.1.100',
      '192.168.1.101',
      '192.168.1.102',
      '192.168.1.103',
      '192.168.0.100',
      '192.168.0.101',
      '192.168.0.102',
      '192.168.0.103',
    ];

    // Try to ping common IP addresses
    for (final ip in commonIps) {
      try {
        LogService.info('Testing connection to $ip');
        final socket = await Socket.connect(
          ip,
          8765,
          timeout: const Duration(milliseconds: 500),
        );
        socket.destroy();
        LogService.info('Found potential Raspberry Pi at $ip');
        await EnvConfig.setResolvedRaspberryPiIP(ip);
        return ip;
      } catch (e) {
        // Continue trying other IPs
      }
    }

    // Try network scan if on debug mode (this can be slow)
    if (kDebugMode) {
      LogService.info('Scanning network for Raspberry Pi...');
      final baseNet = '192.168.1.';
      for (int i = 1; i < 255; i++) {
        final ip = '$baseNet$i';
        try {
          final socket = await Socket.connect(
            ip,
            8765,
            timeout: const Duration(milliseconds: 300),
          );
          socket.destroy();
          LogService.info('Found potential Raspberry Pi at $ip');
          await EnvConfig.setResolvedRaspberryPiIP(ip);
          return ip;
        } catch (e) {
          // Continue scanning
        }
      }
    }

    LogService.error('Failed to resolve raspberrypi.local');
    return null;
  }
}
