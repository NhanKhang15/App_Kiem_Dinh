import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vehicle_registration_app/config/agora_config.dart';

/// Màn gọi thoại trong app bằng Agora RTC. Cần [channelId] và token trong [AgoraConfig.rtcToken].
class AgoraCallScreen extends StatefulWidget {
  const AgoraCallScreen({
    super.key,
    required this.channelId,
    this.channelToken,
    this.remoteTitle = 'Nhân viên',
  });

  final String channelId;
  final String? channelToken;
  final String remoteTitle;

  @override
  State<AgoraCallScreen> createState() => _AgoraCallScreenState();
}

class _AgoraCallScreenState extends State<AgoraCallScreen> {
  RtcEngine? _engine;
  int? _remoteUid;
  String _status = 'Đang kết nối...';
  bool _muted = false;
  bool _speakerOn = true; // Loa ngoài mặc định để nghe rõ hơn
  int _callSeconds = 0;
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    _initAndJoin();
  }

  Future<void> _initAndJoin() async {
    final token = widget.channelToken ?? AgoraConfig.rtcToken;
    if (token.isEmpty) {
      setState(() {
        _status = 'Chưa cấu hình RTC token. Xem docs/AGORA_SETUP.md';
      });
      return;
    }

    // Android/iOS: cần quyền microphone để gọi thoại
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (!mounted) return;
      setState(() {
        _status = 'Cần cấp quyền micro để gọi. Vào Cài đặt → Ứng dụng → Quyền.';
      });
      return;
    }

    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(
        RtcEngineContext(
          appId: AgoraConfig.appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
      await _engine!.enableAudio();
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection conn, int elapsed) {
            if (!mounted) return;
            setState(() {
              _status = 'Đã vào kênh. Đang chờ ${widget.remoteTitle}...';
            });
            _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
              if (!mounted) return;
              setState(() => _callSeconds++);
            });
            _engine?.setEnableSpeakerphone(true);
          },
          onUserJoined: (RtcConnection conn, int remoteUid, int elapsed) {
            if (!mounted) return;
            setState(() {
              _remoteUid = remoteUid;
              _status = 'Đang nói chuyện với ${widget.remoteTitle}';
            });
          },
          onUserOffline: (RtcConnection conn, int remoteUid, UserOfflineReasonType reason) {
            if (!mounted) return;
            setState(() {
              _remoteUid = null;
              _status = 'Đã ngắt kết nối.';
            });
          },
          onError: (ErrorCodeType err, String msg) {
            if (!mounted) return;
            setState(() => _status = 'Lỗi: $msg');
          },
        ),
      );

      await _engine!.joinChannel(
        token: token,
        channelId: widget.channelId,
        uid: 0,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          autoSubscribeAudio: true,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Lỗi: $e');
    }
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  Future<void> _leave() async {
    await _engine?.leaveChannel();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _toggleMute() async {
    setState(() => _muted = !_muted);
    await _engine?.muteLocalAudioStream(_muted);
  }

  Future<void> _toggleSpeaker() async {
    setState(() => _speakerOn = !_speakerOn);
    await _engine?.setEnableSpeakerphone(_speakerOn);
  }

  String get _durationText {
    final m = _callSeconds ~/ 60;
    final s = _callSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0EA5E9),
              Color(0xFF06B6D4),
              Color(0xFF14B8A6),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Thời gian gọi
              Text(
                _durationText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.remoteTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // Avatar
              CircleAvatar(
                radius: 56,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                child: Icon(
                  _remoteUid != null ? Icons.person_rounded : Icons.person_outline_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              // 3 nút: Mic, Kết thúc, Loa (kiểu Zalo / iOS)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _callControlButton(
                      icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      label: _muted ? 'Bật mic' : 'Tắt mic',
                      onTap: _toggleMute,
                      size: 72,
                      iconSize: 32,
                    ),
                    _callControlButton(
                      icon: Icons.call_end_rounded,
                      label: 'Kết thúc',
                      onTap: _leave,
                      size: 88,
                      iconSize: 40,
                      backgroundColor: const Color(0xFFDC2626),
                    ),
                    _callControlButton(
                      icon: _speakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                      label: 'Loa to hơn',
                      onTap: _toggleSpeaker,
                      size: 72,
                      iconSize: 32,
                      isActive: _speakerOn,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _callControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    double size = 64,
    double iconSize = 28,
    Color? backgroundColor,
    bool isActive = false,
  }) {
    final bg = backgroundColor ??
        (isActive
            ? Colors.white.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.18));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: bg,
          shape: const CircleBorder(),
          elevation: 0,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, color: Colors.white, size: iconSize),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
