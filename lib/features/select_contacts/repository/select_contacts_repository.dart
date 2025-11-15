import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:whatsapp_ui/features/chat/screens/mobile_chat_screen.dart';
import 'package:whatsapp_ui/showSnackbar.dart';

import '../../../model/user_model.dart';

final selectContactRepositoryProvider=Provider((ref)=>SelectContactsRepository(firestore: FirebaseFirestore.instance));

class SelectContactsRepository{
  final FirebaseFirestore firestore;

  SelectContactsRepository({
    required this.firestore
  });
  Future<List<Contact>> getContacts() async{
    List<Contact> contacts=[];
    try{
      if(await FlutterContacts.requestPermission()){
        contacts=await FlutterContacts.getContacts(withProperties: true);
      }
    } catch(e){
      debugPrint(e.toString());
    }
    return contacts;
  }

  void selectContact(Contact selectedContact , BuildContext context) async{
    try{
      var userCollection=await firestore.collection('users').get();
      bool isFound = false;
      for(var document in userCollection.docs){
        var userData=UserModel.fromMap(document.data());

        String selectedPhoneNum = selectedContact.phones[0].number.replaceAll(' ', '');
        if(selectedPhoneNum==userData.phoneNumber){
          isFound=true;
          Navigator.pushNamed(context, MobileChatScreen.routeName , arguments: {
            'name': userData.name,
            'uid': userData.uid,
            'profilePic':userData.profilePic
          });
        }

      }
      if(!isFound){
        showSnackBar(context: context, content: 'This number does not exist');
      }
    } catch(e){
      showSnackBar(context: context, content: e.toString());
    }
  }

}