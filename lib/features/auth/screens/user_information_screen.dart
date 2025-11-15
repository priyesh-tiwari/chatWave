import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/features/auth/controller/auth_controller.dart';
import 'package:whatsapp_ui/showSnackbar.dart';

class UserInformationScreen extends ConsumerStatefulWidget {
  const UserInformationScreen({Key? key}) : super(key: key);
  static const String routeName = '/user-information';

  @override
  ConsumerState<UserInformationScreen> createState() => _UserInformationScreenState();
}

class _UserInformationScreenState extends ConsumerState<UserInformationScreen> {
  final TextEditingController nameController=TextEditingController();
  File? image;
  @override
  void dispose(){
    super.dispose();
    nameController.dispose();
  }
  void selectImage()async{
    image=await pickImageFromGallery(context);
    setState(() {

    });
  }

  void storeUserData()async{
    String name=nameController.text.trim();
    if(name.isNotEmpty){
      ref.read(authControllerProvider).saveUserDataToFirebase(context, name, image);
    }
  }

  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // center content
            children: [
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
              Row(
                children: [
                  Container(
                  width: size.width*0.85,
                  padding: const EdgeInsets.all(20),
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your name'
                    ),
                    ),
                  ),
                  IconButton(onPressed: storeUserData, icon: const Icon(Icons.done))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
