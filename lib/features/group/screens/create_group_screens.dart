import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/colors.dart';
import 'package:whatsapp_ui/common/utils/utils.dart';
import 'package:whatsapp_ui/features/group/controller/group_controller.dart';
import 'package:whatsapp_ui/features/group/widget/select_contact_group.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});
  static const routeName='/create_group';

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  File? image;
  final TextEditingController groupNameController=TextEditingController();

  void selectImage()async{
    image=await pickImageFromGallery(context);
    setState(() {

    });
  }
  @override

  void createGroup()async{
    final selectedContacts = ref.read(selectedGroupContacts);
    if(groupNameController.text.trim().isNotEmpty && image!=null && selectedContacts.isNotEmpty){
      await ref.read(groupControllerProvider).createGroup(context, groupNameController.text.trim(), image!, selectedContacts);
      ref.read(selectedGroupContacts.state).update((state)=>[]);
      Navigator.pop(context);
    }else{
      showSnackBar(context: context, content: 'Please fill all fields and select contacts');
    }
  }

  void dispose(){
    super.dispose();
    groupNameController.dispose();
  }
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 10,),
            Stack(
              children: [
                image==null?
                const CircleAvatar(
                  radius: 64,
                  backgroundImage: NetworkImage('https://picsum.photos/600/1200'),
                ) : CircleAvatar(
                  radius: 64,
                  backgroundImage: FileImage(image!),
                ) ,
                Positioned(
                  bottom: -10,
                  left: 80,
                  child: IconButton(
                    onPressed: selectImage,
                    icon: Icon(Icons.add_a_photo),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: TextField(
                controller: groupNameController,
                decoration: InputDecoration(
                  hintText: 'Enter Group Name'
                ),
              ),
            ),
            Container(
              alignment: Alignment.center,
              child: Text('Select Contact', style: TextStyle(fontSize: 18 , fontWeight: FontWeight.w600),),
            ),
            const SelectContactGroup()
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: createGroup,
        backgroundColor: tabColor,
        child: Icon(Icons.done,  color: Colors.white,),
      ),
    );
  }
}
