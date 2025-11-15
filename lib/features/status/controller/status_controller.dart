import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/features/auth/controller/auth_controller.dart';

import '../../../model/status_model.dart';
import '../repository/status_repository.dart';



final statusControllerProvider=Provider((ref){
  final StatusRepository=ref.read(stateRepositoryProvider);
  return StatusController(statusRepository: StatusRepository, ref: ref);
});

class StatusController{
  final StatusRepository statusRepository;
  ProviderRef ref;

  StatusController({
    required this.statusRepository,
    required this.ref
});

  Future<void> addStatus(File file, BuildContext context) async {
    print('🔵 addStatus called');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Get the AsyncValue from the stream provider
      final userData = await ref.read(userDataStreamProvider.future);

      if (userData == null) {
        throw Exception('User data not available. Please log out and log in again.');
      }

      print('🔵 User: ${userData.name}, Phone: ${userData.phoneNumber}');
      print('🟢 Starting upload...');

      await statusRepository.uploadStatus(
        username: userData.name,
        profilePic: userData.profilePic,
        phoneNumber: userData.phoneNumber,
        statusImage: file,
        context: context,
      );

      print('✅ Upload completed');

      if (context.mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error: $e');

      if (context.mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<List<Status>> getStatus(BuildContext context)async{
    await statusRepository.debugFirestore(); // Add this line
    List<Status> statuses=await statusRepository.getStatus(context);
    return statuses;
  }
}