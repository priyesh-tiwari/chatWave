import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:whatsapp_ui/model/call.dart';

import '../../call_history/model.dart';
import '../repository/call_repository.dart';

final callControllerProvider = Provider((ref) {
  final callRepository = ref.read(callRepositoryProvider);
  return CallController(
      auth: FirebaseAuth.instance, callRepository: callRepository, ref: ref);
});

class CallController {
  final CallRepository callRepository;
  final ProviderRef ref;
  final FirebaseAuth auth;
  CallController(
      {required this.callRepository, required this.ref, required this.auth});

  Stream<DocumentSnapshot> get callStream => callRepository.callStream;

  void makeCall(BuildContext context, String receiverName, String receiverUid,
      String receiverProfilePic, bool isGroup,
      {required bool isVideoCall}) async {
    print('===== MAKE CALL TAPPED =====');

    try {
      // Fetch user data directly from Firestore (most reliable)
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(auth.currentUser!.uid)
          .get();

      if (!userDoc.exists) {
        print('❌ User document does not exist');
        return;
      }

      final userData = userDoc.data()!;
      print('✅ User data fetched: ${userData['name']}');

      String callId = const Uuid().v1();

      Call senderCallData = Call(
        auth.currentUser!.uid,
        userData['name'] ?? 'Unknown',
        userData['profilePic'] ?? '',
        receiverUid,
        receiverName,
        receiverProfilePic,
        callId,
        true,
        isVideoCall,
      );

      Call receiverCallData = Call(
        auth.currentUser!.uid,
        userData['name'] ?? 'Unknown',
        userData['profilePic'] ?? '',
        receiverUid,
        receiverName,
        receiverProfilePic,
        callId,
        false,
        isVideoCall,
      );

      print('✅ Making call...');

      if (isGroup) {
        callRepository.makeGroupCall(senderCallData, context, receiverCallData);
      } else {
        callRepository.makeCall(senderCallData, context, receiverCallData);
      }
    } catch (e) {
      print('❌ Error making call: $e');
    }
  }

  void _executeMakeCall(
      BuildContext context,
      String receiverName,
      String receiverUid,
      String receiverProfilePic,
      bool isGroup,
      bool isVideoCall,
      String userName,
      String userPic) {
    String callId = const Uuid().v1();

    Call senderCallData = Call(
      auth.currentUser!.uid,
      userName,
      userPic,
      receiverUid,
      receiverName,
      receiverProfilePic,
      callId,
      true,
      isVideoCall,
    );

    Call receiverCallData = Call(
      auth.currentUser!.uid,
      userName,
      userPic,
      receiverUid,
      receiverName,
      receiverProfilePic,
      callId,
      false,
      isVideoCall,
    );

    if (isGroup) {
      callRepository.makeGroupCall(senderCallData, context, receiverCallData);
    } else {
      callRepository.makeCall(senderCallData, context, receiverCallData);
    }
  }

  void endCall(
      String callerId, String receiverId, BuildContext context, bool isGroup) {
    if (isGroup) {
      callRepository.endGroupCall(callerId, receiverId, context);
    } else {
      callRepository.endCall(callerId, receiverId, context);
    }
  }

  // ========== ADD THESE NEW METHODS ==========

  void saveCallHistory({
    required String callId,
    required String callerName,
    required String callerId,
    required String callerPic,
    required String receiverName,
    required String receiverId,
    required String receiverPic,
    required bool isVideoCall,
    required String status,
    required int duration,
  }) {
    callRepository.saveCallHistory(
      callId: callId,
      callerName: callerName,
      callerId: callerId,
      callerPic: callerPic,
      receiverName: receiverName,
      receiverId: receiverId,
      receiverPic: receiverPic,
      isVideoCall: isVideoCall,
      status: status,
      duration: duration,
    );
  }

  Stream<List<CallHistory>> getCallHistory() {
    return callRepository.getCallHistory();
  }

  void deleteCallHistory(BuildContext context, String callId) {
    callRepository.deleteCallHistory(callId);
  }

  void clearAllCallHistory(BuildContext context) {
    callRepository.clearAllCallHistory();
  }
}
