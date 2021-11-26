import 'package:flutter/material.dart';
import 'package:chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
final _firestore = FirebaseFirestore.instance;

late User loggedInUser ;
class ChatScreen extends StatefulWidget {
  static String id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;

  //xoa text khi an send
  final messageTextController = TextEditingController();
  late String messsageText;
  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }
  //ham check thu coi co user nao vao khon
  void getCurrentUser()async{
    try{
      final user = await _auth.currentUser;
      if(user!=null){
        loggedInUser = user;
        print(loggedInUser.email);
      }
    }catch(e){
      print(e);
    }
  }
  void messagesStream()async{
    await for(var snapshot in _firestore.collection('messages').snapshots()){
      for(var message in snapshot.docs){
        print(message.data());
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                messagesStream();
                // _auth.signOut();
                // Navigator.pop(context);
              }),
        ],
        title: Text('💬 My Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MessagesStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController ,
                      onChanged: (value) {
                        messsageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      messageTextController.clear();
                      //mess+email
                      _firestore.collection('messages').add({
                        'text':messsageText,
                        'sender':loggedInUser.email,
                        'time': DateTime.now(),
                      });
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
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


class MessagesStream extends StatelessWidget {
  const MessagesStream({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('messages').orderBy('time').snapshots(),
        builder:(context, snapshot){
          List<Widget> messageWidgets = [];
          if(!snapshot.hasData){
            return Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.tealAccent,
              ),
            );
          }
          final messages = snapshot.data!.docs.reversed;
          for(var message in messages){
            final messageData = message.data();
            final messageText = messageData['text'];
            final messageSender = messageData['sender'];
            final messageTime = messageData['time'];

            final currentUser = loggedInUser.email;
            if(currentUser==messageSender){
              //Tin nhan tu nguoi dang nhap

            }

            final messageBubble = MessageBubble(
                sender: messageSender,
                text: messageText,
                isMe: currentUser==messageSender,
            );
            messageWidgets.add(messageBubble);
          }
          return Expanded(
            child: ListView(
              reverse: true,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              children: messageWidgets,
            ),
          );
        }
    );
  }
}



class MessageBubble extends StatelessWidget {
  MessageBubble({required this.sender, required this.text, required this.isMe,});
  String sender;
  String text;
  bool isMe;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:isMe? CrossAxisAlignment.end:CrossAxisAlignment.start,
        children: [
          Text(sender,style: TextStyle(
            fontSize: 11.0,
            color: Colors.white30,
          ),),
          SizedBox(height: 5.0,),
          Material(
            borderRadius: isMe? BorderRadius.only(topLeft: Radius.circular(30.0), bottomLeft: Radius.circular(30.0),bottomRight: Radius.circular(30.0)):
            BorderRadius.only(topRight: Radius.circular(30.0), bottomLeft: Radius.circular(30.0),bottomRight: Radius.circular(30.0))
            ,
            color: isMe? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical:10.0, horizontal: 20.0 ),
              child: Text(
                '$text',
                style: TextStyle(
                  fontSize: 20.0,
                  color: isMe?Colors.white:Colors.grey,
                ),
              ),
            ),
          ),
          SizedBox(height: 5.0,),
          // Text(time.toString(),style: TextStyle(
          //   fontSize: 11.0,
          //   color: Colors.white30,
          // ),),
        ],
      ),
    );
  }
}
