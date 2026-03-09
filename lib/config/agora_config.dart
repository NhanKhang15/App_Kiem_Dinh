/// Cấu hình Agora cho project "App đăng kiểm".
/// Secure mode: APP ID + Token (lấy token từ Console khi test).
class AgoraConfig {
  AgoraConfig._();

  /// App ID từ Agora Console (project "App đăng kiểm").
  static const String appId = '72772cb3f1564061bb9c92133b5d557e';

  /// Token cho RTC (gọi thoại/video). Test: vào Console → project → Generate Temp Token
  /// (channel name = tên kênh bạn dùng, uid = số nguyên). Dán token vào đây khi test.
  /// Production: lấy token từ backend của bạn (không hardcode).
  static const String rtcToken = '007eJxTYDi0xzT7su605FWX/io7q/IYmi/R3MzxJUJvQWrXzI0y+TYKDOZG5uZGyUnGaYamZiYGZoZJSZbJlkaGxsZJpimmpuapF7xWZjYEMjLs/8LOysgAgSA+P0N+UUpqUbyRpWO8oZGxiSkDAwA20iDK';

  /// AppKey cho Chat SDK. Lấy từ Console → project → Chat → Basic Info → AppKey (vd: 611369308#1668760).
  /// Nếu để rỗng thì dùng [appId] (một số project dùng chung).
  static const String chatAppKey = '611369308#1668760';

  /// Chat User ID: ID user chat (vd: customer_1). Nhập đúng ID đã dùng khi Generate token.
  static const String chatUserId = 'customer_1';

  /// Chat User Temp Token: token tạm của user. Console → Chat → nhập Chat user ID → Generate → copy vào đây.
  /// Production: lấy token từ backend.
  static const String chatToken = '007eJxTYLCJnnp/TfbKs2GsD7m9kiqnyF4/I74y1rLUcNXtbIFpjvMUGMyNzM2NkpOM0wxNzUwMzAyTkiyTLY0MjY2TTFNMTc1TWxatzGwIZGTQfOLDyMjAysAIhCC+CkOyaVJackqKga6hRaKFrqFhmqFuUqpBmm5qUkpKsrGpqZmhgSkADGomvw==';

  /// Có dùng token cho RTC không (nếu Secure Mode bật thì cần token).
  static bool get useRtcToken => rtcToken.isNotEmpty;

  /// Có token Chat để đăng nhập không.
  static bool get hasChatToken => chatToken.isNotEmpty;
}
