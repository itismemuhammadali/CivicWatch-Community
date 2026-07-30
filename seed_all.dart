import 'dart:convert';
import 'dart:io';

const String projectId = 'commctv-f2b45';

final List<Map<String, dynamic>> targetUsers = [
  {
    'email': 'user@cctv.app',
    'password': 'user@123',
    'firstName': 'User',
    'lastName': 'Test',
    'role': 'user',
    'userId': 1,
  },
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

final List<Map<String, dynamic>> parameters = [
  // CASE_CATEGORY
  {'param_detail_id': 1, 'param_header': 'CASE_CATEGORY', 'param_label': 'Family Affairs', 'param_value': 'FA'},
  {'param_detail_id': 2, 'param_header': 'CASE_CATEGORY', 'param_label': 'Divorce', 'param_value': 'DV'},
  {'param_detail_id': 3, 'param_header': 'CASE_CATEGORY', 'param_label': 'Neighborhood conflicts', 'param_value': 'NC'},
  {'param_detail_id': 4, 'param_header': 'CASE_CATEGORY', 'param_label': 'Property disputes', 'param_value': 'PD'},
  {'param_detail_id': 5, 'param_header': 'CASE_CATEGORY', 'param_label': 'Custody', 'param_value': 'CU'},

  // CASE_VIEW_CATEGORY
  {'param_detail_id': 6, 'param_header': 'CASE_VIEW_CATEGORY', 'param_label': 'Public', 'param_value': 'PUB'},
  {'param_detail_id': 7, 'param_header': 'CASE_VIEW_CATEGORY', 'param_label': 'Private', 'param_value': 'PRV'},
  {'param_detail_id': 8, 'param_header': 'CASE_VIEW_CATEGORY', 'param_label': 'Friends Only', 'param_value': 'FRD'},

  // CASE_AVAILIBILITY_TYPE
  {'param_detail_id': 9, 'param_header': 'CASE_AVAILIBILITY_TYPE', 'param_label': '24 hours', 'param_value': '24H'},
  {'param_detail_id': 10, 'param_header': 'CASE_AVAILIBILITY_TYPE', 'param_label': 'week', 'param_value': 'WK'},
  {'param_detail_id': 11, 'param_header': 'CASE_AVAILIBILITY_TYPE', 'param_label': 'Month', 'param_value': 'MN'},
];

Future<void> main() async {
  final client = HttpClient();
  
  print('========================================');
  print('START SEEDING LOCAL EMULATOR DATABASE');
  print('========================================\n');

  // 1. Seed Auth & Users
  for (final user in targetUsers) {
    final email = user['email']!;
    final password = user['password']!;
    final firstName = user['firstName']!;
    final lastName = user['lastName']!;
    final role = user['role']!;
    final userId = user['userId']!;
    
    print('Processing user: $email...');
    
    String? localId;
    
    try {
      final signUpUrl = Uri.parse('http://localhost:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-key');
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
        print('  [Auth] Registered successfully. UID: $localId');
      } else {
        final errorMsg = data['error']?['message'] ?? 'Unknown error';
        if (errorMsg == 'EMAIL_EXISTS') {
          print('  [Auth] User already exists. Fetching UID via sign in...');
          final signInUrl = Uri.parse('http://localhost:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-key');
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
    
    if (localId != null) {
      try {
        final firestoreUrl = Uri.parse(
          'http://localhost:8080/v1/projects/$projectId/databases/(default)/documents/users/$localId'
        );
        final request = await client.patchUrl(firestoreUrl);
        request.headers.contentType = ContentType.json;
        
        final fields = {
          'firstName': {'stringValue': firstName},
          'lastName': {'stringValue': lastName},
          'email': {'stringValue': email},
          'role': {'stringValue': role},
          'userId': {'integerValue': '$userId'},
          'user_id': {'integerValue': '$userId'},
          'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()}
        };
        
        request.write(jsonEncode({
          'fields': fields,
        }));
        
        final response = await request.close();
        
        if (response.statusCode == 200) {
          print('  [Firestore] Profile document created/updated');
        } else {
          print('  [Firestore] Failed to update profile: Status ${response.statusCode}');
        }
      } catch (e) {
        print('  [Firestore] Error: $e');
      }
    }
    print('');
  }

  print('----------------------------------------');
  print('Seeding parameters...');
  print('----------------------------------------');

  // 2. Seed Parameters
  for (final param in parameters) {
    final detailId = param['param_detail_id'];
    final header = param['param_header'];
    final label = param['param_label'];
    final value = param['param_value'];
    
    try {
      final url = Uri.parse(
        'http://localhost:8080/v1/projects/$projectId/databases/(default)/documents/parameters/param_$detailId'
      );
      final request = await client.patchUrl(url);
      request.headers.contentType = ContentType.json;
      
      final fields = {
        'param_detail_id': {'integerValue': '$detailId'},
        'paramDetailId': {'integerValue': '$detailId'},
        'param_header': {'stringValue': header},
        'paramHeader': {'stringValue': header},
        'param_label': {'stringValue': label},
        'paramLabel': {'stringValue': label},
        'param_value': {'stringValue': value},
        'paramValue': {'stringValue': value},
      };
      
      request.write(jsonEncode({
        'fields': fields,
      }));
      
      final response = await request.close();
      
      if (response.statusCode == 200) {
        print('  [Parameter] Seeded: $header ($label)');
      } else {
        print('  [Parameter] Failed to seed: Status ${response.statusCode}');
      }
    } catch (e) {
      print('  [Parameter] Error: $e');
    }
  }

  client.close();
  print('\n========================================');
  print('SEEDING COMPLETED SUCCESSFULLY!');
  print('========================================');
}
