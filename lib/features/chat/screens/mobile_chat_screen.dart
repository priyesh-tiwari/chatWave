import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/features/call/controller/call_controller.dart';
import 'package:whatsapp_ui/features/call/screens/call_pickup_screen.dart';
import 'package:whatsapp_ui/features/chat/widgets/chat_list.dart';

import '../../../model/user_model.dart';
import '../../auth/controller/auth_controller.dart';
import '../widgets/bottom_chat_field.dart';
import 'chat_profile_screen.dart';

class MobileChatScreen extends ConsumerWidget {
  final String name;
  final String uid;
  final bool isGroup;
  final String profilePic;

  const MobileChatScreen({
    Key? key,
    required this.name,
    required this.uid,
    required this.isGroup,
    required this.profilePic,
  }) : super(key: key);

  static const String routeName = '/mobile-chat-screen';

  void makeVideoCall(WidgetRef ref, BuildContext context) {
    ref.read(callControllerProvider).makeCall(
          context,
          name,
          uid,
          profilePic,
          isGroup,
          isVideoCall: true,
        );
  }

  void makeAudioCall(WidgetRef ref, BuildContext context) {
    ref.read(callControllerProvider).makeCall(
          context,
          name,
          uid,
          profilePic,
          isGroup,
          isVideoCall: false,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CallPickupScreen(
      scaffold: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.black.withOpacity(0.3),
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.transparent),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),

          // ✅ Make title tappable to navigate to profile screen
          title: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatProfileScreen(
                    uid: uid,
                  ),
                ),
              );
            },
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withOpacity(0.7),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(profilePic),
                    radius: 20,
                    backgroundColor: Colors.grey[900],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: isGroup
                      ? Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : StreamBuilder<UserModel>(
                          stream: ref
                              .read(authControllerProvider)
                              .userDataById(uid),
                          builder: (context, snapshot) {
                            final user = snapshot.data;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  snapshot.connectionState ==
                                          ConnectionState.waiting
                                      ? 'Loading...'
                                      : (user?.isOnline ?? false)
                                          ? 'Online'
                                          : 'Offline',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: (user?.isOnline ?? false)
                                        ? const Color(0xFF00E5FF)
                                        : Colors.grey[400],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          actions: [
            IconButton(
              onPressed: () => makeVideoCall(ref, context),
              icon: const Icon(Icons.videocam_rounded, color: Colors.white),
            ),
            IconButton(
              onPressed: () => makeAudioCall(ref, context),
              icon: const Icon(Icons.call_rounded, color: Colors.white),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0F2027),
                Color(0xFF203A43),
                Color(0xFF2C5364),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ChatList(receiverUserId: uid, isGroup: isGroup),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.blueGrey.withOpacity(0.3),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 6,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: BottomChatField(
                    receiverUserId: uid,
                    isGroup: isGroup,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
