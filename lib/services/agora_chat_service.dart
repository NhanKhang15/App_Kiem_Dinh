import 'package:agora_chat_sdk/agora_chat_sdk.dart';
import 'package:vehicle_registration_app/config/agora_config.dart';

/// Service đơn giản cho Agora Chat: init, login, load tin nhắn, gửi tin, lắng nghe realtime.
class AgoraChatService {
  AgoraChatService._();

  static final AgoraChatService _instance = AgoraChatService._();
  static AgoraChatService get instance => _instance;

  bool _inited = false;
  bool _loggedIn = false;
  String? _currentUserId;

  bool get isLoggedIn => _loggedIn;
  String? get currentUserId => _currentUserId;

  static const String _chatEventHandlerId = 'vehicle_reg_chat';

  /// Khởi tạo SDK (gọi một lần). Dùng AppKey từ trang Chat (Basic Info); nếu rỗng thì dùng appId.
  Future<void> init({String? appKey}) async {
    if (_inited) return;
    final key = appKey?.isNotEmpty == true
        ? appKey!
        : (AgoraConfig.chatAppKey.isNotEmpty ? AgoraConfig.chatAppKey : AgoraConfig.appId);
    final options = ChatOptions(appKey: key, autoLogin: false);
    await ChatClient.getInstance.init(options);
    _inited = true;
    // ignore: avoid_print
    print('[AgoraChat] SDK init OK, appKey=${key.substring(0, key.length > 8 ? 8 : key.length)}...');
  }

  /// Đăng nhập bằng token (Chat User Temp Token từ Console).
  Future<void> loginWithToken() async {
    if (!_inited) await init();
    if (AgoraConfig.chatToken.isEmpty || AgoraConfig.chatUserId.isEmpty) {
      // ignore: avoid_print
      print('[AgoraChat] Bỏ qua login: chưa cấu hình chatToken hoặc chatUserId');
      return;
    }
    try {
      final current = await ChatClient.getInstance.getCurrentUserId();
      if (current == AgoraConfig.chatUserId) {
        _loggedIn = true;
        _currentUserId = current;
        // ignore: avoid_print
        print('[AgoraChat] Đã đăng nhập sẵn, userId=$current');
        return;
      }
    } catch (_) {}
    if (_loggedIn) return;
    try {
      await ChatClient.getInstance.loginWithToken(
        AgoraConfig.chatUserId,
        AgoraConfig.chatToken,
      );
      _loggedIn = true;
      _currentUserId = AgoraConfig.chatUserId;
      // ignore: avoid_print
      print('[AgoraChat] Login OK, userId=$_currentUserId');
    } catch (e, st) {
      final msg = e.toString();
      if (msg.contains('already logged in') || msg.contains('already_login')) {
        _loggedIn = true;
        _currentUserId = AgoraConfig.chatUserId;
        // ignore: avoid_print
        print('[AgoraChat] SDK báo đã login, coi như OK userId=$_currentUserId');
        return;
      }
      // ignore: avoid_print
      print('[AgoraChat] Login LỖI: $e');
      // ignore: avoid_print
      print('[AgoraChat] Stack: $st');
      rethrow;
    }
  }

  /// Đăng xuất (tùy chọn).
  Future<void> logout() async {
    await ChatClient.getInstance.logout();
    _loggedIn = false;
    _currentUserId = null;
  }

  /// Lấy conversation 1-1 với [peerUserId] (vd: staff_1).
  Future<ChatConversation?> getConversation(String peerUserId) async {
    if (!_loggedIn) return null;
    return ChatClient.getInstance.chatManager.getConversation(
      peerUserId,
      type: ChatConversationType.Chat,
      createIfNeed: true,
    );
  }

  /// Load lịch sử tin nhắn với [peerUserId], [loadCount] tin gần nhất.
  Future<List<ChatMessage>> loadMessages(String peerUserId, {int loadCount = 50}) async {
    final conv = await getConversation(peerUserId);
    if (conv == null) {
      // ignore: avoid_print
      print('[AgoraChat] getConversation($peerUserId) = null');
      return [];
    }
    final list = await conv.loadMessages(loadCount: loadCount, direction: ChatSearchDirection.Up);
    final result = list ?? [];
    // ignore: avoid_print
    print('[AgoraChat] loadMessages($peerUserId) = ${result.length} tin');
    return result;
  }

  /// Gửi tin nhắn text tới [peerUserId].
  Future<ChatMessage?> sendText(String peerUserId, String content) async {
    if (!_loggedIn || content.trim().isEmpty) return null;
    try {
      final msg = ChatMessage.createTxtSendMessage(targetId: peerUserId, content: content.trim());
      return await ChatClient.getInstance.chatManager.sendMessage(msg);
    } catch (_) {
      return null;
    }
  }

  /// Đăng ký lắng nghe tin nhắn mới. [onMessages] nhận danh sách tin tới (có thể từ nhiều hội thoại).
  void addMessagesListener(void Function(List<ChatMessage> messages) onMessages) {
    if (!_inited) return;
    ChatClient.getInstance.chatManager.addEventHandler(
      _chatEventHandlerId,
      ChatEventHandler(
        onMessagesReceived: (list) {
          if (list != null && list.isNotEmpty) onMessages(list);
        },
      ),
    );
  }

  /// Gỡ listener (gọi khi đóng màn chat để tránh leak).
  void removeMessagesListener() {
    ChatClient.getInstance.chatManager.removeEventHandler(_chatEventHandlerId);
  }
}
