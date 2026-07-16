import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftsmart/models/message.dart';
import 'package:shiftsmart/screens/chats/chat_service.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';

class Chatbox extends StatefulWidget {
  final int chatParticipantId;
  final int receiverId;
  final String receiverName;
  final String? receiverPhoto;

  const Chatbox({
    super.key,
    required this.chatParticipantId,
    required this.receiverId,
    required this.receiverName,
    this.receiverPhoto,
  });

  @override
  State<Chatbox> createState() => _ChatboxState();
}

class _ChatboxState extends State<Chatbox> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int _userId = 0;
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _hasScrolledToLatest = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _getUserId();
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _fetchMessages(scrollOnNewMessage: true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('employeeId') ?? prefs.getInt('userId') ?? 0;
    });
    _fetchMessages(forceScrollToLatest: true);
  }

  Future<void> _fetchMessages({
    bool forceScrollToLatest = false,
    bool scrollOnNewMessage = false,
  }) async {
    final previousLatest = _latestMessageKey(_messages);
    final msgs = await _chatService.fetchMessages(widget.chatParticipantId);
    if (!mounted) return;

    final latest = _latestMessageKey(msgs);
    final shouldScrollToLatest = msgs.isNotEmpty &&
        (forceScrollToLatest ||
            !_hasScrolledToLatest ||
            (scrollOnNewMessage && latest != previousLatest));
    final shouldAnimate = _hasScrolledToLatest || forceScrollToLatest;

    setState(() {
      _messages = msgs;
      _isLoading = false;
    });

    if (shouldScrollToLatest) {
      _hasScrolledToLatest = true;
      _scrollToLatest(animated: shouldAnimate);
    }
  }

  String? _latestMessageKey(List<Message> messages) {
    if (messages.isEmpty) return null;
    final msg = messages.last;
    return '${msg.messageId}|${msg.createdAt.microsecondsSinceEpoch}|${msg.senderId}|${msg.text}';
  }

  void _scrollToLatest({bool animated = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_scrollController.hasClients) return;

      Future<void> move() async {
        if (!_scrollController.hasClients) return;
        final target = _scrollController.position.maxScrollExtent;
        if (animated) {
          await _scrollController.animateTo(
            target,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(target);
        }
      }

      await move();
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      await move();
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final text = _messageController.text;
    _messageController.clear();

    final success = await _chatService.sendMessage(
      chatParticipantId: widget.chatParticipantId,
      senderId: _userId,
      receiverId: widget.receiverId,
      text: text,
    );

    if (success) {
      await _fetchMessages(forceScrollToLatest: true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send message")),
      );
    }
  }

  String _formatTime(DateTime dt) {
    final localTime = dt.toLocal();
    final hour = localTime.hour > 12
        ? localTime.hour - 12
        : (localTime.hour == 0 ? 12 : localTime.hour);
    final minute = localTime.minute.toString().padLeft(2, '0');
    final period = localTime.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }

  String _formatDateLabel(DateTime dt) {
    final messageDate = DateUtils.dateOnly(dt.toLocal());
    final today = DateUtils.dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    if (messageDate == today) return "Today";
    if (messageDate == yesterday) return "Yesterday";
    return DateFormat('MMM d, yyyy').format(messageDate);
  }

  bool _shouldShowDateHeader(int index) {
    if (index == 0) return true;

    final currentDate =
        DateUtils.dateOnly(_messages[index].createdAt.toLocal());
    final previousDate =
        DateUtils.dateOnly(_messages[index - 1].createdAt.toLocal());
    return currentDate != previousDate;
  }

  Widget _buildDateHeader(DateTime dateTime) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2F45),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          _formatDateLabel(dateTime),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C2230),
      appBar: Uppernavbar(
        showBackButton: true,
        title: widget.receiverName,
        profileImageUrl: widget.receiverPhoto,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          "No messages yet",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg.senderId == _userId;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_shouldShowDateHeader(index))
                                _buildDateHeader(msg.createdAt),
                              Align(
                                alignment: isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: isMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                                0.75,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: isMe
                                            ? const LinearGradient(
                                                colors: [
                                                  Color(0xFF3B82F6),
                                                  Color(0xFF2563EB),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : null,
                                        color: isMe
                                            ? null
                                            : const Color(0xFF2A2F45),
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(16),
                                          topRight: const Radius.circular(16),
                                          bottomLeft: isMe
                                              ? const Radius.circular(16)
                                              : Radius.zero,
                                          bottomRight: isMe
                                              ? Radius.zero
                                              : const Radius.circular(16),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        msg.text,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8,
                                        left: 4,
                                        right: 4,
                                      ),
                                      child: Text(
                                        _formatTime(msg.createdAt),
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF2A2F45),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blueAccent,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
