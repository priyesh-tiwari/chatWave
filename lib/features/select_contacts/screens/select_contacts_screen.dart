import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/error.dart';
import 'package:whatsapp_ui/widgets/loader.dart';

import '../controller/select_contact_controller.dart';

import 'package:flutter_contacts/flutter_contacts.dart';

class SelectContactsScreen extends ConsumerWidget {
  const SelectContactsScreen({super.key});
  static const routeName='/select-contact';

  void selectContact(WidgetRef ref , Contact selectedContact , BuildContext context){
    ref.read(selectContactControllerProvider).selectContact(selectedContact, context);
  }

  @override
  Widget build(BuildContext context , WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select contact'),
        actions: [
          IconButton(onPressed: (){}, icon: const Icon(Icons.search)),
          IconButton(onPressed: (){}, icon: const Icon(Icons.more_vert))
        ],
      ),
      body: ref.watch(getContactsProvider).when(

          data: (contactList)=>ListView.builder(
              itemCount: contactList.length,
              itemBuilder: (context , index){
                final contact=contactList[index];
                return InkWell(
                  onTap: ()=> selectContact(ref, contact, context),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ListTile(
                      title: Text(contact.displayName , style: TextStyle(fontSize: 18),),
                      leading: contact.photo==null?null:CircleAvatar(
                        backgroundImage: MemoryImage(contact.photo!),
                        radius: 30,
                      ),
                    ),
                  ),
                );
              }
          ),

          error: (err , trace)=>ErrorScreen(error: err.toString()),

          loading: ()=>Loader()),
    );
  }
}
