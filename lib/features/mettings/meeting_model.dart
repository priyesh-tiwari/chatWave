class Meeting {
  final String meetingId;
  final String creatorId;
  final String creatorName;
  final String creatorPic;
  final String title;
  final DateTime createdAt;
  final List<String> participantIds;
  final List<String> participantNames;
  final bool isActive;
  final bool isVideoMeeting;
  final String? description;
  final int duration; // in seconds

  Meeting({
    required this.meetingId,
    required this.creatorId,
    required this.creatorName,
    required this.creatorPic,
    required this.title,
    required this.createdAt,
    required this.participantIds,
    required this.participantNames,
    required this.isActive,
    required this.isVideoMeeting,
    this.description,
    this.duration = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'meetingId': meetingId,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'creatorPic': creatorPic,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'participantIds': participantIds,
      'participantNames': participantNames,
      'isActive': isActive,
      'isVideoMeeting': isVideoMeeting,
      'description': description ?? '',
      'duration': duration,
    };
  }

  factory Meeting.fromMap(Map<String, dynamic> map) {
    return Meeting(
      meetingId: map['meetingId'] ?? '',
      creatorId: map['creatorId'] ?? '',
      creatorName: map['creatorName'] ?? '',
      creatorPic: map['creatorPic'] ?? '',
      title: map['title'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      participantIds: (map['participantIds'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      participantNames: (map['participantNames'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      isActive: map['isActive'] ?? false,
      isVideoMeeting: map['isVideoMeeting'] ?? true,
      description: map['description'] ?? '',
      duration: map['duration'] ?? 0,
    );
  }

  Meeting copyWith({
    String? meetingId,
    String? creatorId,
    String? creatorName,
    String? creatorPic,
    String? title,
    DateTime? createdAt,
    List<String>? participantIds,
    List<String>? participantNames,
    bool? isActive,
    bool? isVideoMeeting,
    String? description,
    int? duration,
  }) {
    return Meeting(
      meetingId: meetingId ?? this.meetingId,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      creatorPic: creatorPic ?? this.creatorPic,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      participantIds: participantIds ?? this.participantIds,
      participantNames: participantNames ?? this.participantNames,
      isActive: isActive ?? this.isActive,
      isVideoMeeting: isVideoMeeting ?? this.isVideoMeeting,
      description: description ?? this.description,
      duration: duration ?? this.duration,
    );
  }
}