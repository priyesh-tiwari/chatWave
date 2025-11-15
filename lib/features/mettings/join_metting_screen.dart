import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/widgets/loader.dart';

import 'metting_controller.dart';
import 'metting_screen.dart';

class JoinMeetingScreen extends ConsumerStatefulWidget {
  const JoinMeetingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<JoinMeetingScreen> createState() =>
      _JoinMeetingScreenState();
}

class _JoinMeetingScreenState extends ConsumerState<JoinMeetingScreen> {
  late TextEditingController _meetingIdController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _meetingIdController = TextEditingController();
  }

  @override
  void dispose() {
    _meetingIdController.dispose();
    super.dispose();
  }

  void _joinMeeting() async {
    if (_meetingIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a meeting ID')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // First join the meeting
      await ref.read(meetingControllerProvider).joinMeeting(
        context: context,
        meetingId: _meetingIdController.text,
      );

      // Then get the meeting details
      final meeting = await ref
          .read(meetingControllerProvider)
          .getMeetingById(_meetingIdController.text);

      setState(() {
        _isLoading = false;
      });

      if (meeting != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MeetingScreen(
              meeting: meeting,
              isCreator: false,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meeting not found or inactive')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining meeting: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Meeting'),
        backgroundColor: const Color(0xFF075E54),
      ),
      body: _isLoading
          ? const Center(child: Loader())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            // Illustration
            Center(
              child: Icon(
                Icons.video_call,
                size: 100,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 40),
            // Title
            const Text(
              'Join a Meeting',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Subtitle
            Text(
              'Enter the meeting ID shared by the organizer',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 40),
            // Meeting ID Input
            TextField(
              controller: _meetingIdController,
              decoration: InputDecoration(
                hintText: 'Enter Meeting ID',
                labelText: 'Meeting ID',
                prefixIcon: const Icon(Icons.meeting_room),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF075E54),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Join Button
            ElevatedButton.icon(
              onPressed: _joinMeeting,
              icon: const Icon(Icons.login),
              label: const Text('Join Meeting'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF075E54),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Info Text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Make sure the meeting is active before joining',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}