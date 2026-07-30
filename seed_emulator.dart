import 'dart:convert';
import 'dart:io';

const String apiKey = 'fake-api-key';
const String projectId = 'commctv-f2b45';

final List<Map<String, dynamic>> targetUsers = [
  {
    'email': 'user@cctv.app',
    'password': 'user@123',
    'firstName': 'User',
    'lastName': 'Test',
    'role': 'user',
    'userId': 1001,
  },
  {
    'email': 'admin@cctv.app',
    'password': 'admin@123',
    'firstName': 'Admin',
    'lastName': 'Test',
    'role': 'admin',
    'userId': 1002,
  },
  {
    'email': 'superadmin@cctv.app',
    'password': 'superadmin@123',
    'firstName': 'Super',
    'lastName': 'Admin',
    'role': 'super admin',
    'userId': 1003,
  },
];

Future<void> main() async {
  final client = HttpClient();
  
  for (final user in targetUsers) {
    final email = user['email'] as String;
    final password = user['password'] as String;
    final firstName = user['firstName'] as String;
    final lastName = user['lastName'] as String;
    final role = user['role'] as String;
    final userId = user['userId'] as int;
    
    print('Processing $email...');
    
    String? idToken;
    String? localId;
    
    // Try to signUp via Emulator Auth
    try {
      final signUpUrl = Uri.parse('http://localhost:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey');
      final request = await client.postUrl(signUpUrl);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }));
      
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body);
      
      if (response.statusCode == 200) {
        idToken = data['idToken'];
        localId = data['localId'];
        print('  Successfully registered user $email with UID: $localId');
      } else {
        final errorMsg = data['error']?['message'] ?? 'Unknown error';
        if (errorMsg == 'EMAIL_EXISTS') {
          print('  User $email already exists. Attempting to sign in to fetch token...');
          // Try to signIn
          final signInUrl = Uri.parse('http://localhost:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey');
          final signInReq = await client.postUrl(signInUrl);
          signInReq.headers.contentType = ContentType.json;
          signInReq.write(jsonEncode({
            'email': email,
            'password': password,
            'returnSecureToken': true,
          }));
          
          final signInResp = await signInReq.close();
          final signInBody = await signInResp.transform(utf8.decoder).join();
          final signInData = jsonDecode(signInBody);
          
          if (signInResp.statusCode == 200) {
            idToken = signInData['idToken'];
            localId = signInData['localId'];
            print('  Successfully signed in user $email. UID: $localId');
          } else {
            print('  Failed to sign in user $email: ${signInData['error']?['message'] ?? 'Unknown error'}');
          }
        } else {
          print('  Failed to register user $email: $errorMsg');
        }
      }
    } catch (e) {
      print('  Error during auth operations for $email: $e');
    }
    
    // Now write to Firestore Emulator if we have token and localId
    if (idToken != null && localId != null) {
      try {
        final firestoreUrl = Uri.parse(
          'http://localhost:8080/v1/projects/$projectId/databases/(default)/documents/users/$localId'
        );
        final request = await client.patchUrl(firestoreUrl);
        request.headers.contentType = ContentType.json;
        request.headers.set('Authorization', 'Bearer $idToken');
        
        final fields = {
          'user_id': {'integerValue': '$userId'},
          'firstName': {'stringValue': firstName},
          'lastName': {'stringValue': lastName},
          'email': {'stringValue': email},
          'role': {'stringValue': role},
          'is_active': {'stringValue': 'Y'},
          'profileImageUrl': {'stringValue': ''},
          'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()}
        };
        
        request.write(jsonEncode({
          'fields': fields,
        }));
        
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();
        
        if (response.statusCode == 200) {
          print('  Successfully created/updated Firestore document for $email');
        } else {
          print('  Failed to update Firestore document: Status ${response.statusCode}');
          print('  Response body: $body');
        }
      } catch (e) {
        print('  Error writing to Firestore for $email: $e');
      }
    }
    print('');
  }
  
  // Seed Announcements
  try {
    print('Seeding announcements...');
    final announcementsUrl = Uri.parse('http://localhost:8080/v1/projects/$projectId/databases/(default)/documents/announcements/seed_alert_1');
    final request = await client.patchUrl(announcementsUrl);
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({
      'fields': {
        'announcement_id': {'integerValue': '1'},
        'category': {'stringValue': 'U'},
        'alert_note': {'stringValue': 'Scheduled maintenance this weekend!'},
        'attached_meta_id': {'integerValue': '0'},
        'created_by': {'integerValue': '1002'},
        'created_at': {'timestampValue': DateTime.now().toUtc().toIso8601String()}
      }
    }));
    await request.close();
    print('Seeded announcement 1.');
  } catch (e) {
    print('Error seeding announcements: $e');
  }

  // Seed Post Reports
  try {
    print('Seeding post reports...');
    final reportsUrl = Uri.parse('http://localhost:8080/v1/projects/$projectId/databases/(default)/documents/post_reports/seed_report_1');
    final request = await client.patchUrl(reportsUrl);
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({
      'fields': {
        'report_id': {'integerValue': '1'},
        'post_id': {'integerValue': '100'},
        'report_reason_type_id': {'integerValue': '1'},
        'report_additional_information': {'stringValue': 'This post contains offensive language.'},
        'created_by': {'integerValue': '1001'},
        'report_status': {'stringValue': 'P'},
        'created_at': {'timestampValue': DateTime.now().toUtc().toIso8601String()}
      }
    }));
    await request.close();
    print('Seeded post report 1.');
  } catch (e) {
    print('Error seeding post reports: $e');
  }

  client.close();
  print('Finished processing all credentials and seed data.');
}
