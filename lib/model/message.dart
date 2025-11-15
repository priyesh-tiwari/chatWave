import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/enums/message_enum.dart';

class Message {
  final String senderId;
  final String receiverId;
  final String text;
  final MessageEnum type;
  final DateTime timeSent;
  final String messageId;
  final bool isSeen;
  final String repliedMessage;
  final String repliedTo;
  final MessageEnum repliedMessageType;

  Message(
      this.senderId,
      this.receiverId,
      this.text,
      this.type,
      this.timeSent,
      this.messageId,
      this.isSeen,
      this.repliedMessage,
      this.repliedTo,
      this.repliedMessageType,
      );

  // Convert Message object to Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'type': type.type, // store enum as string
      'timeSent': timeSent,
      'messageId': messageId,
      'isSeen': isSeen,
      'repliedMessage': repliedMessage,
      'repliedTo': repliedTo,
      'repliedMessageType': repliedMessageType.type,
    };
  }

  // Create Message object from Map (from Firestore)
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      map['senderId'] ?? '',
      map['receiverId'] ?? '',
      map['text'] ?? '',
      MessageEnum.values.firstWhere(
            (e) => e.type == map['type'],
        orElse: () => MessageEnum.text,
      ),
      map['timeSent'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['timeSent'])
          : (map['timeSent'] as Timestamp).toDate(),
      map['messageId'] ?? '',
      map['isSeen'] ?? false,
      map['repliedMessage'] ?? '',
      map['repliedTo'] ?? '',
      MessageEnum.values.firstWhere(
            (e) => e.type == map['repliedMessageType'],
        orElse: () => MessageEnum.text,
      ),
    );
  }
}
