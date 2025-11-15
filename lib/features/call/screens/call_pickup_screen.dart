import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/features/call/controller/call_controller.dart';
import 'package:whatsapp_ui/main.dart';

import '../../../model/call.dart';
import 'call_screen.dart';

class CallPickupScreen extends ConsumerStatefulWidget {
  final Widget scaffold;
  const CallPickupScreen({Key? key, required this.scaffold}) : super(key: key);

  @override
  ConsumerState<CallPickupScreen> createState() => _CallPickupScreenState();
}

class _CallPickupScreenState extends ConsumerState<CallPickupScreen> {
  bool _dialogShown = false;
  String? _currentCallId;
  Timer? _callTimeout;
  bool _isCallIgnored = false; // Track if call is ignored

  @override
  void dispose() {
    _callTimeout?.cancel();
    super.dispose();
  }

  void _startCallTimeout(Call call, BuildContext dialogContext) {
    // Cancel any existing timer
    _callTimeout?.cancel();

    // Start 45-second timeout
    _callTimeout = Timer(const Duration(seconds: 45), () {
      if (mounted && !_isCallIgnored) {
        // Auto-reject call after timeout
        _dialogShown = false;
        _currentCallId = null;

        if (Navigator.canPop(dialogContext)) {
          Navigator.of(dialogContext).pop();
        }

        // Save as missed call
        ref.read(callControllerProvider).saveCallHistory(
          callId: call.callId,
          callerName: call.callerName,
          callerId: call.callerId,
          callerPic: call.callerPic,
          receiverName: call.receiverName,
          receiverId: call.receiverId,
          receiverPic: call.receiverPic,
          isVideoCall: call.isVideoCall,
          status: 'missed',
          duration: 0,
        );

        // End call in Firestore
        ref.read(callControllerProvider).endCall(
          call.callerId,
          call.receiverId,
          context,
          false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: ref.watch(callControllerProvider).callStream,
      builder: (streamContext, snapshot) {
        if (snapshot.hasData && snapshot.data!.data() != null) {
          Call call = Call.fromMap(snapshot.data!.data() as Map<String, dynamic>);

          // Only show dialog for incoming calls (not dialed by current user)
          if (!call.hasDialled && call.receiverId == FirebaseAuth.instance.currentUser!.uid) {

            // Check if already on call screen
            final currentRoute = ModalRoute.of(streamContext);
            if (currentRoute?.settings.name == '/call-screen' ||
                currentRoute is MaterialPageRoute && currentRoute.builder.toString().contains('CallScreen')) {
              _callTimeout?.cancel();
              return widget.scaffold;
            }

            // Reset ignored flag for new calls
            if (_currentCallId != call.callId) {
              _isCallIgnored = false;
            }

            // Show incoming call dialog only if not ignored
            if ((!_dialogShown || _currentCallId != call.callId) && !_isCallIgnored) {
              _dialogShown = true;
              _currentCallId = call.callId;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (navigatorKey.currentContext != null) {
                  final existingRoute = ModalRoute.of(navigatorKey.currentContext!);
                  if (existingRoute?.settings.name != '/call-screen') {
                    showDialog(
                      context: navigatorKey.currentContext!,
                      barrierDismissible: false,
                      builder: (dialogContext) {
                        // Start timeout timer when dialog opens
                        _startCallTimeout(call, dialogContext);

                        return WillPopScope(
                          onWillPop: () async {
                            // Allow back button to ignore call
                            _isCallIgnored = true;
                            _dialogShown = false;
                            _callTimeout?.cancel();
                            return true; // Allow dialog to close
                          },
                          child: StreamBuilder<DocumentSnapshot>(
                            // Listen to call document changes to auto-close dialog
                            stream: FirebaseFirestore.instance
                                .collection('call')
                                .doc(FirebaseAuth.instance.currentUser!.uid)
                                .snapshots(),
                            builder: (context, callSnapshot) {
                              // Auto-close dialog if call document is deleted (caller ended call)
                              if (callSnapshot.hasData && !callSnapshot.data!.exists) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  _callTimeout?.cancel();
                                  if (Navigator.canPop(dialogContext)) {
                                    Navigator.of(dialogContext).pop();
                                    _dialogShown = false;
                                    _currentCallId = null;
                                    _isCallIgnored = false;
                                  }
                                });
                                return const SizedBox.shrink();
                              }

                              return Dialog(
                                backgroundColor: Colors.black,
                                insetPadding: EdgeInsets.zero,
                                child: Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Incoming Call',
                                        style: TextStyle(
                                            fontSize: 30,
                                            color: Colors.white
                                        ),
                                      ),
                                      const SizedBox(height: 50),
                                      CircleAvatar(
                                        backgroundImage: NetworkImage(call.callerPic),
                                        radius: 60,
                                      ),
                                      const SizedBox(height: 50),
                                      Text(
                                        call.callerName,
                                        style: const TextStyle(
                                            fontSize: 25,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900
                                        ),
                                      ),
                                      const SizedBox(height: 75),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // Reject Button
                                          IconButton(
                                            onPressed: () {
                                              _callTimeout?.cancel();
                                              _dialogShown = false;
                                              _currentCallId = null;
                                              _isCallIgnored = false;
                                              Navigator.of(dialogContext).pop();

                                              ref.read(callControllerProvider).saveCallHistory(
                                                callId: call.callId,
                                                callerName: call.callerName,
                                                callerId: call.callerId,
                                                callerPic: call.callerPic,
                                                receiverName: call.receiverName,
                                                receiverId: call.receiverId,
                                                receiverPic: call.receiverPic,
                                                isVideoCall: call.isVideoCall,
                                                status: 'rejected',
                                                duration: 0,
                                              );

                                              ref.read(callControllerProvider).endCall(
                                                  call.callerId,
                                                  call.receiverId,
                                                  dialogContext,
                                                  false
                                              );
                                            },
                                            icon: const Icon(Icons.call_end, color: Colors.redAccent, size: 40),
                                          ),
                                          const SizedBox(width: 60),

                                          // Accept Button
                                          IconButton(
                                            onPressed: () {
                                              _callTimeout?.cancel();
                                              _dialogShown = false;
                                              _currentCallId = null;
                                              _isCallIgnored = false;
                                              Navigator.of(dialogContext).pop();

                                              Navigator.of(navigatorKey.currentContext!).push(
                                                MaterialPageRoute(
                                                  settings: const RouteSettings(name: '/call-screen'),
                                                  builder: (context) => CallScreen(
                                                    call: call,
                                                    isGroup: false,
                                                    channelId: call.callId,
                                                  ),
                                                ),
                                              ).then((_) {
                                                // Reset dialog flag when returning from call screen
                                                _dialogShown = false;
                                                _currentCallId = null;
                                                _isCallIgnored = false;
                                              });
                                            },
                                            icon: Icon(
                                              call.isVideoCall ? Icons.videocam : Icons.call,
                                              color: Colors.green,
                                              size: 40,
                                            ),
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 30),
                                      // Hint for back button
                                      Text(
                                        'Press back to ignore',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ).then((_) {
                      // Reset flag if dialog dismissed
                      _callTimeout?.cancel();
                      if (!_isCallIgnored) {
                        _dialogShown = false;
                        _currentCallId = null;
                      }
                    });
                  }
                }
              });
            }
          } else {
            // Reset flags if not an incoming call
            _callTimeout?.cancel();
            _dialogShown = false;
            _currentCallId = null;
            _isCallIgnored = false;
          }
        } else {
          // Reset flags if no call data
          _callTimeout?.cancel();
          _dialogShown = false;
          _currentCallId = null;
          _isCallIgnored = false;
        }

        return widget.scaffold;
      },
    );
  }
}