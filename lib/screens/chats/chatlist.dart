import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Keep for type safety if needed elsewhere
import 'package:shiftsmart/models/chat_list_item.dart';
import 'package:shiftsmart/models/search_employee.dart'; // <--- Import New Model
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/gradienthorizontal.dart';
import 'package:shiftsmart/widgets/sidenav.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';
import 'package:shiftsmart/screens/chats/chatbox.dart';
import 'package:shiftsmart/screens/chats/chat_service.dart';

class Chatlist extends StatefulWidget {
  final bool isInsideBottomNav;
  const Chatlist({super.key, this.isInsideBottomNav = false});

  @override
  State<Chatlist> createState() => _ChatlistState();
}

class _ChatlistState extends State<Chatlist> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();
  bool _isLoading = true;
  bool _isRefreshing = false;
  int _userId = 0;
  int _newMessageTotal = 0;

  List<ChatListItem> filteredChats = [];
  Map<int, int> _unreadCounts = {};

  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _getUserId();
  }

  Future<void> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('employeeId') ?? prefs.getInt('userId');
    if (id != null) {
      setState(() {
        _userId = id;
      });
      await _fetchChats();
    }
  }

  List<ChatListItem> _visibleChats(List<ChatListItem> chats) {
    return chats.where((chat) => !_isStarterMessage(chat.lastMessage)).toList();
  }

  bool _isStarterMessage(String value) {
    return value.trim().toLowerCase() == 'started a new chat';
  }

  Future<List<ChatListItem>> _fetchChats() async {
    try {
      final chatList = await _chatService.fetchChatList();
      final visibleChats = _visibleChats(chatList);
      final unreadCounts = await _loadUnreadCounts(visibleChats);
      final totalUnread =
          unreadCounts.values.fold<int>(0, (total, count) => total + count);

      if (mounted) {
        setState(() {
          filteredChats = visibleChats;
          _unreadCounts = unreadCounts;
          _newMessageTotal = totalUnread;
          _isLoading = false;
        });
      }
      return chatList;
    } catch (e) {
      debugPrint("Error loading chats: $e");
      if (mounted) setState(() => _isLoading = false);
      return const [];
    }
  }

  Future<void> _refreshChats() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    await _fetchChats();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  Future<Map<int, int>> _loadUnreadCounts(List<ChatListItem> chats) async {
    if (_userId == 0 || chats.isEmpty) return {};

    final prefs = await SharedPreferences.getInstance();
    final entries = await Future.wait(chats.map((chat) async {
      final seenAt = prefs.getInt('chat_seen_${_userId}_${chat.chatId}') ?? 0;

      try {
        final messages = await _chatService.fetchMessages(chat.chatId);
        final unreadCount = messages.where((message) {
          if (_isStarterMessage(message.text)) return false;
          return message.senderId != _userId &&
              message.createdAt.microsecondsSinceEpoch > seenAt;
        }).length;

        return MapEntry(chat.chatId, unreadCount);
      } catch (e) {
        debugPrint("Error loading unread count for chat ${chat.chatId}: $e");
        return MapEntry(chat.chatId, 0);
      }
    }));

    return Map<int, int>.fromEntries(entries);
  }

  String _formatLastMessageTime(DateTime? dt) {
    if (dt == null) return "";

    final local = dt.toLocal();
    final messageDate = DateUtils.dateOnly(local);
    final today = DateUtils.dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    if (messageDate == today) return DateFormat('h:mm a').format(local);
    if (messageDate == yesterday) return "Yesterday";
    return DateFormat('d/M/yyyy').format(local);
  }

  Widget _buildNewMessageBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF163A5A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF34C8E8), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.mark_chat_unread_rounded,
                color: Color(0xFF34C8E8), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _newMessageTotal == 1
                    ? '1 new message'
                    : '$_newMessageTotal new messages',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: _isRefreshing ? null : _refreshChats,
              child: Text(
                _isRefreshing ? 'Refreshing...' : 'Refresh',
                style: const TextStyle(
                  color: Color(0xFF34C8E8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _SearchUserDialog(
        currentUserId: _userId,
        onUserSelected: (searchEmp) {
          Navigator.pop(context);
          _createAndOpenChatFromSearch(searchEmp);
        },
      ),
    );
  }

  // --- Modified Create Chat Function for Search Results ---
  Future<void> _createAndOpenChatFromSearch(SearchEmployee receiver) async {
    if (receiver.employeeId == _userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot chat with yourself.")),
      );
      return;
    }

    final chatList = await _fetchChats();
    var chatParticipantId = 0;
    for (final chat in chatList) {
      if (chat.partnerId == receiver.employeeId && chat.chatId > 0) {
        chatParticipantId = chat.chatId;
        break;
      }
    }

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Chatbox(
          chatParticipantId: chatParticipantId,
          receiverId: receiver.employeeId,
          receiverName: receiver.firstName,
          receiverPhoto: receiver.profilePicture,
        ),
      ),
    );
    _fetchChats();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Stack(
      children: [
        const Background(),
        Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(180, 42, 50, 67),
                      Color.fromARGB(180, 34, 40, 52)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("Chats",
                          style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Refresh chats',
                          onPressed: _isRefreshing ? null : _refreshChats,
                          icon: _isRefreshing
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Color(0xFF34C8E8),
                                  ),
                                )
                              : const Icon(
                                  Icons.refresh_rounded,
                                  color: Color(0xFF34C8E8),
                                  size: 28,
                                ),
                        ),
                        IconButton(
                          tooltip: 'Start chat',
                          onPressed: () => showSearchDialog(context),
                          icon: const Icon(
                            Icons.add_comment_rounded,
                            color: Colors.blue,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_newMessageTotal > 0) _buildNewMessageBanner(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      key: _refreshKey,
                      onRefresh: _refreshChats,
                      child: filteredChats.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              children: const [
                                SizedBox(height: 180),
                                Center(
                                  child: Text(
                                    "No chats yet.",
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: filteredChats.length,
                              itemBuilder: (context, index) {
                                final chat = filteredChats[index];
                                final unreadCount =
                                    _unreadCounts[chat.chatId] ?? 0;
                                final hasUnread = unreadCount > 0;

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6.0),
                                  child: GestureDetector(
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Chatbox(
                                            chatParticipantId: chat.chatId,
                                            receiverId: chat.partnerId,
                                            receiverName: chat.partnerName,
                                            receiverPhoto: chat
                                                .partnerPhoto, // Added receiverPhoto
                                          ),
                                        ),
                                      );
                                      _fetchChats();
                                    },
                                    child: Gradienthorizontal(
                                      width: double.infinity,
                                      height: 80,
                                      child: Row(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 16.0, right: 12.0),
                                            child: CircleAvatar(
                                              backgroundColor: Colors.white24,
                                              backgroundImage:
                                                  (chat.partnerPhoto != null &&
                                                          chat.partnerPhoto!
                                                              .isNotEmpty)
                                                      ? NetworkImage(
                                                          chat.partnerPhoto!)
                                                      : null,
                                              child: (chat.partnerPhoto == null)
                                                  ? const Icon(Icons.person,
                                                      color: Colors.white)
                                                  : null,
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        chat.partnerName,
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: hasUnread
                                                              ? FontWeight.w800
                                                              : FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              right: 16.0),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .end,
                                                        children: [
                                                          Text(
                                                            _formatLastMessageTime(
                                                                chat.lastMessageTime),
                                                            style: TextStyle(
                                                                color: hasUnread
                                                                    ? const Color(
                                                                        0xFF34C8E8)
                                                                    : Colors
                                                                        .white54,
                                                                fontSize: 12,
                                                                fontWeight: hasUnread
                                                                    ? FontWeight
                                                                        .bold
                                                                    : FontWeight
                                                                        .normal),
                                                          ),
                                                          if (hasUnread)
                                                            Container(
                                                              margin:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      top: 6),
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                horizontal: 7,
                                                                vertical: 2,
                                                              ),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: const Color(
                                                                    0xFF34C8E8),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            999),
                                                              ),
                                                              child: Text(
                                                                unreadCount > 99
                                                                    ? '99+'
                                                                    : unreadCount
                                                                        .toString(),
                                                                style:
                                                                    const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 11,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  chat.lastMessage.isNotEmpty
                                                      ? chat.lastMessage
                                                      : "No messages yet",
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: hasUnread
                                                        ? Colors.white
                                                        : Colors.white70,
                                                    fontSize: 13,
                                                    fontWeight: hasUnread
                                                        ? FontWeight.w700
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ],
    );

    if (widget.isInsideBottomNav) {
      return content;
    } else {
      return Scaffold(
        drawer: const Sidenav(currentScreen: 'Chat'),
        appBar: const Uppernavbar(),
        backgroundColor: const Color(0xFF1C2230),
        body: content,
      );
    }
  }
}

