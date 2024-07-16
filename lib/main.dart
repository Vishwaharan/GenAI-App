import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

const String _apiKey = "YOUR_API_KEY";

void main() {
  runApp(const GenerativeAISample());
}

class GenerativeAISample extends StatelessWidget {
  const GenerativeAISample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GenAI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.blue,
          primaryContainer: Colors.lightBlue,
          onSurfaceVariant: Colors.grey.shade200,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ChatScreen(title: 'GenAI'),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.title});

  final String title;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

File? _profileImage;

class _ChatScreenState extends State<ChatScreen> {
  final GlobalKey<_ChatWidgetState> _chatWidgetKey =
      GlobalKey<_ChatWidgetState>();
  List<Chat> _chats = [];
  Chat? _currentChat;

  String userName = "Username";

  @override
  void initState() {
    super.initState();
    _currentChat = Chat('Chat 1');
    _chats.add(_currentChat!);
  }

  Future<void> _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        actions: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _clearChats,
              tooltip: 'Clear Chats',
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addNewChat,
              tooltip: 'Add New Chat',
              color: Colors.greenAccent,
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.cyanAccent[50],
        elevation: 16.0,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.blueAccent),
              currentAccountPictureSize: Size(100, 88),
              currentAccountPicture: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                backgroundImage:
                    _profileImage != null ? FileImage(_profileImage!) : null,
                child: _profileImage == null
                    ? Text(
                        "P",
                        style: TextStyle(fontSize: 50.0, color: Colors.black),
                      )
                    : null,
              ),
              accountName: Text(""),
              accountEmail: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Text(
                      userName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _editProfile,
                    child: Text(
                      "Edit Profile",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              "Chats",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                letterSpacing: 1.2,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _chats.length,
                itemBuilder: (context, index) {
                  Color chatColor = index.isEven ? Colors.blue : Colors.green;
                  IconData chatIcon =
                      index.isEven ? Icons.chat_bubble : Icons.message;

                  bool isSelected = _currentChat == _chats[index];

                  return Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 3.0, horizontal: 8.0),
                    decoration: BoxDecoration(
                      border: isSelected
                          ? Border.all(color: Colors.black)
                          : Border.all(color: Colors.white),
                      color: isSelected
                          ? Colors.cyanAccent.withOpacity(0.3)
                          : chatColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(8.0),
                      leading: CircleAvatar(
                        backgroundColor: chatColor,
                        child: Icon(chatIcon, color: Colors.white),
                      ),
                      title: Text(
                        _chats[index].name,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            int? previousIndex = index > 0 ? index - 1 : null;
                            _chats.removeAt(index);
                            if (_chats.isNotEmpty) {
                              _currentChat = previousIndex != null
                                  ? _chats[previousIndex]
                                  : _chats[0];
                            } else {
                              _currentChat = null;
                            }
                          });
                        },
                      ),
                      onTap: () {
                        setState(() {
                          _currentChat = _chats[index];
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: _currentChat != null
          ? ChatWidget(
              key: _chatWidgetKey,
              apiKey: _apiKey,
              currentChat: _currentChat!,
            )
          : const Center(child: Text('No chats available.')),
    );
  }

  void _editProfile() {
    TextEditingController _nameController =
        TextEditingController(text: userName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Profile"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Name",
                  hintText: "Enter your new name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.blueGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.blue, width: 2.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.white, width: 1.5),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 15.0, horizontal: 12.0),
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  labelStyle: TextStyle(color: Colors.black),
                ),
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _pickProfileImage,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue[500],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding: EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 15.0), // Padding
                ),
                child: Text(
                  "Change Profile Image",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  userName = _nameController.text;
                });
                Navigator.of(context).pop();
              },
              child: Text("Save"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
              style: ButtonStyle(),
            ),
          ],
        );
      },
    );
  }

  void _clearChats() {
    _currentChat?.messages.clear();
    setState(() {});
  }

  void _addNewChat() {
    final chatName = 'Chat ${_chats.length + 1}';
    setState(() {
      final newChat = Chat(chatName);
      _chats.add(newChat);
      _currentChat = newChat;
    });
  }
}

class Chat {
  final String name;
  final List<({Image? image, String? text, bool fromUser})> messages;

  Chat(this.name) : messages = [];
}

class ChatWidget extends StatefulWidget {
  const ChatWidget({
    required this.apiKey,
    required this.currentChat,
    super.key,
  });

