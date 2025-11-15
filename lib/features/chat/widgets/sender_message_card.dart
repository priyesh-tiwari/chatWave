import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ✅ ADD THIS
import 'package:swipe_to/swipe_to.dart';
import 'package:whatsapp_ui/features/chat/widgets/display_text_images_file.dart';

import '../../../common/enums/message_enum.dart';
import '../controller/chat_controller.dart'; // ✅ ADD THIS

class SenderMessageCard extends ConsumerWidget {
  // ✅ CHANGE TO ConsumerWidget
  const SenderMessageCard(
      {Key? key,
      required this.message,
      required this.date,
      required this.type,
      required this.onRightSwipe,
      required this.repliedText,
      required this.username,
      required this.repliedMessageType,
      required this.messageId,
      required this.senderId,
      required this.receiverUserId,
      required this.isGroup})
      : super(key: key);
  final String message;
  final String date;
  final MessageEnum type;
  final VoidCallback onRightSwipe;
  final String repliedText;
  final String username;
  final MessageEnum repliedMessageType;
  final String messageId;
  final String senderId;
  final String receiverUserId;
  final bool isGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ ADD WidgetRef ref
    final isReplying = repliedText.isNotEmpty;
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    return GestureDetector(
      onLongPress: () {
        if (currentUserId == senderId) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Message'),
              content:
                  const Text('Are you sure you want to delete this message?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);

                    // ✅ ADD DEBUG PRINTS
                    print('🔍 SenderMessageCard - Delete button pressed');
                    print('   messageId: $messageId');
                    print('   receiverUserId: $receiverUserId');
                    print('   isGroup: $isGroup');

                    // ✅ ADD DELETE CALL
                    ref.read(chatControllerProvider).deleteMessage(
                          context: context,
                          messageId: messageId,
                          receiverUserId: receiverUserId,
                          isGroup: isGroup,
                        );
                  },
                  child:
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        }
      },
      child: SwipeTo(
        onRightSwipe: (_) => onRightSwipe(),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width - 60,
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2A34),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: type == MessageEnum.text
                        ? const EdgeInsets.only(
                            left: 14,
                            right: 40,
                            top: 8,
                            bottom: 22,
                          )
                        : const EdgeInsets.only(
                            left: 8,
                            right: 8,
                            top: 8,
                            bottom: 28,
                          ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isReplying) ...[
                          Text(
                            username,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF00BFA5),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF121B22),
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(10)),
                                border: Border.all(
                                  color:
                                      const Color(0xFF00BFA5).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: DisplayTextImagesFile(
                                  message: repliedText,
                                  type: repliedMessageType)),
                          const SizedBox(
                            height: 6,
                          )
                        ],
                        DisplayTextImagesFile(message: message, type: type),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 12,
                    child: Text(
                      date,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
