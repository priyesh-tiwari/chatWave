class Call {
  final String callerId;
  final String callerName;
  final String callerPic;
  final String receiverId;
  final String receiverName;
  final String receiverPic;
  final String callId;
  final bool hasDialled;
  final bool isVideoCall; // added parameter

  Call(
      this.callerId,
      this.callerName,
      this.callerPic,
      this.receiverId,
      this.receiverName,
      this.receiverPic,
      this.callId,
      this.hasDialled,
      this.isVideoCall, // added here
      );

  // Convert Call object to Map
  Map<String, dynamic> toMap() {
    return {
      'callerId': callerId,
      'callerName': callerName,
      'callerPic': callerPic,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverPic': receiverPic,
      'callId': callId,
      'hasDialled': hasDialled,
      'isVideoCall': isVideoCall, // added here
    };
  }

  // Create a Call object from a Map
  factory Call.fromMap(Map<String, dynamic> map) {
    return Call(
      map['callerId'] ?? '',
      map['callerName'] ?? '',
      map['callerPic'] ?? '',
      map['receiverId'] ?? '',
      map['receiverName'] ?? '',
      map['receiverPic'] ?? '',
      map['callId'] ?? '',
      map['hasDialled'] ?? false,
      map['isVideoCall'] ?? false, // added here
    );
  }
}
