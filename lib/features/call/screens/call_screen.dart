import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:whatsapp_ui/features/call/controller/call_controller.dart';
import 'package:whatsapp_ui/widgets/loader.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/agora_config.dart';
import '../../../model/call.dart';

class CallScreen extends ConsumerStatefulWidget {
  final String channelId;
  final Call call;
  final bool isGroup;
  const CallScreen({
    super.key,
    required this.call,
    required this.isGroup,
    required this.channelId,
  });

  @override
  ConsumerState createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;
  bool _isFrontCamera = true;
  bool _isInitializing = true;
  String? _token;
  String baseUrl = 'https://twitch-backend-server.onrender.com';

  DateTime? callStartTime;
  bool callAnswered = false;
  bool _isCallEnded = false;
  bool _showLoadingScreen = true; // Control when to hide loading

  bool get isVideoCall => widget.call.isVideoCall;

  @override
  void initState() {
    super.initState();
    initAgora();

    // Hide loading screen after 3 seconds even if remote user hasn't joined
    // This ensures caller sees the call screen
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showLoadingScreen = false;
        });
      }
    });
  }

  Future<void> initAgora() async {
    // Request permissions
    if (isVideoCall) {
      await [Permission.microphone, Permission.camera].request();
    } else {
      await [Permission.microphone].request();
    }

    // Fetch token from server
    await _fetchToken();

    // Create RTC engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
      appId: AgoraConfig.appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("Local user ${connection.localUid} joined ${isVideoCall ? 'video' : 'audio'} call");
          setState(() {
            _localUserJoined = true;
            _isInitializing = false;
            // Hide loading immediately when local user joins
            _showLoadingScreen = false;
          });
          // Set speaker after joining channel (audio calls only)
          if (!isVideoCall) {
            _engine.setEnableSpeakerphone(_isSpeakerOn).catchError((error) {
              debugPrint('Speaker error: $error');
            });
          }
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("Remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
            callAnswered = true;
            callStartTime = DateTime.now();
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint("Remote user $remoteUid left channel");
          setState(() {
            _remoteUid = null;
          });
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          debugPrint(
              '[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token');
          _fetchToken();
        },
      ),
    );

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    if (isVideoCall) {
      await _engine.enableVideo();
      await _engine.startPreview();
    } else {
      await _engine.disableVideo();
      await _engine.enableAudio();
      await _engine.setAudioProfile(
        profile: AudioProfileType.audioProfileDefault,
        scenario: AudioScenarioType.audioScenarioChatroom,
      );
    }

    await _engine.joinChannel(
      token: _token ?? '',
      channelId: widget.channelId,
      uid: 0,
      options: ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: true,
        publishCameraTrack: isVideoCall,
        autoSubscribeAudio: true,
        autoSubscribeVideo: isVideoCall,
      ),
    );
  }

  Future<void> _fetchToken() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rtc/${widget.channelId}/publisher/uid/0'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _token = data['rtcToken'];
        });
        debugPrint('Token fetched: $_token');
      } else {
        debugPrint('Failed to fetch token: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching token: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
    _dispose();
  }

  Future<void> _dispose() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  void _onToggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _engine.muteLocalAudioStream(_isMuted);
  }

  void _onToggleCamera() {
    if (!isVideoCall) return;
    setState(() {
      _isCameraOff = !_isCameraOff;
    });
    _engine.muteLocalVideoStream(_isCameraOff);
  }

  void _onSwitchCamera() {
    if (!isVideoCall) return;
    _engine.switchCamera();
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
  }

  void _onToggleSpeaker() {
    if (isVideoCall) return;
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    _engine.setEnableSpeakerphone(_isSpeakerOn).catchError((error) {
      debugPrint('Speaker toggle error: $error');
      setState(() {
        _isSpeakerOn = !_isSpeakerOn;
      });
    });
  }

  void _onCallEnd(BuildContext context) async {
    if (_isCallEnded) return; // Prevent multiple calls

    setState(() {
      _isCallEnded = true;
    });

    int duration = 0;
    String status = 'missed';

    if (callAnswered && callStartTime != null) {
      duration = DateTime.now().difference(callStartTime!).inSeconds;
      status = 'dialed';
    }

    // Save call history
    ref.read(callControllerProvider).saveCallHistory(
      callId: widget.call.callId,
      callerName: widget.call.callerName,
      callerId: widget.call.callerId,
      callerPic: widget.call.callerPic,
      receiverName: widget.call.receiverName,
      receiverId: widget.call.receiverId,
      receiverPic: widget.call.receiverPic,
      isVideoCall: widget.call.isVideoCall,
      status: status,
      duration: duration,
    );

    // Leave Agora channel
    await _engine.leaveChannel();

    // End call in Firestore
    ref.read(callControllerProvider).endCall(
        widget.call.callerId,
        widget.call.receiverId,
        context,
        widget.isGroup
    );

    // Navigate back
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back button during call
        return false;
      },
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('call')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          // ✅ Auto-close if call document deleted by other user (only if call not already ended by us)
          if (snapshot.hasData && !snapshot.data!.exists && !_isCallEnded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            });
            return const SizedBox.shrink();
          }

          // Show loading only initially and for short time
          if (_showLoadingScreen) {
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: Loader(),
              ),
            );
          }

          return isVideoCall ? _buildVideoCallUI() : _buildAudioCallUI();
        },
      ),
    );
  }

  // Video Call UI
  Widget _buildVideoCallUI() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _remoteVideo(),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              margin: const EdgeInsets.all(16),
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _localUserJoined
                    ? AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _engine,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                )
                    : const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
          ),
          _videoToolbar(),
        ],
      ),
    );
  }

  // Audio Call UI - Fixed RenderFlex overflow
  Widget _buildAudioCallUI() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      // Profile Picture
                      CircleAvatar(
                        radius: 70,
                        backgroundImage: NetworkImage(widget.call.receiverPic),
                      ),

                      const SizedBox(height: 20),

                      // Name
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          widget.call.receiverName,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Call Status
                      Text(
                        _remoteUid != null ? 'Connected' : 'Calling...',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[400],
                        ),
                      ),

                      const Spacer(),

                      // Audio Controls
                      _audioToolbar(),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Display remote user's video
  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelId),
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.call.receiverPic),
              radius: 60,
            ),
            const SizedBox(height: 20),
            Text(
              widget.call.receiverName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Calling...',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }
  }

  // Video call toolbar
  Widget _videoToolbar() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 👈 evenly distribute
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Flexible(
            child: RawMaterialButton(
              onPressed: _onToggleMute,
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: _isMuted ? Colors.blueAccent : Colors.white,
              padding: const EdgeInsets.all(12.0),
              child: Icon(
                _isMuted ? Icons.mic_off : Icons.mic,
                color: _isMuted ? Colors.white : Colors.blueAccent,
                size: 20.0,
              ),
            ),
          ),
          Flexible(
            child: RawMaterialButton(
              onPressed: () => _onCallEnd(context),
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.redAccent,
              padding: const EdgeInsets.all(15.0),
              child: const Icon(
                Icons.call_end,
                color: Colors.white,
                size: 35.0,
              ),
            ),
          ),
          Flexible(
            child: RawMaterialButton(
              onPressed: _onToggleCamera,
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: _isCameraOff ? Colors.blueAccent : Colors.white,
              padding: const EdgeInsets.all(12.0),
              child: Icon(
                _isCameraOff ? Icons.videocam_off : Icons.videocam,
                color: _isCameraOff ? Colors.white : Colors.blueAccent,
                size: 20.0,
              ),
            ),
          ),
          Flexible(
            child: RawMaterialButton(
              onPressed: _onSwitchCamera,
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.white,
              padding: const EdgeInsets.all(12.0),
              child: const Icon(
                Icons.switch_camera,
                color: Colors.blueAccent,
                size: 20.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _audioToolbar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: Speaker and Mute buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.max,
            children: [
              // Speaker Button
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RawMaterialButton(
                      onPressed: _onToggleSpeaker,
                      shape: const CircleBorder(),
                      elevation: 2.0,
                      fillColor: _isSpeakerOn ? Colors.white : Colors.blueAccent,
                      padding: const EdgeInsets.all(16.0),
                      child: Icon(
                        _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                        color: _isSpeakerOn ? Colors.blueAccent : Colors.white,
                        size: 24.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Speaker',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Mute Button
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RawMaterialButton(
                      onPressed: _onToggleMute,
                      shape: const CircleBorder(),
                      elevation: 2.0,
                      fillColor: _isMuted ? Colors.blueAccent : Colors.white,
                      padding: const EdgeInsets.all(16.0),
                      child: Icon(
                        _isMuted ? Icons.mic_off : Icons.mic,
                        color: _isMuted ? Colors.white : Colors.blueAccent,
                        size: 24.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isMuted ? 'Unmute' : 'Mute',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 50),

          // Bottom: End Call Button (centered)
          RawMaterialButton(
            onPressed: () => _onCallEnd(context),
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(18.0),
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 32.0,
            ),
          ),
        ],
      ),
    );
  }
}