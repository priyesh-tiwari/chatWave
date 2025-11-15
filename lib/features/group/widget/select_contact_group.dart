import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/error.dart';
import 'package:whatsapp_ui/features/select_contacts/controller/select_contact_controller.dart';
import 'package:whatsapp_ui/widgets/contacts_list.dart';
import 'package:whatsapp_ui/widgets/loader.dart';

final selectedGroupContacts=StateProvider<List<Contact>>((ref)=>[]);

class SelectContactGroup extends ConsumerStatefulWidget {
  const SelectContactGroup({super.key});

  @override
  ConsumerState createState() => _SelectContactGroupState();
}

class _SelectContactGroupState extends ConsumerState<SelectContactGroup> {
  List<int> selectedContactIndex=[];
  void selectContact(int index , Contact contact){
    if(selectedContactIndex.contains(index)){
      selectedContactIndex.removeAt(index);
    }else{
      selectedContactIndex.add(index);
    }
    setState(() {});
    ref.read(selectedGroupContacts.state).update((state)=>[...state, contact]);
  }
  @override
  Widget build(BuildContext context) {
    return ref.watch(getContactsProvider).when(data: (
        ContactsList)=>Expanded(child: ListView.builder(
      itemCount: ContactsList.length,
        itemBuilder: (context , index){
          final contact=ContactsList[index];
          return InkWell(
            onTap: ()=>selectContact(index, contact),
            child: Padding(padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  contact.displayName,
                  style: const TextStyle(
                    fontSize: 18
                  ),
                ),
                leading: selectedContactIndex.contains(index)?IconButton(
                    onPressed: (){},
                    icon: Icon(Icons.done)):null,
              ),

            ),
          );
    })),
        error: (err , trace) =>ErrorScreen(error: err.toString()),
        loading: ()=>const Loader()
    );
  }
}
