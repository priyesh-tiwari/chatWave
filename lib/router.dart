import 'dart:io';

import 'package:flutter/material.dart';
import 'package:whatsapp_ui/features/auth/screens/login_screen.dart';
import 'package:whatsapp_ui/features/auth/screens/user_information_screen.dart';
import 'package:whatsapp_ui/screens/profile_screen.dart';

import 'error.dart';
import 'features/auth/screens/otp_screen.dart';
import 'features/call/screens/call_pickup_screen.dart';
import 'features/chat/screens/mobile_chat_screen.dart';
import 'features/group/screens/create_group_screens.dart';
import 'features/select_contacts/screens/select_contacts_screen.dart';
import 'features/status/screens/confirm_status_screen.dart';
import 'features/status/screens/status_screen.dart';
import 'model/status_model.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case LoginScreen.routeName:
      return MaterialPageRoute(builder: (context) => const LoginScreen());
    case OTPScreen.routeName:
      final verificationId = settings.arguments as String;
      return MaterialPageRoute(
          builder: (context) => OTPScreen(
                verificationId: verificationId,
              ));
    case UserInformationScreen.routeName:
      return MaterialPageRoute(
        builder: (context) => const UserInformationScreen(),
      );
    case SelectContactsScreen.routeName:
      return MaterialPageRoute(
        builder: (context) => const SelectContactsScreen(),
      );
    case MobileChatScreen.routeName:
      final arguments = settings.arguments as Map<String, dynamic>;
      final name = arguments['name'];
      final uid = arguments['uid'];
      final isGroup = arguments['isGroup'] ?? false;
      final profilePic = arguments['profilePic'];

      return MaterialPageRoute(
        builder: (context) => CallPickupScreen(
          scaffold: MobileChatScreen(
            name: name,
            uid: uid,
            isGroup: isGroup,
            profilePic: profilePic,
          ),
        ),
      );

    case ConfirmStatusScreen.routeName:
      final file = settings.arguments as File;

      return MaterialPageRoute(
        builder: (context) => ConfirmStatusScreen(file: file),
      );
    case StatusScreen.routeName:
      final status = settings.arguments as Status;

      return MaterialPageRoute(
        builder: (context) => StatusScreen(status: status),
      );

    case CreateGroupScreen.routeName:
      return MaterialPageRoute(
        builder: (context) => const CreateGroupScreen(),
      );
    case ProfileScreen.routeName:
      return MaterialPageRoute(
        builder: (context) => ProfileScreen(),
      );
    default:
      return MaterialPageRoute(
          builder: (context) => Scaffold(
                body: ErrorScreen(error: 'This page doesn\'t exist'),
              ));
  }
}
