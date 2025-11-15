import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:whatsapp_ui/common/provider/message_reply_provider.dart';
import 'package:whatsapp_ui/common/utils/utils.dart';
import 'package:whatsapp_ui/features/chat/controller/chat_controller.dart';
import 'package:whatsapp_ui/features/chat/widgets/message_reply.dart';

import '../../../common/enums/message_enum.dart';

class BottomChatField extends ConsumerStatefulWidget {
  final String receiverUserId;
  final bool isGroup;
  const BottomChatField({
    Key? key,
    required this.receiverUserId,
    required this.isGroup,
  }) : super(key: key);

  @override
  ConsumerState<BottomChatField> createState() => _BottomChatFieldState();
}

class _BottomChatFieldState extends ConsumerState<BottomChatField> {
  bool isShowEmojiContainer = false;
  FocusNode focusNode = FocusNode();
  bool isShowSendButton = false;
  String? _audioPath;
  final TextEditingController _messageController = TextEditingController();

  FlutterSoundRecorder? _soundRecorder;
  bool isRecorderInit = false;
  bool isRecording = false;

  @override
  void initState() {
    super.initState();
    _soundRecorder = FlutterSoundRecorder();
    openAudio();
  }

  void openAudio() async {
    if (Platform.isAndroid) {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException('Mic permission not allowed');
      }
    }
    await _soundRecorder!.openRecorder();
    isRecorderInit = true;
  }

  void sendTextMessage() async {
    if (isShowSendButton) {
      ref.read(chatControllerProvider).sendTextMessage(
          context,
          _messageController.text.trim(),
          widget.receiverUserId,
          widget.isGroup);
      setState(() {
        _messageController.text = '';
      });
    } else {
      if (isRecording) {
        await _soundRecorder!.stopRecorder();
        File audioFile = File(_audioPath!);
        if (await audioFile.exists()) {
          sendFileMessage(audioFile, MessageEnum.audio);
        }
        _audioPath = null;
      } else {
        var tempDir = await getTemporaryDirectory();
        _audioPath =
            '${tempDir.path}/flutter_sound_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _soundRecorder!.startRecorder(
            toFile: _audioPath,
            codec: Platform.isIOS ? Codec.aacMP4 : Codec.aacMP4);
      }

      setState(() {
        isRecording = !isRecording;
      });
    }
  }

  void sendFileMessage(File file, MessageEnum messageEnum) async {
    await ref.read(chatControllerProvider).sendFileMessage(
        context, file, widget.receiverUserId, messageEnum, widget.isGroup);
  }

  void selectImage() async {
    File? image = await pickImageFromGallery(context);
    if (image != null) {
      sendFileMessage(image, MessageEnum.image);
    }
  }

  void selectVideo() async {
    File? video = await pickVideoFromGallery(context);
    if (video != null) {
      sendFileMessage(video, MessageEnum.video);
    }
  }

  void selectGIF() async {
    final gif = await pickGif(context);
    if (gif != null) {
      ref.read(chatControllerProvider).sendGIFMessage(
          context, gif.url, widget.receiverUserId, widget.isGroup);
    }
  }

  void hideEmojiContainer() {
    setState(() {
      isShowEmojiContainer = false;
    });
  }

  void showKeyboard() => focusNode.requestFocus();
  void hideKeyboard() => focusNode.unfocus();

  void toggleEmojiKeyboardContainer() {
    if (isShowEmojiContainer) {
      showKeyboard();
      hideEmojiContainer();
    } else {
      hideKeyboard();
      showEmojiContainer();
    }
  }

  void showEmojiContainer() {
    setState(() {
      isShowEmojiContainer = true;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _messageController.dispose();
    _soundRecorder!.closeRecorder();
    isRecorderInit = false;
  }

  @override
  Widget build(BuildContext context) {
    final messageReply = ref.watch(messageReplyProvider);
    final isShowMessageReply = messageReply != null;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          isShowMessageReply ? const MessageReplyPreview() : const SizedBox(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: toggleEmojiKeyboardContainer,
                  icon: Icon(
                    Icons.emoji_emotions_outlined,
                    color: Colors.grey[400],
                  ),
                  tooltip: 'Emoji',
                ),
                IconButton(
                  onPressed: selectGIF,
                  icon: Icon(
                    Icons.gif_box_outlined,
                    color: Colors.grey[400],
                  ),
                  tooltip: 'GIF',
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF121B22),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: TextFormField(
                      controller: _messageController,
                      focusNode: focusNode,
                      onChanged: (val) {
                        setState(() => isShowSendButton = val.isNotEmpty);
                      },
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Message',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: selectImage,
                  icon: Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.grey[400],
                  ),
                  tooltip: 'Camera',
                ),
                IconButton(
                  onPressed: selectVideo,
                  icon: Icon(
                    Icons.attach_file,
                    color: Colors.grey[400],
                  ),
                  tooltip: 'Attach',
                ),
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00BFA5),
                        const Color(0xFF1DE9B6),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00BFA5).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: sendTextMessage,
                      borderRadius: BorderRadius.circular(25),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        child: Icon(
                          isShowSendButton
                              ? Icons.send
                              : isRecording
                                  ? Icons.close
                                  : Icons.mic,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isShowEmojiContainer)
            SizedBox(
              height: 310,
              child: EmojiPicker(
                onEmojiSelected: ((category, emoji) {
                  setState(() {
                    _messageController.text =
                        _messageController.text + emoji.emoji;
                  });

                  if (!isShowSendButton) {
                    setState(() {
                      isShowSendButton = true;
                    });
                  }
                }),
              ),
            ),
        ],
      ),
    );
  }
}
