import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:whatsapp_ui/common/provider/message_reply_provider.dart';
import 'package:whatsapp_ui/features/chat/controller/chat_controller.dart';
import 'package:whatsapp_ui/features/chat/widgets/my_message_card.dart';
import 'package:whatsapp_ui/features/chat/widgets/sender_message_card.dart';

import '../../../common/enums/message_enum.dart';
import '../../../model/message.dart';

class ChatList extends ConsumerStatefulWidget {
  final String receiverUserId;
  final bool isGroup;
  const ChatList(
      {Key? key, required this.receiverUserId, required this.isGroup})
      : super(key: key);

  @override
  ConsumerState createState() => _ChatListState();
}

class _ChatListState extends ConsumerState<ChatList> {
  final ScrollController messageController = ScrollController();
  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  void onMessageSwipe(String message, bool isMe, MessageEnum messageEnum) {
    ref
        .read(messageReplyProvider.state)
        .update((state) => MessageReply(messageEnum, message, isMe));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF121B22),
            Color(0xFF0A1014),
          ],
        ),
      ),
      child: StreamBuilder<List<Message>>(
          stream: widget.isGroup
              ? ref
                  .watch(chatControllerProvider)
                  .groupChatStream(widget.receiverUserId)
              : ref
                  .watch(chatControllerProvider)
                  .chatStream(widget.receiverUserId),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Colors.grey[600],
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No messages yet',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (messageController.hasClients) {
                messageController
                    .jumpTo(messageController.position.maxScrollExtent);
              }
            });
            return ListView.builder(
              controller: messageController,
              itemCount: snapshot.data!.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final messageData = snapshot.data![index];
                var timeSent = DateFormat.Hm().format(messageData.timeSent);

                if (messageData.isSeen &&
                    messageData.receiverId ==
                        FirebaseAuth.instance.currentUser!.uid) {
                  ref.read(chatControllerProvider).setChatMessageSeen(
                      context, widget.receiverUserId, messageData.messageId);
                }
                if (messageData.senderId ==
                    FirebaseAuth.instance.currentUser!.uid) {
                  return MyMessageCard(
                    message: messageData.text,
                    date: timeSent,
                    type: messageData.type,
                    repliedText: messageData.repliedMessage,
                    username: messageData.repliedTo,
                    repliedMessageType: messageData.repliedMessageType,
                    onLeftSwipe: () => onMessageSwipe(
                        messageData.text, true, messageData.type),
                    isSeen: messageData.isSeen,
                    messageId: messageData.messageId,
                    receiverUserId: widget.isGroup
                        ? widget.receiverUserId
                        : messageData.receiverId,
                    isGroup: widget.isGroup,
                  );
                }
                return SenderMessageCard(
                  message: messageData.text,
                  date: timeSent,
                  type: messageData.type,
                  onRightSwipe: () =>
                      onMessageSwipe(messageData.text, false, messageData.type),
                  repliedText: messageData.repliedMessage,
                  username: messageData.repliedTo,
                  repliedMessageType: messageData.repliedMessageType,
                  senderId: messageData.senderId,
                  messageId: messageData.messageId,
                  receiverUserId: widget.isGroup
                      ? widget.receiverUserId
                      : messageData.receiverId,
                  isGroup: widget.isGroup,
                );
              },
            );
          }),
    );
  }
}
