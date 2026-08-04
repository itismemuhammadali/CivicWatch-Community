import 'dart:convert';
import 'dart:io';

const String apiKey = 'AIzaSyAO-iIxJvS_rVmR6TsOmCbIGC42usT5qm8';
const String projectId = 'commctv-f2b45';

Future<void> main() async {
  final client = HttpClient();
  try {
    // 1. Sign in
    final signInUrl = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey');
    final signInReq = await client.postUrl(signInUrl);
    signInReq.headers.contentType = ContentType.json;
    signInReq.write(jsonEncode({
      'email': 'admin@cctv.app',
      'password': 'admin@123',
      'returnSecureToken': true,
    }));
    
    final signInResp = await signInReq.close();
    final signInBody = await signInResp.transform(utf8.decoder).join();
    final signInData = jsonDecode(signInBody);
    
    if (signInResp.statusCode != 200) {
      print('Sign in failed: $signInBody');
      return;
    }
    
    final idToken = signInData['idToken'];
    
    // 2. Fetch users
    final firestoreUrl = Uri.parse('https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users');
    final req = await client.getUrl(firestoreUrl);
    req.headers.set('Authorization', 'Bearer $idToken');
    final resp = await req.close();
    final body = await resp.transform(utf8.decoder).join();
    
    print('--- USERS ---');
    print(body);
    
    // 3. Fetch follows
    final followsUrl = Uri.parse('https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/follows');
    final req2 = await client.getUrl(followsUrl);
    req2.headers.set('Authorization', 'Bearer $idToken');
    final resp2 = await req2.close();
    final body2 = await resp2.transform(utf8.decoder).join();
    
    print('--- FOLLOWS ---');
    print(body2);

  } catch (e) {
    print('Error: $e');
  }
}
