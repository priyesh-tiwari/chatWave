import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:whatsapp_ui/model/chatContact.dart';
import 'package:whatsapp_ui/showSnackbar.dart';

import '../../../cloudinary.dart';
import '../../../common/enums/message_enum.dart';
import '../../../common/provider/message_reply_provider.dart';
import '../../../model/group.dart';
import '../../../model/message.dart';
import '../../../model/user_model.dart';

final chatRepositoryProvider = Provider((ref) => ChatRepository(
    firestore: FirebaseFirestore.instance, auth: FirebaseAuth.instance));

class ChatRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  ChatRepository({required this.firestore, required this.auth});

  Stream<List<ChatContact>> getChatContact() {
    return firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .snapshots()
        .asyncMap((event) async {
      List<ChatContact> contacts = [];

      for (var document in event.docs) {
        // ✅ USE DOCUMENT ID as the contact ID
        String contactId = document.id;

        // Skip if document ID is your own UID
        if (contactId == auth.currentUser!.uid) {
          continue;
        }

        // Get chat data
        var chatData = document.data();

        // Fetch user data using the document ID (which is the other person's UID)
        var userData = await firestore.collection('users').doc(contactId).get();

        if (!userData.exists) {
          continue;
        }

        var user = UserModel.fromMap(userData.data()!);

        // Create ChatContact using the document ID as contactId
        contacts.add(
          ChatContact(
            name: user.name,
            profilePic: user.profilePic,
            contactId: contactId, // ✅ Document ID = other person's UID
            timeSent: DateTime.fromMillisecondsSinceEpoch(chatData['timeSent']),
            lastMessage: chatData['lastMessage'] ?? '',
          ),
        );
      }

      return contacts;
    });
  }

  Stream<List<Group>> getChatGroups() {
    return firestore.collection('groups').snapshots().map((event) {
      List<Group> groups = [];

      for (var document in event.docs) {
        var group = Group.fromMap(document.data());

        if (group.membersUid.contains(auth.currentUser!.uid)) {
          groups.add(group);
        }
      }

      return groups;
    });
  }

  Stream<List<Message>> getChatStream(String receiverUserId) {
    print('🔍 getChatStream called');
    print('🔍 Current user: ${auth.currentUser!.uid}');
    print('🔍 Receiver user: $receiverUserId');
    print(
        '🔍 Path: users/${auth.currentUser!.uid}/chats/$receiverUserId/messages');

    return firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .doc(receiverUserId)
        .collection('messages')
        .orderBy('timeSent')
        .snapshots()
        .map((event) {
      print('🔍 Snapshot received: ${event.docs.length} messages');
      List<Message> messages = [];
      for (var document in event.docs) {
        print('📨 Message: ${document.data()}');
        messages.add(Message.fromMap(document.data()));
      }
      return messages;
    });
  }

