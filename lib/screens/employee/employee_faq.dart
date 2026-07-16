import 'package:flutter/material.dart';
import 'package:shiftsmart/responsive.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/search.dart';
import 'package:shiftsmart/widgets/emp_slidenav.dart';
import 'package:shiftsmart/theme.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';

class EmployeeFaq extends StatefulWidget {
  const EmployeeFaq({super.key});

  @override
  State<EmployeeFaq> createState() => _EmployeeFaqState();
}

class _EmployeeFaqState extends State<EmployeeFaq> {
  final List<FaqItem> faqs = [
    FaqItem(
      question: "How do I change my password?",
      answer:
          "Go to the Settings section, enter your current password followed by the new password. Confirm the new password and then tap the 'Change Password' button to save the changes.",
    ),
    FaqItem(
      question: "How do I clock in and start my shift?",
      answer:
          "Navigate to the Jobs section and tap on the relevant shift. From the Shift View, locate your assigned shift at the bottom of the screen. Tap on the shift and then select the 'Clock In' button. Please ensure you are physically on-site to successfully clock in.",
    ),
    FaqItem(
      question: "How do I request leave?",
      answer:
          "Go to the Leave section via the bottom navigation bar and tap the 'Apply for Leave' button. Complete the required form with the necessary details and submit it. Your request will be subject to approval or rejection by your manager.",
    ),
    FaqItem(
      question: "How do I add an emergency contact?",
      answer:
          "You are required to add an emergency contact during the onboarding process. To update or view your emergency contact, navigate to the Emergency section via the side navigation menu. You can initiate an emergency call to your listed contact by tapping the SOS button.",
    ),
    FaqItem(
      question: "How do I send a message to my manager?",
      answer:
          "Open the Chat screen by tapping the chat icon in the bottom navigation bar. Tap the '+' icon to start a new conversation, select your manager's name from the list, and send your message.",
    ),
  ];

  final Map<String, bool> _isExpandedMap = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    enableFullScreen();
    for (var faq in faqs) {
      _isExpandedMap[faq.question] = false;
    }
  }

  Widget _buildExpandableFaqItem(FaqItem faq) {
    bool isExpanded = _isExpandedMap[faq.question] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: AppTheme.backgroundGradient),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpandedMap[faq.question] = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    flex: Responsive.isTablet(context) ? 2 : 1,
                    child: Text(
                      faq.question,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.remove : Icons.add,
                    color: Colors.blueAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(48, 0, 16, 16),
              child: Align(
                alignment: Alignment.topLeft,
                child: _buildAnswerContent(faq.answer),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    List<FaqItem> filteredFaqs = _searchQuery.isEmpty
        ? faqs
        : faqs
            .where((faq) =>
                faq.question
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                faq.answer.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: const EmpSidenav(
        currentScreen: 'EmployeeFAQ',
      ),
      backgroundColor: const Color(0xFF1C2230),
      appBar: Uppernavbar(showBackButton: false),
      body: Stack(
        children: [
          const Positioned.fill(child: Background()),
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Search(onQueryChanged: (query) {
                            setState(() {
                              _searchQuery = query;
                            });
                          }),
                          const SizedBox(height: 20),
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 24 : 40),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: AppTheme.backgroundGradient,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.question_answer,
                                    color: Colors.cyan, size: 28),
                                SizedBox(width: isSmallScreen ? 12 : 20),
                                Expanded(
                                  child: Text(
                                    "How can we help you?",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 16 : 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Top Questions",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          if (filteredFaqs.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  "No matching questions found",
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 16),
                                ),
                              ),
                            ),
                          ...filteredFaqs
                              .map((faq) => _buildExpandableFaqItem(faq)),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerContent(String answerText) {
    // Basic step detection based on punctuation  feel free to customize this.
    List<String> steps =
        answerText.split(RegExp(r'\.\s+')).where((s) => s.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps.map((step) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(" ",
                  style: TextStyle(color: Colors.cyanAccent, fontSize: 16)),
              Expanded(
                child: Text(
                  '${step.trim()}.',
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.5,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class FaqItem {
  final String question;
  final String answer;
  FaqItem({required this.question, required this.answer});
}
