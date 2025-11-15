import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/widgets/loader.dart';

import 'meeting_detail_screen.dart';
import 'metting_controller.dart';

class CreateMeetingScreen extends ConsumerStatefulWidget {
  const CreateMeetingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateMeetingScreen> createState() =>
      _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends ConsumerState<CreateMeetingScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool _isVideoMeeting = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _createMeeting() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a meeting title')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final meeting = await ref.read(meetingControllerProvider).createMeeting(
      context: context,
      title: _titleController.text,
      isVideoMeeting: _isVideoMeeting,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (meeting != null) {
      Navigator.of(context).pop(); // Close the create meeting screen
      // Show the meeting details
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MeetingDetailsScreen(
            meeting: meeting,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Meeting'),
        backgroundColor: const Color(0xFF075E54),
      ),
      body: _isLoading
          ? const Center(child: Loader())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            // Title Input
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Meeting Title',
                labelText: 'Meeting Title',
                prefixIcon: const Icon(Icons.title),
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
            const SizedBox(height: 20),
            // Description Input
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Meeting Description (Optional)',
                labelText: 'Description',
                prefixIcon: const Icon(Icons.description),
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
            const SizedBox(height: 30),
            // Meeting Type Selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Meeting Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isVideoMeeting = true;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _isVideoMeeting
                                  ? const Color(0xFF075E54)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF075E54),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.videocam,
                                  color: _isVideoMeeting
                                      ? Colors.white
                                      : const Color(0xFF075E54),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Video',
                                  style: TextStyle(
                                    color: _isVideoMeeting
                                        ? Colors.white
                                        : const Color(0xFF075E54),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isVideoMeeting = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: !_isVideoMeeting
                                  ? const Color(0xFF075E54)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF075E54),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.call,
                                  color: !_isVideoMeeting
                                      ? Colors.white
                                      : const Color(0xFF075E54),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Audio',
                                  style: TextStyle(
                                    color: !_isVideoMeeting
                                        ? Colors.white
                                        : const Color(0xFF075E54),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Create Meeting Button
            ElevatedButton.icon(
              onPressed: _createMeeting,
              icon: const Icon(Icons.video_call),
              label: const Text('Create Meeting'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF075E54),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}