class UserModel{
  final String name;
  final String uid;
  final String profilePic;
  final bool isOnline;
  final String phoneNumber;
  final List<String> groupId;

  UserModel({
    required this.name,
    required this.profilePic,
    required this.uid,
    required this.phoneNumber,
    required this.groupId,
    required this.isOnline
  });

  Map<String , dynamic> toMap(){
    return{
      'name':name,
      'uid':uid,
      'profilePic':profilePic,
      'isOnline':isOnline,
      'phoneNumber':phoneNumber,
      'groupId':groupId
    };
  }
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'] ?? '',
      profilePic: map['profilePic'] ?? '',
      uid: map['uid'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      groupId: (map['groupId'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      isOnline: map['isOnline'] ?? false,
    );
  }
}