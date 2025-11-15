import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/features/auth/controller/auth_controller.dart';

import 'meeting_model.dart';
import 'meeting_repository.dart';

final meetingControllerProvider = Provider((ref) {
  final meetingRepository = ref.read(meetingRepositoryProvider);
  return MeetingController(
    auth: FirebaseAuth.instance,
    meetingRepository: meetingRepository,
    ref: ref,
  );
});

class MeetingController {
  final MeetingRepository meetingRepository;
  final ProviderRef ref;
  final FirebaseAuth auth;

  MeetingController({
    required this.meetingRepository,
    required this.ref,
    required this.auth,
  });

  // Get user meetings stream
  Stream<List<Meeting>> get userMeetings =>
      meetingRepository.getUserMeetings();

  // Get meeting history stream
  Stream<List<Meeting>> get meetingHistory =>
      meetingRepository.getMeetingHistory();

  // Create a new meeting
  Future<Meeting?> createMeeting({
    required BuildContext context,
    required String title,
    required bool isVideoMeeting,
    String? description,
  }) async {
    try {
      final userData = await ref.read(userDataAuthProvider.future);
      if (userData != null) {
        Meeting meeting = await meetingRepository.createMeeting(
          title: title,
          creatorName: userData.name,
          creatorPic: userData.profilePic,
          isVideoMeeting: isVideoMeeting,
          description: description,
        );
        return meeting;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating meeting: $e')),
      );
    }
    return null;
  }

  // Get meeting by ID
  Future<Meeting?> getMeetingById(String meetingId) async {
    try {
      return await meetingRepository.getMeetingById(meetingId);
    } catch (e) {
      return null;
    }
  }

  // Join meeting
  Future<void> joinMeeting({
    required BuildContext context,
    required String meetingId,
  }) async {
    try {
      final userData = await ref.read(userDataAuthProvider.future);
      if (userData != null) {
        await meetingRepository.joinMeeting(
          meetingId,
          auth.currentUser!.uid,
          userData.name,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining meeting: $e')),
      );
    }
  }

  // Leave meeting
  Future<void> leaveMeeting({
    required String meetingId,
  }) async {
    try {
      await meetingRepository.leaveMeeting(
        meetingId,
        auth.currentUser!.uid,
      );
    } catch (e) {
      debugPrint('Error leaving meeting: $e');
    }
  }

  // End meeting
  Future<void> endMeeting({
    required String meetingId,
    required BuildContext context,
  }) async {
    try {
      await meetingRepository.endMeeting(meetingId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error ending meeting: $e')),
      );
    }
  }

  // Get meeting stream
  Stream<Meeting?> getMeetingStream(String meetingId) =>
      meetingRepository.getMeetingStream(meetingId);
}