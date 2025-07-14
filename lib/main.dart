import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FirebaseAuth.instance.currentUser == null ? LoginPage() : ChatPage(),
    );
  }
}

class LoginPage extends StatelessWidget {
  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: const Text("Sign in with Google"),
          onPressed: () async {
            await signInWithGoogle();
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ChatPage()));
          },
        ),
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController controller = TextEditingController();

  void sendMessage() {
    if (controller.text.isNotEmpty) {
      FirebaseFirestore.instance.collection('messages').add({
        'text': controller.text,
        'sender': FirebaseAuth.instance.currentUser?.displayName,
        'timestamp': FieldValue.serverTimestamp(),
      });
      controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat - ${FirebaseAuth.instance.currentUser?.displayName}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              await GoogleSignIn().signOut();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginPage()));
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final docs = snapshot.data!.docs;
                return ListView(
                  children: docs.map((doc) => ListTile(
                    title: Text(doc['text']),
                    subtitle: Text(doc['sender'] ?? ''),
                  )).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: 'Enter Message'),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: sendMessage)
              ],
            ),
          ),
        ],
      ),
    );
  }
}
