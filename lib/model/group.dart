import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String senderId;
  final String name;
  final String groupId;
  final String lastMessage;
  final String groupPic;
  final List<String> membersUid;
  final DateTime timeSent;

  Group(
      this.senderId,
      this.name,
      this.groupId,
      this.lastMessage,
      this.groupPic,
      this.membersUid,
      this.timeSent,
      );

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'name': name,
      'groupId': groupId,
      'lastMessage': lastMessage,
      'groupPic': groupPic,
      'membersUid': membersUid,
      'timeSent': timeSent,
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      map['senderId'] ?? '',
      map['name'] ?? '',
      map['groupId'] ?? '',
      map['lastMessage'] ?? '',
      map['groupPic'] ?? '',
      List<String>.from(map['membersUid'] ?? []),
      (map['timeSent'] is Timestamp)
          ? (map['timeSent'] as Timestamp).toDate()
          : (map['timeSent'] is int)
          ? DateTime.fromMillisecondsSinceEpoch(map['timeSent'])
          : DateTime.now(),
    );
  }
}