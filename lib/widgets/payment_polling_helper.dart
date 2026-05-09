import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vehicle_registration_app/services/payment_service.dart';

typedef OnPaymentSuccess = void Function();
typedef OnPaymentFailed = void Function();

/// Helper class dùng chung cho cả Receipt và Return screens
/// để tạo QR dialog + polling kiểm tra trạng thái thanh toán.
class PaymentPollingHelper {
  PaymentPollingHelper({required this.paymentService});

  final PaymentService paymentService;
  Timer? _pollingTimer;

  void dispose() {
    _pollingTimer?.cancel();
  }

  void showQRDialogAndPoll({
    required BuildContext context,
    required String qrImageUrl,
    required int orderCode,
    required OnPaymentSuccess onSuccess,
    OnPaymentFailed? onFailed,
    String title = 'Quét mã QR thanh toán',
    int pollingIntervalSeconds = 3,
    int timeoutSeconds = 300,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(qrImageUrl, width: 250, height: 250, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(width: 250, height: 250,
                  child: Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey))),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Vui lòng khách hàng quét mã để thanh toán.', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const CircularProgressIndicator(),
            const SizedBox(height: 8),
            const Text('Đang chờ hệ thống PayOS...', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () { _pollingTimer?.cancel(); Navigator.pop(ctx); },
            child: const Text('Huỷ / Đóng'),
          ),
        ],
      ),
    );

    _pollingTimer?.cancel();
    int elapsed = 0;
    _pollingTimer = Timer.periodic(Duration(seconds: pollingIntervalSeconds), (timer) async {
      elapsed += pollingIntervalSeconds;
      if (elapsed >= timeoutSeconds) {
        timer.cancel();
        if (context.mounted) { Navigator.pop(context); onFailed?.call(); }
        return;
      }
      try {
        final statusRes = await paymentService.checkPaymentStatus(orderCode);
        if (statusRes['status'] == 'SUCCESS') {
          timer.cancel();
          if (context.mounted) { Navigator.pop(context); onSuccess(); }
        } else if (statusRes['status'] == 'FAILED') {
          timer.cancel();
          if (context.mounted) { Navigator.pop(context); onFailed?.call(); }
        }
      } catch (e) {
        print('Polling error: $e');
      }
    });
  }
}
