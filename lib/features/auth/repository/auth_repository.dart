import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/common/repositories/common_firebase_storage_repository.dart';
import 'package:whatsapp_ui/features/auth/screens/user_information_screen.dart';
import 'package:whatsapp_ui/model/user_model.dart';
import 'package:whatsapp_ui/screens/mobile_layout_screen.dart';

import '../../../cloudinary.dart';
import '../../../showSnackbar.dart';
import '../screens/otp_screen.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository(
    auth: FirebaseAuth.instance, firestore: FirebaseFirestore.instance));

class AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  AuthRepository({required this.auth, required this.firestore});

  Future<UserModel?> getCurrentUserData() async {
    var userData =
        await firestore.collection('users').doc(auth.currentUser?.uid).get();

    UserModel? user;
    if (userData.data() != null) {
      user = UserModel.fromMap(userData.data()!);
    }
    return user;
  }

  void signInWithPhone(BuildContext context, String phoneNumber) async {
    try {
      await auth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (PhoneAuthCredential credential) async {
            await auth.signInWithCredential(credential);
          },
          verificationFailed: (e) {
            throw Exception(e.message);
          },
          codeSent: ((String verificationId, int? resendToken) async {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OTPScreen(verificationId: verificationId),
              ),
            );
          }),
          codeAutoRetrievalTimeout: (String verificationId) {
            verificationId;
          });
    } on FirebaseAuthException catch (e) {
      showSnackBar(context: context, content: e.message!);
    }
  }

  void verifyOTP(
      {required BuildContext context,
      required String verificationId,
      required String userOTP}) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId, smsCode: userOTP);

      await auth.signInWithCredential(credential);
      if (auth.currentUser != null) {
        final userDoc = await firestore
            .collection('users')
            .doc(auth.currentUser!.uid)
            .get();

        if (userDoc.exists) {
          // User already exists - go to main screen
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => const MobileLayoutScreen()),
              (route) => false);
        } else {
          // New user - go to user information screen
          Navigator.pushNamedAndRemoveUntil(
              context, UserInformationScreen.routeName, (route) => false);
        }
      }
    } on FirebaseAuthException catch (e) {
      showSnackBar(context: context, content: e.message!);
    } catch (e) {
      if (auth.currentUser != null) {
        final userDoc = await firestore
            .collection('users')
            .doc(auth.currentUser!.uid)
            .get();

        if (userDoc.exists) {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => const MobileLayoutScreen()),
              (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(
              context, UserInformationScreen.routeName, (route) => false);
        }
      } else {
        showSnackBar(context: context, content: 'Authentication failed');
      }
    }
  }

  void saveUserDataToFirebase(
      {required String name,
      required File? profilePic,
      required ProviderRef ref,
      required BuildContext context}) async {
    try {
      String uid = auth.currentUser!.uid;
      String photoUrl = 'https://picsum.photos/600/1200';

      if (profilePic != null) {
        photoUrl = await ref
            .read(commonFirebaseRepositoryProvider)
            .storeFileToFirebase('profilePic/$uid', profilePic);
      }

      var user = UserModel(
          name: name,
          profilePic: photoUrl,
          uid: uid,
          phoneNumber: auth.currentUser!.phoneNumber!,
          groupId: [],
          isOnline: true);

      await firestore.collection('users').doc(uid).set(user.toMap());

      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MobileLayoutScreen()),
          (route) => false);
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  Stream<UserModel> userData(String userId) {
    return firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((event) => UserModel.fromMap(event.data()!));
  }

  void setUserState(bool isOnline) async {
    await firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .update({'isOnline': isOnline});
  }

  Future<void> signOut() async {
    try {
      final currentUser = auth.currentUser;

      if (currentUser != null) {
        await firestore
            .collection('users')
            .doc(currentUser.uid)
            .update({'isOnline': false}).timeout(const Duration(seconds: 5),
                onTimeout: () {
          debugPrint(
              '⚠️ Timeout setting user offline, continuing with sign out');
        });
      }

      await auth.signOut();
      await Future.delayed(const Duration(milliseconds: 300));

      print('✅ User signed out successfully');
    } catch (e) {
      print('❌ Error during sign out: $e');
      await auth.signOut();
    }
  }

  Future<void> updateUserProfile({
    required BuildContext context,
    required String uid,
    String? newName,
    File? newProfilePic,
  }) async {
    try {
      Map<String, dynamic> updates = {};

      // Update name if provided
      if (newName != null && newName.isNotEmpty) {
        updates['name'] = newName;
      }

      // Upload profile picture if provided
      if (newProfilePic != null) {
        print('📤 Starting profile picture upload...');

        // Verify file exists
        if (!await newProfilePic.exists()) {
          throw Exception('Selected file does not exist');
        }

        print('📁 File path: ${newProfilePic.path}');
        print('📏 File size: ${await newProfilePic.length()} bytes');

        // Upload to Cloudinary
        final String photoUrl = await uploadFileToCloudinary(
          newProfilePic,
          'image',
        );

        print('✅ Upload successful: $photoUrl');
        updates['profilePic'] = photoUrl;
      }

      // Update Firestore if there are changes
      if (updates.isNotEmpty) {
        print('💾 Updating Firestore with: $updates');

        await firestore.collection('users').doc(uid).update(updates);

        print('✅ Firestore updated successfully');

        if (context.mounted) {
          showSnackBar(
              context: context, content: 'Profile updated successfully');
        }
      } else {
        print('⚠️ No updates to apply');
      }
    } catch (e, stackTrace) {
      print('❌ Error updating profile: $e');
      print('Stack trace: $stackTrace');

      if (context.mounted) {
        showSnackBar(
          context: context,
          content: 'Failed to update profile: ${e.toString()}',
        );
      }
      rethrow;
    }
  }
}
