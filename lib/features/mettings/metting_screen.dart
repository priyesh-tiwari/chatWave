import 'dart:convert';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:whatsapp_ui/config/agora_config.dart';
import 'package:whatsapp_ui/widgets/loader.dart';

import 'meeting_model.dart';
import 'metting_controller.dart';

class MeetingScreen extends ConsumerStatefulWidget {
  final Meeting meeting;
  final bool isCreator;

  const MeetingScreen({
    Key? key,
    required this.meeting,
    required this.isCreator,
  }) : super(key: key);

  @override
  ConsumerState<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends ConsumerState<MeetingScreen> {
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;
  bool _isFrontCamera = true;
  bool _isInitializing = true;
  String? _token;
  final String baseUrl = 'https://twitch-backend-server.onrender.com';
  int _meetingDuration = 0;
  late DateTime _meetingStartTime;

  bool get isVideoMeeting => widget.meeting.isVideoMeeting;

  @override
  void initState() {
    super.initState();
    _meetingStartTime = DateTime.now();
    initAgora();
    _startDurationTimer();
  }

  void _startDurationTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _meetingDuration =
              DateTime.now().difference(_meetingStartTime).inSeconds;
        });
        _startDurationTimer();
      }
    });
  }

  String _formatDuration(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  Future<void> initAgora() async {
    if (isVideoMeeting) {
      await [Permission.microphone, Permission.camera].request();
    } else {
      await [Permission.microphone].request();
    }

    await _fetchToken();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
      appId: AgoraConfig.appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("Local user joined meeting");
          setState(() {
            _localUserJoined = true;
            _isInitializing = false;
          });
          if (!isVideoMeeting) {
            _engine.setEnableSpeakerphone(_isSpeakerOn).catchError((error) {
              debugPrint('Speaker error: $error');
            });
          }
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("Remote user $remoteUid joined meeting");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint("Remote user $remoteUid left meeting");
          setState(() {
            _remoteUid = null;
          });
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          _fetchToken();
        },
      ),
    );

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    if (isVideoMeeting) {
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
      channelId: widget.meeting.meetingId,
      uid: 0,
      options: ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: true,
        publishCameraTrack: isVideoMeeting,
        autoSubscribeAudio: true,
        autoSubscribeVideo: isVideoMeeting,
      ),
    );
  }

  Future<void> _fetchToken() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rtc/${widget.meeting.meetingId}/publisher/uid/0'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _token = data['rtcToken'];
        });
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

    // Only update if creator leaves
    if (widget.isCreator) {
      await ref
          .read(meetingControllerProvider)
          .endMeeting(meetingId: widget.meeting.meetingId, context: context);
    } else {
      await ref
          .read(meetingControllerProvider)
          .leaveMeeting(meetingId: widget.meeting.meetingId);
    }
  }

  void _onToggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _engine.muteLocalAudioStream(_isMuted);
  }

  void _onToggleCamera() {
    if (!isVideoMeeting) return;
    setState(() {
      _isCameraOff = !_isCameraOff;
    });
    _engine.muteLocalVideoStream(_isCameraOff);
  }

  void _onSwitchCamera() {
    if (!isVideoMeeting) return;
    _engine.switchCamera();
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
  }

  void _onToggleSpeaker() {
    if (isVideoMeeting) return;
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    _engine.setEnableSpeakerphone(_isSpeakerOn).catchError((error) {
      setState(() {
        _isSpeakerOn = !_isSpeakerOn;
      });
    });
  }

  void _endMeeting() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Loader()),
      );
    }

    return isVideoMeeting ? _buildVideoMeetingUI() : _buildAudioMeetingUI();
  }

  Widget _buildVideoMeetingUI() {
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
          _buildMeetingInfo(),
          _buildVideoToolbar(),
        ],
      ),
    );
  }

  Widget _buildAudioMeetingUI() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            CircleAvatar(
              radius: 80,
              backgroundImage: NetworkImage(widget.meeting.creatorPic),
            ),
            const SizedBox(height: 24),
            Text(
              widget.meeting.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _formatDuration(_meetingDuration),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: _buildParticipantsList(),
            ),
            _buildAudioToolbar(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingInfo() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.meeting.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDuration(_meetingDuration),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsList() {
    return StreamBuilder<Meeting?>(
      stream: ref
          .read(meetingControllerProvider)
          .getMeetingStream(widget.meeting.meetingId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(
            child: Text(
              'No participants',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final meeting = snapshot.data!;
        return ListView.builder(
          itemCount: meeting.participantNames.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  CircleAvatar(
                    radius: 20,
                    child: Text(
                      meeting.participantNames[index][0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      meeting.participantNames[index],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.meeting.meetingId),
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.meeting.creatorPic),
              radius: 60,
            ),
            const SizedBox(height: 20),
            Text(
              widget.meeting.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Waiting for participants...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }
  }

  // ------------------------------ FIXED TOOLBAR ------------------------------

  Widget _buildVideoToolbar() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // FIX ADDED HERE
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RawMaterialButton(
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
            const SizedBox(width: 15),
            RawMaterialButton(
              onPressed: _endMeeting,
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
            const SizedBox(width: 15),
            RawMaterialButton(
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
            const SizedBox(width: 15),
            RawMaterialButton(
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
          ],
        ),
      ),
    );
  }

  Widget _buildAudioToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  RawMaterialButton(
                    onPressed: _onToggleSpeaker,
                    shape: const CircleBorder(),
                    elevation: 2.0,
                    fillColor: _isSpeakerOn ? Colors.white : Colors.blueAccent,
                    padding: const EdgeInsets.all(20.0),
                    child: Icon(
                      _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                      color: _isSpeakerOn ? Colors.blueAccent : Colors.white,
                      size: 28.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Speaker',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  RawMaterialButton(
                    onPressed: _onToggleMute,
                    shape: const CircleBorder(),
                    elevation: 2.0,
                    fillColor: _isMuted ? Colors.blueAccent : Colors.white,
                    padding: const EdgeInsets.all(20.0),
                    child: Icon(
                      _isMuted ? Icons.mic_off : Icons.mic,
                      color: _isMuted ? Colors.white : Colors.blueAccent,
                      size: 28.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isMuted ? 'Unmute' : 'Mute',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 60),
          RawMaterialButton(
            onPressed: _endMeeting,
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(20.0),
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 35.0,
            ),
          ),
        ],
      ),
    );
  }
}
