import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../common/utils/utils.dart';
import 'meeting_model.dart';

final meetingRepositoryProvider = Provider(
      (ref) => MeetingRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  ),
);

class MeetingRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  MeetingRepository({
    required this.firestore,
    required this.auth,
  });

  // Create a new meeting
  Future<Meeting> createMeeting({
    required String title,
    required String creatorName,
    required String creatorPic,
    required bool isVideoMeeting,
    String? description,
  }) async {
    try {
      String meetingId = const Uuid().v1();
      String creatorId = auth.currentUser!.uid;

      Meeting meeting = Meeting(
        meetingId: meetingId,
        creatorId: creatorId,
        creatorName: creatorName,
        creatorPic: creatorPic,
        title: title,
        createdAt: DateTime.now(),
        participantIds: [creatorId],
        participantNames: [creatorName],
        isActive: true,
        isVideoMeeting: isVideoMeeting,
        description: description,
        duration: 0,
      );

      await firestore.collection('meetings').doc(meetingId).set(meeting.toMap());
      return meeting;
    } catch (e) {
      throw Exception('Error creating meeting: $e');
    }
  }

  // Get meeting by ID
  Future<Meeting?> getMeetingById(String meetingId) async {
    try {
      DocumentSnapshot doc =
      await firestore.collection('meetings').doc(meetingId).get();
      if (doc.exists) {
        return Meeting.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting meeting: $e');
    }
  }

  // Join meeting
  Future<void> joinMeeting(
      String meetingId,
      String userId,
      String userName,
      ) async {
    try {
      Meeting? meeting = await getMeetingById(meetingId);
      if (meeting != null && meeting.isActive) {
        List<String> participantIds = [...meeting.participantIds];
        List<String> participantNames = [...meeting.participantNames];

        if (!participantIds.contains(userId)) {
          participantIds.add(userId);
          participantNames.add(userName);
        }

        await firestore.collection('meetings').doc(meetingId).update({
          'participantIds': participantIds,
          'participantNames': participantNames,
        });
      }
    } catch (e) {
      throw Exception('Error joining meeting: $e');
    }
  }

  // Leave meeting
  Future<void> leaveMeeting(String meetingId, String userId) async {
    try {
      Meeting? meeting = await getMeetingById(meetingId);
      if (meeting != null) {
        List<String> participantIds = [...meeting.participantIds];
        List<String> participantNames = [...meeting.participantNames];

        int index = participantIds.indexOf(userId);
        if (index != -1) {
          participantIds.removeAt(index);
          participantNames.removeAt(index);
        }

        if (participantIds.isEmpty) {
          // End meeting if no participants left
          await endMeeting(meetingId);
        } else {
          await firestore.collection('meetings').doc(meetingId).update({
            'participantIds': participantIds,
            'participantNames': participantNames,
          });
        }
      }
    } catch (e) {
      throw Exception('Error leaving meeting: $e');
    }
  }

  // End meeting
  Future<void> endMeeting(String meetingId) async {
    try {
      await firestore.collection('meetings').doc(meetingId).update({
        'isActive': false,
        'duration': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error ending meeting: $e');
    }
  }

  // Get all active meetings for a user
  Stream<List<Meeting>> getUserMeetings() {
    String userId = auth.currentUser!.uid;
    return firestore
        .collection('meetings')
        .where('creatorId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final meetings = snapshot.docs
          .map((doc) => Meeting.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      // Filter for active meetings in the app
      final activeMeetings = meetings.where((m) => m.isActive).toList();
      // Sort by createdAt descending
      activeMeetings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return activeMeetings;
    });
  }

  // Get all meetings history for a user
  Stream<List<Meeting>> getMeetingHistory() {
    String userId = auth.currentUser!.uid;
    return firestore
        .collection('meetings')
        .where('creatorId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final meetings = snapshot.docs
          .map((doc) => Meeting.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      // Sort by createdAt descending
      meetings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return meetings;
    });
  }

  // Get meeting participants stream
  Stream<Meeting?> getMeetingStream(String meetingId) {
    return firestore
        .collection('meetings')
        .doc(meetingId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return Meeting.fromMap(snapshot.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Update meeting duration
  Future<void> updateMeetingDuration(String meetingId, int duration) async {
    try {
      await firestore
          .collection('meetings')
          .doc(meetingId)
          .update({'duration': duration});
    } catch (e) {
      throw Exception('Error updating meeting duration: $e');
    }
  }

  // Delete meeting (admin only)
  Future<void> deleteMeeting(String meetingId) async {
    try {
      await firestore.collection('meetings').doc(meetingId).delete();
    } catch (e) {
      throw Exception('Error deleting meeting: $e');
    }
  }
}