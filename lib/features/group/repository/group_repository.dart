import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:whatsapp_ui/common/utils/utils.dart';
import 'package:whatsapp_ui/model/group.dart';

import '../../../cloudinary.dart';

final groupRepositoryProvider=Provider(
    (ref)=>GroupRepository(ref: ref, firestore: FirebaseFirestore.instance, auth: FirebaseAuth.instance)
);

class GroupRepository{
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final ProviderRef ref;
  GroupRepository({
    required this.ref,
    required this.firestore,
    required this.auth
});

  Future<void> createdGroup(BuildContext context , String name , File profilePic , List<Contact> selectedContact)async{
    try{
      List<String> uids=[auth.currentUser!.uid];
      for(int i=0;i<selectedContact.length;i++){
        if(selectedContact[i].phones.isNotEmpty){
          var userCollection=await firestore.collection('users').where('phoneNumber' , isEqualTo: selectedContact[i].phones[0].number.replaceAll(' ', '')).get();
          if(userCollection.docs.isNotEmpty && userCollection.docs[0].exists){
            uids.add(userCollection.docs[0].data()['uid']);
          }
        }
      }
      var groupId=const Uuid().v1();

      String profileUrl=await uploadFileToCloudinary(profilePic, 'image');
      print('Profile URL: $profileUrl');

      Group group=Group(auth.currentUser!.uid, name, groupId, '', profileUrl, uids , DateTime.now());
      await firestore.collection('groups').doc(groupId).set(group.toMap());
      showSnackBar(context: context, content: 'Group created');
    }catch(e){
      showSnackBar(context: context, content: e.toString());
    }
  }

}