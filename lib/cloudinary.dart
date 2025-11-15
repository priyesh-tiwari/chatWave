import 'dart:io';

import 'package:cloudinary_public/cloudinary_public.dart';

final cloudinary =
    CloudinaryPublic('dxmyhk7ag', 'unsigned_preset', cache: false);

Future<String> uploadFileToCloudinary(File file, String type) async {
  try {
    print('🔄 Starting Cloudinary upload...');
    print('📁 File path: ${file.path}');
    print('📦 File type: $type');

    // Verify file exists before uploading
    if (!await file.exists()) {
      throw Exception('File does not exist at path: ${file.path}');
    }

    final fileSize = await file.length();
    print('📏 File size: $fileSize bytes');

    if (fileSize == 0) {
      throw Exception('File is empty');
    }

    // Determine resource type
    CloudinaryResourceType resourceType;
    if (type == 'video') {
      resourceType = CloudinaryResourceType.Video;
    } else if (type == 'audio') {
      resourceType = CloudinaryResourceType.Raw;
    } else {
      resourceType = CloudinaryResourceType.Image;
    }

    print('📤 Uploading to Cloudinary...');

    CloudinaryResponse response = await cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        file.path,
        resourceType: resourceType,
      ),
    );

    print('✅ Cloudinary upload successful!');
    print('🔗 Secure URL: ${response.secureUrl}');

    return response.secureUrl;
  } on CloudinaryException catch (e) {
    print('❌ Cloudinary error: ${e.message}');
    print('Error details: ${e.toString()}');
    throw Exception('Cloudinary upload failed: ${e.message}');
  } catch (e) {
    print('❌ Unexpected error during upload: $e');
    throw Exception('Cloudinary upload failed: $e');
  }
}
