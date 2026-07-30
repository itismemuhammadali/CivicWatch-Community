import 'dart:convert';
import 'dart:io';

const String projectId = 'commctv-f2b45';
const String apiKey = 'AIzaSyAO-iIxJvS_rVmR6TsOmCbIGC42usT5qm8';

final List<Map<String, dynamic>> targetUsers = [
  {
    'email': 'admin@cctv.app',
    'password': 'admin@123',
    'firstName': 'Admin',
    'lastName': 'Test',
    'role': 'admin',
    'userId': 2,
  },
  {
    'email': 'superadmin@cctv.app',
    'password': 'superadmin@123',
    'firstName': 'Super',
    'lastName': 'Admin',
    'role': 'super admin',
    'userId': 3,
  },
];

Future<void> main() async {
  final client = HttpClient();
  
  print('========================================');
  print('START SEEDING PRODUCTION DATABASE');
  print('========================================\n');

  for (final user in targetUsers) {
    final email = user['email']!;
    final password = user['password']!;
    final firstName = user['firstName']!;
    final lastName = user['lastName']!;
    final role = user['role']!;
    final userId = user['userId']!;
    
    print('Processing user: $email...');
    
    String? localId;
    String? idToken;
    
    try {
      final signUpUrl = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey');
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
        localId = data['localId'];
        idToken = data['idToken'];
        print('  [Auth] Registered successfully. UID: $localId');
      } else {
        final errorMsg = data['error']?['message'] ?? 'Unknown error';
        if (errorMsg == 'EMAIL_EXISTS') {
          print('  [Auth] User already exists. Fetching UID via sign in...');
          final signInUrl = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey');
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
            localId = signInData['localId'];
            idToken = signInData['idToken'];
            print('  [Auth] Retrieved UID: $localId');
          } else {
            print('  [Auth] Failed to sign in: ${signInData['error']?['message'] ?? 'Unknown error'}');
          }
        } else {
          print('  [Auth] Failed to register: $errorMsg');
        }
      }
    } catch (e) {
      print('  [Auth] Error: $e');
    }
    
    if (localId != null && idToken != null) {
      try {
        final firestoreUrl = Uri.parse(
          'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users/$localId'
        );
        final request = await client.patchUrl(firestoreUrl);
        request.headers.contentType = ContentType.json;
        request.headers.add('Authorization', 'Bearer $idToken');
        
        final fields = {
          'firstName': {'stringValue': firstName},
          'lastName': {'stringValue': lastName},
          'email': {'stringValue': email},
          'role': {'stringValue': role},
          'userId': {'integerValue': '$userId'},
          'user_id': {'integerValue': '$userId'},
          'is_active': {'stringValue': 'Y'},
          'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()}
        };
        
        request.write(jsonEncode({
          'fields': fields,
        }));
        
        final response = await request.close();
        
        if (response.statusCode == 200) {
          print('  [Firestore] Profile document created/updated');
        } else {
          final body = await response.transform(utf8.decoder).join();
          print('  [Firestore] Failed to update profile: Status ${response.statusCode} - $body');
        }
      } catch (e) {
        print('  [Firestore] Error: $e');
      }
    }
    print('');
  }

  client.close();
  print('\n========================================');
  print('SEEDING COMPLETED SUCCESSFULLY!');
  print('========================================');
}
