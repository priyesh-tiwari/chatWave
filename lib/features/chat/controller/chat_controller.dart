import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/common/enums/message_enum.dart';
import 'package:whatsapp_ui/common/provider/message_reply_provider.dart';
import 'package:whatsapp_ui/features/auth/controller/auth_controller.dart';
import 'package:whatsapp_ui/features/chat/repository/chat_repository.dart';
import 'package:whatsapp_ui/model/group.dart';
import 'package:whatsapp_ui/model/message.dart';

import '../../../common/utils/utils.dart';
import '../../../model/chatContact.dart';

final chatControllerProvider = Provider((ref) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return ChatController(chatRepository: chatRepository, ref: ref);
});

class ChatController {
  final ChatRepository chatRepository;
  final ProviderRef ref;
  ChatController({required this.chatRepository, required this.ref});

  Stream<List<ChatContact>> chatContact() {
    return chatRepository.getChatContact();
  }

  Stream<List<Group>> chatGroups() {
    return chatRepository.getChatGroups();
  }

  Stream<List<Message>> chatStream(String receiverUserId) {
    return chatRepository.getChatStream(receiverUserId);
  }

  Stream<List<Message>> groupChatStream(String groupId) {
    return chatRepository.groupChatStream(groupId);
  }

  void sendTextMessage(
      BuildContext context, String text, String receiverUserId, bool isGroup) {
    final messageReply = ref.read(messageReplyProvider);
    final userDataAsync = ref.read(userDataStreamProvider);

    userDataAsync.when(
      data: (userData) {
        if (userData == null) {
          showSnackBar(context: context, content: 'User data not available');
          return;
        }
        chatRepository.sendTextMessage(
            context: context,
            text: text,
            receiverUserId: receiverUserId,
            senderUser: userData,
            messageReply: messageReply,
            isGroup: isGroup);
      },
      loading: () {
        showSnackBar(context: context, content: 'Loading...');
      },
      error: (err, stack) {
        showSnackBar(context: context, content: 'Error: $err');
      },
    );

    ref.read(messageReplyProvider.notifier).update((state) => null);
  }

  Future<void> sendFileMessage(
    BuildContext context,
    File file,
    String receiverUserId,
    MessageEnum messageEnum,
    bool isGroup,
  ) async {
    final messageReply = ref.read(messageReplyProvider);
    final userDataAsync =
        ref.read(userDataStreamProvider); // use stream provider

    userDataAsync.when(
      data: (userData) async {
        if (userData == null) {
          showSnackBar(context: context, content: 'User data not available');
          return;
        }

        await chatRepository.sendFileMessage(
          context: context,
          file: file,
          receiverUserId: receiverUserId,
          senderUserData: userData,
          messageEnum: messageEnum,
          ref: ref,
          messageReply: messageReply,
          isGroup: isGroup,
        );
      },
      loading: () {
        showSnackBar(context: context, content: 'Loading user data...');
      },
      error: (error, stack) {
        showSnackBar(context: context, content: 'Error: ${error.toString()}');
      },
    );

    // Reset reply after sending
    ref.read(messageReplyProvider.notifier).update((state) => null);
  }

  void sendGIFMessage(
    BuildContext context,
    String gifUrl,
    String receiverUserId,
    bool isGroup,
  ) {
    final messageReply = ref.read(messageReplyProvider);
    final userDataAsync = ref.read(userDataStreamProvider);

    int gifUrlPartIndex = gifUrl.lastIndexOf('-') + 1;
    String gifUrlPart = gifUrl.substring(gifUrlPartIndex);
    String newgifUrl = 'https://i.giphy.com/media/$gifUrlPart/200.gif';

    userDataAsync.when(
      data: (userData) {
        if (userData == null) {
          showSnackBar(context: context, content: 'User data not available');
          return;
        }
        chatRepository.sendGIFMessage(
          context: context,
          gifUrl: newgifUrl,
          receiverUserId: receiverUserId,
          senderUser: userData,
          messageReply: messageReply,
          isGroup: isGroup,
        );
      },
      loading: () {
        showSnackBar(context: context, content: 'Loading user data...');
      },
      error: (error, stack) {
        showSnackBar(context: context, content: 'Error: ${error.toString()}');
      },
    );

    ref.read(messageReplyProvider.notifier).update((state) => null);
  }

  void setChatMessageSeen(
      BuildContext context, String receiverUserId, String messageId) {
    chatRepository.setChatMessageSeen(context, receiverUserId, messageId);
  }

  void deleteMessage({
    required BuildContext context,
    required String messageId,
    required String receiverUserId,
    required bool isGroup,
  }) {
    chatRepository.deleteMessage(
      messageId: messageId,
      receiverUserId: receiverUserId,
      isGroup: isGroup,
      context: context,
    );
  }
}
