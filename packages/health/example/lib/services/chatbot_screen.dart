import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../utils/colors1.dart';

class ChatBotScreen extends StatefulWidget {
  @override
  _ChatBotScreenState createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  String? _latestStress;
  double? _latestGpa;
  DateTime? _gpaUpdatedAt;
  bool _isLoading = true;
  bool _isSending = false;

  // Gemini API
  late final GenerativeModel _model;
  late final ChatSession _chat;

  @override
  void initState() {
    super.initState();
    // Initialize Gemini with your API key
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: 'AIzaSyDiWzexy2T-XmJbflf6Xgt68E5Ei5RBwVo', // Replace with your actual API key
    );
    _chat = _model.startChat();
    _loadUserData();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      text: "Hello! I'm your AI academic assistant. How can I help you today?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final predictionQuery = await FirebaseFirestore.instance
          .collection('user_stress_history')
          .doc(user.uid)
          .collection('predictions')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      setState(() {
        _latestStress = userDoc.data()?['latestStress'] ??
            (predictionQuery.docs.isNotEmpty ?
            predictionQuery.docs.first['stressLevel'] : null);

        _latestGpa = (userDoc.data()?['latestGpa'] ??
            (predictionQuery.docs.isNotEmpty ?
            predictionQuery.docs.first['gpa'] : null))?.toDouble();

        final updatedAt = userDoc.data()?['gpaUpdatedAt'] as Timestamp?;
        _gpaUpdatedAt = updatedAt?.toDate();
        _isLoading = false;
      });