// --- UPDATED SEARCH DIALOG (Uses SearchEmployee) ---
class _SearchUserDialog extends StatefulWidget {
  final int currentUserId;
  final Function(SearchEmployee) onUserSelected; // Type Updated
  const _SearchUserDialog(
      {required this.onUserSelected, required this.currentUserId});

  @override
  State<_SearchUserDialog> createState() => _SearchUserDialogState();
}

class _SearchUserDialogState extends State<_SearchUserDialog> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();

  List<SearchEmployee> _allEmployees = [];
  List<SearchEmployee> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    if (!mounted) return;
    setState(() => _isSearching = true);

    try {
      final results = await _chatService.fetchDefaultSearchEmployees();

      if (mounted) {
        setState(() {
          _allEmployees = results
              .where((emp) => emp.employeeId != widget.currentUserId)
              .toList();
          _searchResults = List.of(_allEmployees);
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading employees in dialog: $e");
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _performSearch(String query) async {
    final keyword = query.trim().toLowerCase();
    if (keyword.isEmpty) {
      if (!mounted) return;
      setState(() => _searchResults = List.of(_allEmployees));
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = _allEmployees.where((emp) {
        final fullName = "${emp.firstName} ${emp.lastName}".toLowerCase();
        final email = (emp.email ?? "").toLowerCase();
        final role = emp.role.toLowerCase();
        return fullName.contains(keyword) ||
            email.contains(keyword) ||
            role.contains(keyword);
      }).toList();
    });

    try {
      final results = await _chatService.searchEmployees(keyword);
      if (!mounted || _searchController.text.trim().toLowerCase() != keyword) {
        return;
      }

      setState(() {
        _searchResults = results
            .where((emp) => emp.employeeId != widget.currentUserId)
            .toList();
        _isSearching = false;
      });
    } catch (e) {
      debugPrint("Error searching employees in dialog: $e");
      if (!mounted) return;
      setState(() {
        _searchResults = _allEmployees.where((emp) {
          final fullName = "${emp.firstName} ${emp.lastName}".toLowerCase();
          final email = (emp.email ?? "").toLowerCase();
          final role = emp.role.toLowerCase();
          return fullName.contains(keyword) ||
              email.contains(keyword) ||
              role.contains(keyword);
        }).toList();
        _isSearching = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    final keyword = query.trim().toLowerCase();

    if (keyword.isEmpty) {
      _debounce?.cancel();
      setState(() {
        _isSearching = false;
        _searchResults = List.of(_allEmployees);
      });
      return;
    }

    setState(() {
      _searchResults = _allEmployees.where((emp) {
        final fullName = "${emp.firstName} ${emp.lastName}".toLowerCase();
        final email = (emp.email ?? "").toLowerCase();
        final role = emp.role.toLowerCase();
        return fullName.contains(keyword) ||
            email.contains(keyword) ||
            role.contains(keyword);
      }).toList();
    });

    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _performSearch(keyword),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2A2F45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 500,
        child: Column(
          children: [
            const Text(
              "Find Employee",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Type name...",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.black26,
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isSearching && _searchResults.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? const Center(
                          child: Text("No users found",
                              style: TextStyle(color: Colors.white38)))
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final emp = _searchResults[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blueAccent,
                                backgroundImage: (emp.profilePicture != null &&
                                        emp.profilePicture!.isNotEmpty)
                                    ? NetworkImage(emp.profilePicture!)
                                    : null,
                                child: (emp.profilePicture == null ||
                                        emp.profilePicture!.isEmpty)
                                    ? const Icon(Icons.person,
                                        color: Colors.white)
                                    : null,
                              ),
                              title: Text("${emp.firstName} ${emp.lastName}",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  "${emp.role} • ${emp.email ?? "No Email"}",
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 12)),
                              onTap: () => widget.onUserSelected(emp),
                            );
                          },
                        ),
            ),
            // ========== CHANGED CODE START ==========
            // UPDATED: Styled Cancel button with gradient and proper sizing
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF3B82F6), // Blue gradient start
                      Color(0xFF2563EB), // Blue gradient end
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            // ========== CHANGED CODE END ==========
          ],
        ),
      ),
    );
  }
}
