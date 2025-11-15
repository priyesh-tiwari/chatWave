import 'package:cloud_firestore/cloud_firestore.dart';

class Status {
  final String uid;
  final String username;
  final String phoneNumber;
  final List<String> photoUrl;
  final DateTime createdAt;
  final List<DateTime> photoTimestamps;
  final String profilePic;
  final String statusId;
  final List<String> whoCanSee;

  Status({
    required this.uid,
    required this.username,
    required this.profilePic,
    required this.phoneNumber,
    required this.photoUrl,
    required this.createdAt,
    required this.photoTimestamps,
    required this.statusId,
    required this.whoCanSee,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
      'photoTimestamps': photoTimestamps,
      'profilePic': profilePic,
      'statusId': statusId,
      'whoCanSee': whoCanSee,
    };
  }

  factory Status.fromMap(Map<String, dynamic> map) {
    return Status(
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      photoUrl: List<String>.from(map['photoUrl'] ?? []),
      createdAt: map['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : (map['createdAt'] as Timestamp).toDate(),
      photoTimestamps: (map['photoTimestamps'] as List?)
          ?.map((t) => t is int
          ? DateTime.fromMillisecondsSinceEpoch(t)
          : (t as Timestamp).toDate())
          .toList() ?? [],
      profilePic: map['profilePic'] ?? '',
      statusId: map['statusId'] ?? '',
      whoCanSee: List<String>.from(map['whoCanSee'] ?? []),
    );
  }
}