// For group chats
  Stream<List<Message>> groupChatStream(String groupId) {
    return firestore
        .collection('groups')
        .doc(groupId)
        .collection('chats')
        .orderBy('timeSent')
        .snapshots()
        .map((event) {
      List<Message> messages = [];
      for (var document in event.docs) {
        messages.add(Message.fromMap(document.data()));
      }
      return messages;
    });
  }

  Future<void> _saveDataToContactSubcollection(
      UserModel senderUserData,
      UserModel? receiverUserData,
      String text,
      DateTime timeSent,
      String receiverUserId,
      bool isGroup) async {
    print('🔍 Saving chat contact');
    print('🔍 Sender UID: ${auth.currentUser!.uid}');
    print('🔍 Receiver UID: $receiverUserId');
    print('🔍 Is Group: $isGroup');

    if (isGroup) {
      await firestore.collection('groups').doc(receiverUserId).update({
        'lastMessage': text,
        'timeSent': DateTime.now().millisecondsSinceEpoch
      });
    } else {
      // For receiver's chat list
      print(
          '💾 Saving to: users/$receiverUserId/chats/${auth.currentUser!.uid}');
      print(
          '   Storing sender data: ${senderUserData.name} (${senderUserData.uid})');

      await firestore
          .collection('users')
          .doc(receiverUserId)
          .collection('chats')
          .doc(auth.currentUser!.uid)
          .set({
        'name': senderUserData.name,
        'profilePic': senderUserData.profilePic,
        'uid': senderUserData.uid, // ✅ Changed from contactId to uid
        'phoneNumber': senderUserData.phoneNumber, // ✅ Add phone number
        'timeSent': timeSent.millisecondsSinceEpoch,
        'lastMessage': text,
        'isOnline': false, // ✅ Add this field
      });

      // For sender's chat list
      print(
          '💾 Saving to: users/${auth.currentUser!.uid}/chats/$receiverUserId');
      print(
          '   Storing receiver data: ${receiverUserData!.name} (${receiverUserData.uid})');

      await firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('chats')
          .doc(receiverUserId)
          .set({
        'name': receiverUserData.name,
        'profilePic': receiverUserData.profilePic,
        'uid': receiverUserData.uid, // ✅ Changed from contactId to uid
        'phoneNumber': receiverUserData.phoneNumber, // ✅ Add phone number
        'timeSent': timeSent.millisecondsSinceEpoch,
        'lastMessage': text,
        'isOnline': false, // ✅ Add this field
      });

      print('✅ Chat contact saved successfully');
    }
  }

  Future<void> _saveMessageToMessageSubcollection(
      {required String receiverUserId,
      required String text,
      required DateTime timeSent,
      required String messageId,
      required String username,
      required MessageEnum messageType,
      required MessageReply? messageReply,
      required String senderUserName,
      required String? receiverUserName,
      required bool isGroup}) async {
    final message = Message(
        auth.currentUser!.uid,
        receiverUserId,
        text,
        messageType,
        timeSent,
        messageId,
        false,
        messageReply == null ? '' : messageReply.message,
        messageReply == null
            ? ''
            : messageReply.isMe
                ? senderUserName
                : receiverUserName ?? '',
        messageReply == null ? MessageEnum.text : messageReply.messageEnum);

    if (isGroup) {
      await firestore
          .collection('groups')
          .doc(receiverUserId)
          .collection('chats')
          .doc(messageId)
          .set(message.toMap());
    } else {
      // ✅ ADD DEBUG LOGS
      print('💾 Saving message to sender path:');
      print(
          '   users/${auth.currentUser!.uid}/chats/$receiverUserId/messages/$messageId');

      await firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('chats')
          .doc(receiverUserId)
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());

      print('💾 Saving message to receiver path:');
      print(
          '   users/$receiverUserId/chats/${auth.currentUser!.uid}/messages/$messageId');

      await firestore
          .collection('users')
          .doc(receiverUserId)
          .collection('chats')
          .doc(auth.currentUser!.uid)
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());

      print('✅ Messages saved successfully');
    }
  }

  void sendTextMessage(
      {required BuildContext context,
      required String text,
      required String receiverUserId,
      required UserModel senderUser,
      required MessageReply? messageReply,
      required bool isGroup}) async {
    try {
      if (!isGroup && receiverUserId == auth.currentUser!.uid) {
        showSnackBar(context: context, content: 'You cannot message yourself');
        return;
      }
      var timeSent = DateTime.now();
      UserModel? receiverUserData;

      if (!isGroup) {
        var userDataMap =
            await firestore.collection('users').doc(receiverUserId).get();
        receiverUserData = UserModel.fromMap(userDataMap.data()!);
      }

      var messageId = const Uuid().v1();

      await _saveDataToContactSubcollection(senderUser, receiverUserData, text,
          timeSent, receiverUserId, isGroup);

      await _saveMessageToMessageSubcollection(
          receiverUserId: receiverUserId,
          text: text,
          timeSent: timeSent,
          messageId: messageId,
          username: senderUser.name,
          messageType: MessageEnum.text,
          messageReply: messageReply,
          receiverUserName: receiverUserData?.name,
          senderUserName: senderUser.name,
          isGroup: isGroup);
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  Future<void> sendFileMessage(
      {required BuildContext context,
      required File file,
      required String receiverUserId,
      required UserModel senderUserData,
      required ProviderRef ref,
      required MessageEnum messageEnum,
      required MessageReply? messageReply,
      required bool isGroup}) async {
    try {
      var timeSent = DateTime.now();
      var messageId = const Uuid().v1();
      String imageURL = await uploadFileToCloudinary(
        file,
        messageEnum == MessageEnum.video
            ? 'video'
            : messageEnum == MessageEnum.audio
                ? 'audio'
                : 'image',
      );

      UserModel? receiverUserData;
      if (!isGroup) {
        var userDataMap =
            await firestore.collection('users').doc(receiverUserId).get();
        receiverUserData = UserModel.fromMap(userDataMap.data()!);
      }

      String contactMsg;
      switch (messageEnum) {
        case MessageEnum.image:
          contactMsg = 'Photo';
          break;

        case MessageEnum.video:
          contactMsg = 'Video';
          break;

        case MessageEnum.audio:
          contactMsg = 'Audio';
          break;

        case MessageEnum.gif:
          contactMsg = 'GIF';
          break;

        default:
          contactMsg = 'GIF';
      }

      await _saveDataToContactSubcollection(senderUserData, receiverUserData,
          contactMsg, timeSent, receiverUserId, isGroup);

      await _saveMessageToMessageSubcollection(
          receiverUserId: receiverUserId,
          text: imageURL,
          timeSent: timeSent,
          username: senderUserData.name,
          messageId: messageId,
          messageType: messageEnum,
          messageReply: messageReply,
          senderUserName: senderUserData.name,
          receiverUserName: receiverUserData?.name,
          isGroup: isGroup);
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  void sendGIFMessage(
      {required BuildContext context,
      required String gifUrl,
      required String receiverUserId,
      required UserModel senderUser,
      required MessageReply? messageReply,
      required bool isGroup}) async {
    try {
      var timeSent = DateTime.now();
      UserModel? receiverUserData;

      var messageId = const Uuid().v1();

      if (!isGroup) {
        var userDataMap =
            await firestore.collection('users').doc(receiverUserId).get();
        receiverUserData = UserModel.fromMap(userDataMap.data()!);
      }

      await _saveDataToContactSubcollection(senderUser, receiverUserData, 'GIF',
          timeSent, receiverUserId, isGroup);

      await _saveMessageToMessageSubcollection(
          receiverUserId: receiverUserId,
          text: gifUrl,
          timeSent: timeSent,
          messageId: messageId,
          username: senderUser.name,
          messageType: MessageEnum.gif,
          messageReply: messageReply,
          senderUserName: senderUser.name,
          receiverUserName: receiverUserData?.name,
          isGroup: isGroup);
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  void setChatMessageSeen(
      BuildContext context, String receiverUserId, String messageId) async {
    try {
      await firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('chats')
          .doc(receiverUserId)
          .collection('messages')
          .doc(messageId)
          .update({'isSeen': true});

      await firestore
          .collection('users')
          .doc(receiverUserId)
          .collection('chats')
          .doc(auth.currentUser!.uid)
          .collection('messages')
          .doc(messageId)
          .update({'isSeen': true});
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  Future<void> deleteMessage({
    required BuildContext context,
    required String messageId,
    required String receiverUserId,
    required bool isGroup,
  }) async {
    try {
      if (messageId.isEmpty || receiverUserId.isEmpty) {
        showSnackBar(
            context: context, content: 'Cannot delete: Invalid message data');
        return;
      }

      if (isGroup) {
        await firestore
            .collection('groups')
            .doc(receiverUserId)
            .collection('chats')
            .doc(messageId)
            .delete();
      } else {
        await firestore
            .collection('users')
            .doc(auth.currentUser!.uid)
            .collection('chats')
            .doc(receiverUserId)
            .collection('messages')
            .doc(messageId)
            .delete();

        await firestore
            .collection('users')
            .doc(receiverUserId)
            .collection('chats')
            .doc(auth.currentUser!.uid)
            .collection('messages')
            .doc(messageId)
            .delete();
      }
    } catch (e) {
      try {
        showSnackBar(context: context, content: 'Failed to delete message');
      } catch (_) {
        // Context might be unavailable if widget is disposed
      }
    }
  }
}
