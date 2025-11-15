import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swipe_to/swipe_to.dart';
import 'package:whatsapp_ui/features/chat/widgets/display_text_images_file.dart';

import '../../../common/enums/message_enum.dart';
import '../controller/chat_controller.dart';

class MyMessageCard extends ConsumerWidget {
  final String message;
  final String date;
  final MessageEnum type;
  final VoidCallback onLeftSwipe;
  final String repliedText;
  final String username;
  final MessageEnum repliedMessageType;
  final bool isSeen;
  final String messageId;
  final String receiverUserId; // ADD THIS
  final bool isGroup;

  const MyMessageCard(
      {Key? key,
      required this.message,
      required this.date,
      required this.type,
      required this.onLeftSwipe,
      required this.username,
      required this.repliedText,
      required this.repliedMessageType,
      required this.isSeen,
      required this.messageId,
      required this.isGroup,
      required this.receiverUserId})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReplying = repliedText.isNotEmpty;
    return GestureDetector(
      onLongPress: () {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('Delete message'),
                  content: const Text(
                      'Are you sure you want to delete this message?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ref.read(chatControllerProvider).deleteMessage(
                                context: context,
                                messageId: messageId,
                                receiverUserId: receiverUserId,
                                isGroup: isGroup,
                              );
                        },
                        child: const Text('Delete'))
                  ],
                ));
      },
      child: SwipeTo(
        onLeftSwipe: (_) => onLeftSwipe(),
        child: Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width - 60,
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF00BFA5),
                    Color(0xFF00A896),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00BFA5).withOpacity(0.2),
                    blurRadius: 8,
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
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.15),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(10)),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
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
                      )),
                  Positioned(
                    bottom: 4,
                    right: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isSeen ? Icons.done_all : Icons.done,
                          size: 16,
                          color: isSeen
                              ? Colors.white
                              : Colors.white.withOpacity(0.7),
                        ),
                      ],
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
