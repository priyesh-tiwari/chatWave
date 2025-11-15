import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/colors.dart';
import 'package:whatsapp_ui/features/status/controller/status_controller.dart';

class ConfirmStatusScreen extends ConsumerWidget {
  static const String routeName='/confirm-status-screen';
  final File file;
  const ConfirmStatusScreen({super.key, required this.file});

  Future<void> addStatus(WidgetRef ref, BuildContext context) async {
    await ref.read(statusControllerProvider).addStatus(file, context);
  }



  @override
  Widget build(BuildContext context , WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: AspectRatio(aspectRatio: 9/16, child: Image.file(file),),
      ),
      floatingActionButton:FloatingActionButton(
        child: const Icon(Icons.done ,color: Colors.white,),
        onPressed: () {addStatus(ref, context);},
        backgroundColor: tabColor,
      ),
    );
  }
}