      if (_latestStress != null || _latestGpa != null) {
        _addBotMessage(await _generateInitialAnalysis());
      }
    } catch (e) {
      print("Error loading user data: $e");
      setState(() => _isLoading = false);
      _addBotMessage("Sorry, I couldn't load your data. Please try again.");
    }
  }

  Future<String> _generateInitialAnalysis() async {
    String prompt = """
    Role: Academic counselor analyzing student data
    Student Metrics:
    ${_latestGpa != null ? '- Current GPA: ${_latestGpa!.toStringAsFixed(2)}\n' : ''}
    ${_latestStress != null ? '- Stress Level: $_latestStress\n' : ''}
    ${_gpaUpdatedAt != null ? '- Last Updated: ${DateFormat('MMM d, y').format(_gpaUpdatedAt!)}\n' : ''}

    Task:
    1. Provide a friendly greeting
    2. Give a 2-3 sentence analysis
    3. Offer 3 specific recommendations
    4. Ask what they'd like to focus on

    Style:
    - Use bullet points for recommendations
    - Keep tone empathetic and professional
    - Limit to 150 words
    """;

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? _getFallbackInitialAnalysis();
    } catch (e) {
      print("Gemini error: $e");
      return _getFallbackInitialAnalysis();
    }
  }

  String _getFallbackInitialAnalysis() {
    String message = "Based on your ";
    if (_latestGpa != null) message += "GPA (${_latestGpa!.toStringAsFixed(2)}) ";
    if (_latestStress != null) message += "and stress level ($_latestStress) ";
    message += "here are my recommendations:\n\n";

    if (_latestStress?.toLowerCase().contains('high') ?? false) {
      message += "• Practice 5-5-5 breathing (5 sec inhale, 5 hold, 5 exhale)\n"
          "• Schedule worry time (30 min/day to address concerns)\n"
          "• Try progressive muscle relaxation\n\n";
    } else {
      message += "• Maintain consistent study habits\n"
          "• Track your progress weekly\n"
          "• Balance work with self-care\n\n";
    }

    message += "What would you like to focus on today?";
    return message;
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isSending = true;
    });

    _messageController.clear();
    _scrollToBottom();

    final response = await _generateGeminiResponse(text);

    setState(() => _isSending = false);
    _addBotMessage(response);
  }

  Future<String> _generateGeminiResponse(String userInput) async {
    String prompt = """
    Role: Academic counselor in ongoing conversation
    Student Context:
    ${_latestGpa != null ? '- Current GPA: ${_latestGpa!.toStringAsFixed(2)}\n' : ''}
    ${_latestStress != null ? '- Stress Level: $_latestStress\n' : ''}

    Recent Conversation:
    ${_messages.reversed.take(3).map((m) => "${m.isUser ? 'Student' : 'Counselor'}: ${m.text}").join('\n')}

    New Message: $userInput

    Response Guidelines:
    - Be concise (1-2 short paragraphs max)
    - Provide actionable advice
    - Use bullet points if listing items
    - Maintain empathetic tone
    - Relate to academic wellness
    """;

    try {
      final response = await _chat.sendMessage(Content.text(prompt));
      return response.text ?? _getFallbackResponse(userInput);
    } catch (e) {
      print("Gemini error: $e");
      return _getFallbackResponse(userInput);
    }
  }

  String _getFallbackResponse(String userInput) {
    if (userInput.toLowerCase().contains('stress')) {
      return "For stress management:\n• Try 5-minute meditation breaks\n• Maintain regular sleep schedule\n• Practice deep breathing";
    } else if (userInput.toLowerCase().contains('gpa')) {
      return "To improve GPA:\n• Attend professor office hours\n• Form study groups\n• Focus on understanding concepts";
    }
    return "I'm here to help with academic wellness. Could you clarify your question?";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("AI Academic Assistant"),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadUserData,
            tooltip: "Refresh Data",
          ),
        ],
      ),
      body: Column(
        children: [
          if ((_latestStress != null || _latestGpa != null) && !_isLoading)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_latestStress != null)
                    _buildMetricChip("Stress", _latestStress!),
                  if (_latestGpa != null)
                    Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: _buildMetricChip("GPA", _latestGpa!.toStringAsFixed(2)),
                    ),
                  Spacer(),
                  if (_gpaUpdatedAt != null)
                    Text(
                      "Updated ${DateFormat('MMM d').format(_gpaUpdatedAt!)}",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadUserData,
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(8),
                itemCount: _messages.length + (_isSending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _messages.length) {
                    return _messages[index];
                  } else {
                    return _buildTypingIndicator();
                  }
                },
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: _handleSubmitted,
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isSending
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : Icon(Icons.send, color: Colors.white),
                    onPressed: _isSending
                        ? null
                        : () => _handleSubmitted(_messageController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            child: Icon(Icons.school, size: 18),
            radius: 16,
            backgroundColor: AppColors.primary,
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 8, height: 8),
                Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 4),
                Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 4),
                Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, String value) {
    Color color;
    IconData icon;

    if (label == "Stress") {
      if (value.toLowerCase().contains('high')) {
        color = AppColors.error;
        icon = Icons.sentiment_very_dissatisfied;
      } else if (value.toLowerCase().contains('medium')) {
        color = Colors.orange;
        icon = Icons.sentiment_neutral;
      } else {
        color = AppColors.success;
        icon = Icons.sentiment_very_satisfied;
      }
    } else {
      final numValue = double.tryParse(value) ?? 0;
      if (numValue < 2.0) {
        color = AppColors.error;
        icon = Icons.trending_down;
      } else if (numValue < 3.0) {
        color = Colors.orange;
        icon = Icons.trending_flat;
      } else {
        color = AppColors.success;
        icon = Icons.trending_up;
      }
    }

    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 16),
      label: Text(
        "$label: $value",
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
    );
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            CircleAvatar(
              child: Icon(Icons.school, size: 18),
              radius: 16,
              backgroundColor: AppColors.primary,
            ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.cardBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: !isUser ? Radius.zero : Radius.circular(12),
                      topRight: isUser ? Radius.zero : Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('h:mm a').format(timestamp),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isUser)
            CircleAvatar(
              child: Icon(Icons.person, size: 18),
              radius: 16,
              backgroundColor: AppColors.accentPurple,
            ),
        ],
      ),
    );
  }
}