import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/common/utils/utils.dart';
import 'package:whatsapp_ui/features/auth/controller/auth_controller.dart';
import 'package:whatsapp_ui/features/group/screens/create_group_screens.dart';
import 'package:whatsapp_ui/features/select_contacts/screens/select_contacts_screen.dart';
import 'package:whatsapp_ui/features/status/screens/confirm_status_screen.dart';
import 'package:whatsapp_ui/features/status/screens/status_contact_screen.dart';
import 'package:whatsapp_ui/screens/profile_screen.dart';
import 'package:whatsapp_ui/widgets/contacts_list.dart';

import '../features/call_history/screen.dart';
import '../features/mettings/meeting_list_screen.dart';

class MobileLayoutScreen extends ConsumerStatefulWidget {
  const MobileLayoutScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MobileLayoutScreen> createState() => _MobileLayoutScreenState();
}

class _MobileLayoutScreenState extends ConsumerState<MobileLayoutScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late TabController tabController;
  int _currentIndex = 0;

  // Animation for FAB scale
  late AnimationController _fabController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    tabController = TabController(length: 3, vsync: this);

    tabController.addListener(() {
      if (_currentIndex != tabController.index) {
        setState(() {
          _currentIndex = tabController.index;
        });
      }
    });

    // Initialize FAB animation safely
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );

    // Start animation after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fabController.forward();
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    _fabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        ref.read(authControllerProvider).setUserState(true);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        ref.read(authControllerProvider).setUserState(false);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121B22),
      body: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildTabIndicators(),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: const [
                ContactsList(),
                StatusContactScreen(),
                CallHistoryScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
      floatingActionButton: _buildDynamicFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF121B22), Color(0xFF1E2A34)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF00BFA5), Color(0xFF1DE9B6)],
                  ).createShader(bounds),
                  child: const Text(
                    'ChatWave',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getSubtitle(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[400],
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildHeaderIcon(Icons.search_rounded, () {}),
              const SizedBox(width: 8),
              _buildProfileIcon(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: Colors.grey[300],
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileIcon() {
    final user = ref.watch(userDataAuthProvider).value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, ProfileScreen.routeName);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: user?.profilePic != null && user!.profilePic.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    user.profilePic,
                    width: 20,
                    height: 20,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person_rounded,
                        color: Colors.grey[300],
                        size: 20,
                      );
                    },
                  ),
                )
              : Icon(
                  Icons.person_rounded,
                  color: Colors.grey[300],
                  size: 20,
                ),
        ),
      ),
    );
  }

  String _getSubtitle() {
    switch (_currentIndex) {
      case 0:
        return 'Stay connected';
      case 1:
        return 'View updates';
      case 2:
        return 'Call history';
      default:
        return 'Stay connected';
    }
  }

  Widget _buildTabIndicators() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTab('Chats', 0, Icons.chat_bubble_rounded),
          const SizedBox(width: 12),
          _buildTab('Updates', 1, Icons.donut_large_rounded),
          const SizedBox(width: 12),
          _buildTab('Calls', 2, Icons.call_rounded),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index, IconData icon) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        tabController.animateTo(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 12,
          vertical: isActive ? 10 : 8,
        ),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF00BFA5), Color(0xFF1DE9B6)],
                )
              : null,
          color: isActive ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF00BFA5).withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey[500],
              size: 18,
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBottomNavItem(
                Icons.group_add_rounded,
                'New Group',
                () {
                  Navigator.pushNamed(context, CreateGroupScreen.routeName);
                },
              ),
              _buildBottomNavItem(
                Icons.videocam_rounded,
                'Meetings',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MeetingsListScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: Colors.grey[300],
                  size: 22,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicFAB() {
    // Chat tab - show message icon
    if (_currentIndex == 0) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00A884).withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, SelectContactsScreen.routeName);
            },
            backgroundColor: const Color(0xFF00A884),
            elevation: 0,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: child,
              ),
              child: const Icon(
                Icons.message_rounded,
                key: ValueKey('message_icon'),
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      );
    }
    // Updates/Status tab - show camera icon
    else if (_currentIndex == 1) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00A884).withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () async {
              File? pickedImage = await pickImageFromGallery(context);
              if (pickedImage != null) {
                Navigator.pushNamed(
                  context,
                  ConfirmStatusScreen.routeName,
                  arguments: pickedImage,
                );
              }
            },
            backgroundColor: const Color(0xFF00A884),
            elevation: 0,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: child,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                key: ValueKey('camera_icon'),
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      );
    }
    // Calls tab - no FAB
    else {
      return const SizedBox.shrink();
    }
  }
}
