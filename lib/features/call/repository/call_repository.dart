import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:whatsapp_ui/common/repositories/common_firebase_storage_repository.dart';
import 'package:whatsapp_ui/common/utils/utils.dart';
import 'package:whatsapp_ui/features/call/screens/call_screen.dart';
import 'package:whatsapp_ui/model/group.dart';

import '../../../model/call.dart';
import '../../call_history/model.dart';

final callRepositoryProvider=Provider(
        (ref)=>CallRepository( firestore: FirebaseFirestore.instance, auth: FirebaseAuth.instance)
);

class CallRepository{
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  CallRepository({
    required this.firestore,
    required this.auth
  });

  Stream<DocumentSnapshot> get callStream=>
      firestore.collection('call').doc(auth.currentUser!.uid).snapshots();

  void makeCall(Call senderCallData , BuildContext context , Call receiverCallData)async {
    try {
      await firestore.collection('call').doc(senderCallData.callerId).set(
          senderCallData.toMap());

      await Future.delayed(const Duration(seconds: 2));

      await firestore.collection('call').doc(senderCallData.receiverId).set(
          receiverCallData.toMap());

      Navigator.push(context, MaterialPageRoute(builder: (context) =>
          CallScreen(call: senderCallData,
              isGroup: false,
              channelId: senderCallData.callId)));
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  void makeGroupCall(
      Call senderCallData ,
      BuildContext context ,
      Call receiverCallData
      )async {
    try {
      await firestore.collection('call').doc(senderCallData.callerId).set(
          senderCallData.toMap());

      var groupSnapshot=await firestore.collection('groups').doc(senderCallData.receiverId).get();


      Group group=Group.fromMap(groupSnapshot.data()!);

      await Future.delayed(const Duration(seconds: 2));

      for(var id in group.membersUid){
        await firestore.collection('call').doc(id).set(receiverCallData.toMap());
      }

      Navigator.push(context, MaterialPageRoute(builder: (context) =>
          CallScreen(call: senderCallData,
              isGroup: true,
              channelId: senderCallData.callId)));
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  void endCall(
      String callerId,
      String receiverId,
      BuildContext context,
      )async{
    try{
      await firestore.collection('call').doc(callerId).delete();

      await firestore.collection('call').doc(receiverId).delete();


    }catch(e){
      showSnackBar(context: context, content: e.toString());
    }
  }

  void endGroupCall(
      String callerId,
      String receiverId,
      BuildContext context,
      )async{
    try{
      await firestore.collection('call').doc(callerId).delete();
      var groupSnapshot=await firestore.collection('groups').doc(receiverId).get();

      Group group=Group.fromMap(groupSnapshot.data()!);

      for(var id in group.membersUid){
        await firestore.collection('call').doc(id).delete();
      }

    }catch(e){
      showSnackBar(context: context, content: e.toString());
    }
  }


  // ========== ADD THESE NEW METHODS ==========

  Future<void> saveCallHistory({
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
  }) async {
    try {
      final timestamp = DateTime.now();

      final callHistory = CallHistory(
        callId: callId,
        callerName: callerName,
        callerId: callerId,
        callerPic: callerPic,
        receiverName: receiverName,
        receiverId: receiverId,
        receiverPic: receiverPic,
        isVideoCall: isVideoCall,
        timestamp: timestamp,
        status: status,
        duration: duration,
      );

      await firestore
          .collection('users')
          .doc(callerId)
          .collection('callHistory')
          .doc(callId)
          .set(callHistory.toMap());

      String receiverStatus = status;
      if (status == 'dialed') {
        receiverStatus = 'received';
      } else if (status == 'received') {
        receiverStatus = 'dialed';
      }

      final receiverCallHistory = CallHistory(
        callId: callId,
        callerName: callerName,
        callerId: callerId,
        callerPic: callerPic,
        receiverName: receiverName,
        receiverId: receiverId,
        receiverPic: receiverPic,
        isVideoCall: isVideoCall,
        timestamp: timestamp,
        status: receiverStatus,
        duration: duration,
      );

      await firestore
          .collection('users')
          .doc(receiverId)
          .collection('callHistory')
          .doc(callId)
          .set(receiverCallHistory.toMap());

      print('✅ Call history saved');
    } catch (e) {
      print('❌ Error saving call history: $e');
    }
  }

  Stream<List<CallHistory>> getCallHistory() {
    return firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('callHistory')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CallHistory.fromMap(doc.data());
      }).toList();
    });
  }

  Future<void> deleteCallHistory(String callId) async {
    try {
      await firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('callHistory')
          .doc(callId)
          .delete();
    } catch (e) {
      print('❌ Error deleting: $e');
    }
  }

  Future<void> clearAllCallHistory() async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('callHistory')
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('❌ Error clearing: $e');
    }
  }

}