  final String apiKey;
  final Chat currentChat;

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  late final GenerativeModel _model;
  late final ChatSession _chat;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();
  bool _loading = false;
  bool _newMessageReceived = false;
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: widget.apiKey,
    );
    _chat = _model.startChat();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  itemCount: widget.currentChat.messages.length,
                  itemBuilder: (context, idx) {
                    final content = widget.currentChat.messages[idx];
                    return MessageWidget(
                      text: content.text,
                      image: content.image,
                      isFromUser: content.fromUser,
                    );
                  },
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue[100],
                    child: Icon(Icons.image, color: Colors.blue, size: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      autofocus: true,
                      focusNode: _textFieldFocus,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                      ),
                      controller: _textController,
                      onSubmitted: _sendChatMessage,
                      onTap: () {
                        setState(() {
                          _newMessageReceived = false; // Reset when typing
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _startListening,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue[100],
                    child: Icon(
                      _isListening ? Icons.stop : Icons.mic,
                      color: _isListening ? Colors.red : Colors.blue,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: !_loading
                      ? () => _sendChatMessage(_textController.text)
                      : null,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: !_loading
                        ? Theme.of(context).colorScheme.primary
                        : Colors.red,
                    child: _loading
                        ? Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          )
                        : Icon(Icons.send, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _sendImagePrompt(image);
    }
  }

  Future<void> _startListening() async {
    if (!_isListening) {
      _isListening = await _speech.initialize();
      if (_isListening) {
        _speech.listen(onResult: (result) {
          _textController.text = result.recognizedWords;
        });
      }
    } else {
      _speech.stop();
      _isListening = false;
    }
    setState(() {});
  }

  Future<void> _sendChatMessage(String message) async {
    if (message.isEmpty) return;

    setState(() {
      widget.currentChat.messages
          .add((image: null, text: message, fromUser: true));
      widget.currentChat.messages
          .add((image: null, text: '...', fromUser: false));
      _loading = true;
      _newMessageReceived = false;
    });

    try {
      final response = await _chat.sendMessage(Content.text(message));
      final text = response.text;

      setState(() {
        _loading = false;
        widget.currentChat.messages.removeLast();
        widget.currentChat.messages
            .add((image: null, text: text, fromUser: false));
        _newMessageReceived = true;
      });

      _scrollToBottom();
    } catch (e) {
      _showError(e.toString());
      setState(() {
        _loading = false;
      });
    } finally {
      _textController.clear();
    }
  }

  Future<void> _sendImagePrompt(XFile imageFile) async {
    setState(() {
      widget.currentChat.messages.add((
        image: Image.file(File(imageFile.path)),
        text: 'Image sent!',
        fromUser: true,
      ));
      widget.currentChat.messages.add((
        image: null,
        text: '...',
        fromUser: false,
      ));
      _loading = true;
      _newMessageReceived = false;
    });

    try {
      final bytes = await imageFile.readAsBytes();
      final content = [
        Content.multi([
          TextPart('Here is an image!'),
          DataPart('image/jpeg', bytes),
        ])
      ];

      var response = await _model.generateContent(content);
      var text = response.text;

      setState(() {
        _loading = false; // Reset loading state
        widget.currentChat.messages.removeLast();
        widget.currentChat.messages
            .add((image: null, text: text, fromUser: false));
        _newMessageReceived = true;
      });

      _scrollToBottom();
    } catch (e) {
      _showError(e.toString());
      setState(() {
        _loading = false;
      });
    } finally {
      _textController.clear();
    }
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Something went wrong'),
          content: SingleChildScrollView(
            child: SelectableText(message),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class MessageWidget extends StatelessWidget {
  const MessageWidget({
    super.key,
    this.image,
    this.text,
    required this.isFromUser,
  });

  final Image? image;
  final String? text;
  final bool isFromUser;

  @override
  Widget build(BuildContext context) {
    final String aiImagePath = 'assets/images/ai.jpeg';

    return Row(
      mainAxisAlignment:
          isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isFromUser)
          CircleAvatar(
            backgroundColor: Colors.blue,
            backgroundImage: AssetImage(aiImagePath),
          ),
        const SizedBox(width: 8),
        Flexible(
          child: Card(
            color: isFromUser
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (text != null && text!.isNotEmpty)
                    SelectableText(
                      text!,
                      style: TextStyle(
                        color: isFromUser ? Colors.white : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (image != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: image!,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (isFromUser) const SizedBox(width: 8),
        if (isFromUser)
          CircleAvatar(
            backgroundColor: Colors.white,
            backgroundImage:
                _profileImage != null ? FileImage(_profileImage!) : null,
            child: _profileImage == null
                ? Text(
                    'U',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
      ],
    );
  }
}
