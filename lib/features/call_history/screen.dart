import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:whatsapp_ui/features/call/controller/call_controller.dart';
import 'package:whatsapp_ui/features/chat/screens/mobile_chat_screen.dart';
import 'package:whatsapp_ui/widgets/loader.dart';

import 'model.dart';

class CallHistoryScreen extends ConsumerWidget {
  const CallHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: StreamBuilder<List<CallHistory>>(
        stream: ref.watch(callControllerProvider).getCallHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(20.0),
              child: Loader(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final callHistory = snapshot.data![index];
              return CallHistoryTile(callHistory: callHistory);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.call_end,
              color: Colors.grey,
              size: 40,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No call history',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class CallHistoryTile extends ConsumerWidget {
  final CallHistory callHistory;

  const CallHistoryTile({Key? key, required this.callHistory})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.read(callControllerProvider).auth.currentUser!.uid;

    // Determine if this call is outgoing (you made the call) or incoming
    final bool isOutgoing = callHistory.callerId == currentUid;

    // Always show the other user
    final displayName =
        isOutgoing ? callHistory.receiverName : callHistory.callerName;
    final displayPic =
        isOutgoing ? callHistory.receiverPic : callHistory.callerPic;
    final otherUserId =
        isOutgoing ? callHistory.receiverId : callHistory.callerId;

    IconData statusIcon;
    Color statusColor;

    switch (callHistory.status) {
      case 'dialed':
        statusIcon = Icons.call_made;
        statusColor = Colors.green;
        break;
      case 'received':
        statusIcon = Icons.call_received;
        statusColor = Colors.blue;
        break;
      case 'missed':
        statusIcon = Icons.call_missed;
        statusColor = Colors.red;
        break;
      case 'rejected':
        statusIcon = Icons.call_missed_outgoing;
        statusColor = Colors.orange;
        break;
      default:
        statusIcon = Icons.call;
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A34),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              MobileChatScreen.routeName,
              arguments: {
                'name': displayName,
                'uid': otherUserId,
                'isGroup': false,
                'profilePic': displayPic,
              },
            );
          },
          onLongPress: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Call'),
                content: const Text('Delete this call from history?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () {
                        ref.read(callControllerProvider).deleteCallHistory(
                              context,
                              callHistory.callId,
                            );
                        Navigator.pop(context);
                      },
                      child: const Text('Delete',
                          style: TextStyle(color: Colors.red))),
                ],
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.teal.withOpacity(0.3),
                        Colors.teal.withOpacity(0.1),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(displayPic),
                    radius: 28,
                    backgroundColor: Colors.grey[800],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          color: callHistory.status == 'missed'
                              ? Colors.red
                              : Colors.white,
                          fontSize: 16,
                          fontWeight: callHistory.status == 'missed'
                              ? FontWeight.bold
                              : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _getCallDescription(callHistory, isOutgoing),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTimestamp(callHistory.timestamp),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Icon(
                      callHistory.isVideoCall ? Icons.videocam : Icons.call,
                      color: Colors.teal,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getCallDescription(CallHistory call, bool isOutgoing) {
    String type = call.isVideoCall ? "Video" : "Voice";

    if (call.status == 'missed') {
      return 'Missed $type call';
    } else if (call.status == 'rejected') {
      return 'Rejected $type call';
    } else if (isOutgoing) {
      return 'Outgoing $type call • ${_formatDuration(call.duration)}';
    } else {
      return 'Incoming $type call • ${_formatDuration(call.duration)}';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return DateFormat.Hm().format(timestamp);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat.E().format(timestamp);
    } else {
      return DateFormat.MMMd().format(timestamp);
    }
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return '0:00';

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${secs.toString().padLeft(2, '0')}';
    }
  }
}
