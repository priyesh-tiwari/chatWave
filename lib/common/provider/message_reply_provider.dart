import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../enums/message_enum.dart';

class MessageReply{
  final String message;
  final bool isMe;
  final MessageEnum messageEnum;

  MessageReply(this.messageEnum , this.message , this.isMe);
}

final messageReplyProvider=StateProvider<MessageReply?>((ref)=>null);