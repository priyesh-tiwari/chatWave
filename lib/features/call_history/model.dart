class CallHistory {
  final String callId;
  final String callerName;
  final String callerId;
  final String callerPic;
  final String receiverName;
  final String receiverId;
  final String receiverPic;
  final bool isVideoCall;
  final DateTime timestamp;
  final String status; // 'missed', 'received', 'dialed', 'rejected'
  final int duration; // in seconds

  CallHistory({
    required this.callId,
    required this.callerName,
    required this.callerId,
    required this.callerPic,
    required this.receiverName,
    required this.receiverId,
    required this.receiverPic,
    required this.isVideoCall,
    required this.timestamp,
    required this.status,
    required this.duration,
  });

  Map<String, dynamic> toMap() {
    return {
      'callId': callId,
      'callerName': callerName,
      'callerId': callerId,
      'callerPic': callerPic,
      'receiverName': receiverName,
      'receiverId': receiverId,
      'receiverPic': receiverPic,
      'isVideoCall': isVideoCall,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status,
      'duration': duration,
    };
  }

  factory CallHistory.fromMap(Map<String, dynamic> map) {
    return CallHistory(
      callId: map['callId'] ?? '',
      callerName: map['callerName'] ?? '',
      callerId: map['callerId'] ?? '',
      callerPic: map['callerPic'] ?? '',
      receiverName: map['receiverName'] ?? '',
      receiverId: map['receiverId'] ?? '',
      receiverPic: map['receiverPic'] ?? '',
      isVideoCall: map['isVideoCall'] ?? false,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      status: map['status'] ?? 'missed',
      duration: map['duration'] ?? 0,
    );
  }
}