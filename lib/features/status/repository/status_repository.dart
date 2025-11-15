import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:whatsapp_ui/cloudinary.dart';
import 'package:whatsapp_ui/common/utils/utils.dart';
import '../../../model/status_model.dart';
import '../../../model/user_model.dart';

final stateRepositoryProvider=Provider(
    (ref)=> StatusRepository(
      firestore: FirebaseFirestore.instance, auth: FirebaseAuth.instance,
      ref: ref
    )
);

class StatusRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final ProviderRef ref;

  StatusRepository({
    required this.firestore,
    required this.auth,
    required this.ref
  });

  Future<void> uploadStatus({
    required String username,
    required String profilePic,
    required String phoneNumber,
    required File statusImage,
    required BuildContext context
  }) async {
    try {
      print('📤 Starting uploadStatus...');

      var statusId = const Uuid().v1();
      print('🆔 Generated statusId: $statusId');

      String uid = auth.currentUser!.uid;
      print('👤 Current UID: $uid');

      print('☁️ Uploading image to Cloudinary...');
      String imageUrl = await uploadFileToCloudinary(statusImage, 'image');
      print('✅ Image uploaded: $imageUrl');

      List<Contact> contacts = [];

      if (await FlutterContacts.requestPermission()) {
        contacts = await FlutterContacts.getContacts(withProperties: true);
        print('📱 Found ${contacts.length} contacts');
      }

      List<String> uidWhoCanSee = [uid];
      print('👥 Starting with uidWhoCanSee: $uidWhoCanSee');

      for (int i = 0; i < contacts.length; i++) {
        if (contacts[i].phones.isEmpty) continue;

        String cleanPhone = contacts[i].phones[0].number.replaceAll(RegExp(r'\D'), '');

        var allUsers = await firestore.collection('users').get();

        for (var userDoc in allUsers.docs) {
          String firestorePhone = (userDoc.data()['phoneNumber'] ?? '').replaceAll(RegExp(r'\D'), '');

          if (cleanPhone.length >= 10 && firestorePhone.length >= 10) {
            String contactLast10 = cleanPhone.substring(cleanPhone.length - 10);
            String firestoreLast10 = firestorePhone.substring(firestorePhone.length - 10);

            if (contactLast10 == firestoreLast10) {
              String matchedUid = userDoc.id;
              if (!uidWhoCanSee.contains(matchedUid)) {
                uidWhoCanSee.add(matchedUid);
                break;
              }
            }
          }
        }
      }
      print('👥 Final uidWhoCanSee: $uidWhoCanSee (${uidWhoCanSee.length} users)');

      List<String> statusImageUrls = [];

      print('🔍 Checking for existing status...');
      var statusesSnapshot = await firestore.collection('status').where(
          'uid', isEqualTo: auth.currentUser!.uid).get();

      print('📊 Found ${statusesSnapshot.docs.length} existing status documents');

      if (statusesSnapshot.docs.isNotEmpty) {
        print('♻️ Updating existing status...');
        Status status = Status.fromMap(statusesSnapshot.docs[0].data());
        statusImageUrls = status.photoUrl;
        statusImageUrls.add(imageUrl);

        List<DateTime> photoTimestamps = status.photoTimestamps ?? [];
        photoTimestamps.add(DateTime.now());

        await firestore
            .collection('status')
            .doc(statusesSnapshot.docs[0].id)
            .update({
          'photoUrl': statusImageUrls ,
          'photoTimestamps': photoTimestamps,
          'createdAt': FieldValue.serverTimestamp(),
        });

        print('✅ Status updated successfully');
        return;
      } else {
        print('📝 Creating new status...');
        statusImageUrls = [imageUrl];

        List<DateTime> photoTimestamps = [DateTime.now()];

        Status status = Status(
            uid: uid,
            username: username,
            profilePic: profilePic,
            phoneNumber: phoneNumber,
            photoUrl: statusImageUrls,
            createdAt: DateTime.now(),
            statusId: statusId,
            whoCanSee: uidWhoCanSee,
            photoTimestamps: photoTimestamps
        );

        print('💾 Saving to Firestore...');
        print('📋 Status data: ${status.toMap()}');

        await firestore.collection('status').doc(statusId).set(status.toMap());

        print('✅✅✅ Status SAVED to Firestore!');
        return;

      }

    } catch (e) {
      print('❌❌❌ ERROR in uploadStatus: $e');
      showSnackBar(context: context, content: e.toString());
      rethrow;
    }
  }

  Future<List<Status>> getStatus(BuildContext context) async {
    List<Status> statusData = [];

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return statusData;

      debugPrint('🔹 Current user UID: ${currentUser.uid}');

      // 🔹 Fetch statuses where current user is in whoCanSee array
      final snapshot = await FirebaseFirestore.instance
          .collection('status')
          .where('whoCanSee', arrayContains: currentUser.uid)
          .where('createdAt',
          isGreaterThan: Timestamp.fromDate(
              DateTime.now().subtract(const Duration(hours: 24))))
          .orderBy('createdAt', descending: true)
          .get();

      debugPrint('🔹 Fetched ${snapshot.docs.length} documents');

      for (var doc in snapshot.docs) {
        try {
          Status status = Status.fromMap(doc.data());

          // ✅ NEW: Filter expired images
          List<String> validUrls = [];
          List<DateTime> validTimestamps = [];
          DateTime now = DateTime.now();

          for (int i = 0; i < status.photoUrl.length; i++) {
            DateTime imgTime = status.photoTimestamps[i];
            if (now.difference(imgTime).inHours < 24) {
              validUrls.add(status.photoUrl[i]);
              validTimestamps.add(imgTime);
            }
          }

          // If all images expired, delete the entire status document
          if (validUrls.isEmpty) {
            await firestore.collection('status').doc(doc.id).delete();
            debugPrint('🗑️ Deleted expired status for: ${status.username}');
            continue; // Skip adding to statusData
          }

          // If some images expired, update the document
          if (validUrls.length < status.photoUrl.length) {
            await firestore.collection('status').doc(doc.id).update({
              'photoUrl': validUrls,
              'photoTimestamps': validTimestamps,
            });
            debugPrint('🧹 Cleaned ${status.photoUrl.length - validUrls.length} expired images for: ${status.username}');
          }

          // Create updated status with only valid images
          Status validStatus = Status(
            uid: status.uid,
            username: status.username,
            profilePic: status.profilePic,
            phoneNumber: status.phoneNumber,
            photoUrl: validUrls,
            createdAt: status.createdAt,
            statusId: status.statusId,
            whoCanSee: status.whoCanSee,
            photoTimestamps: validTimestamps,
          );

          statusData.add(validStatus);
          debugPrint('✅ Added status from: ${status.username} with ${validUrls.length} valid images');

        } catch (e) {
          debugPrint('❌ Error parsing status: $e');
        }
      }

      // 🔹 Keep only latest status per user
      final Map<String, Status> latestStatusPerUser = {};
      for (var s in statusData) {
        if (!latestStatusPerUser.containsKey(s.uid) ||
            s.createdAt.isAfter(latestStatusPerUser[s.uid]!.createdAt)) {
          latestStatusPerUser[s.uid] = s;
        }
      }

      statusData = latestStatusPerUser.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint('🔹 Final status list length: ${statusData.length}');
    } catch (e) {
      debugPrint('❌ Error in getStatus(): $e');
      showSnackBar(context: context, content: e.toString());
    }

    return statusData;
  }

  Future<void> debugFirestore() async {
    print('🔍 === DEBUG FIRESTORE ===');

    final currentUser = auth.currentUser!;
    print('👤 Current user: ${currentUser.uid}');

    // Check all status documents
    final allStatus = await firestore.collection('status').get();
    print('📊 Total status documents: ${allStatus.docs.length}');

    for (var doc in allStatus.docs) {
      print('---');
      print('Status ID: ${doc.id}');
      print('UID: ${doc.data()['uid']}');
      print('Username: ${doc.data()['username']}');
      print('whoCanSee: ${doc.data()['whoCanSee']}');
      print('createdAt: ${doc.data()['createdAt']}');
      print('photoUrl count: ${(doc.data()['photoUrl'] as List).length}');
    }

    // Check if createdAt is within 24 hours
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    print('⏰ Cutoff time: $cutoff');

    print('🔍 === END DEBUG ===');
  }


}