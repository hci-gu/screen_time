import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_time/theme/app_theme.dart';
import 'package:html/parser.dart' as html_parser;
import '../api.dart';
import '../providers/user_provider.dart';
import '../widgets/question_widget.dart';

class NewEntryPage extends ConsumerStatefulWidget {
  final Questionnaire questionnaire;
  final DateTime? initialDate;
  final int? dayNumber;

  const NewEntryPage({
    super.key,
    required this.questionnaire,
    this.initialDate,
    this.dayNumber,
  });

  @override
  ConsumerState<NewEntryPage> createState() => _NewEntryPageState();
}

class _NewEntryPageState extends ConsumerState<NewEntryPage>
    with SingleTickerProviderStateMixin {
  final Map<String, dynamic> _answers = {};
  bool _showLastDayQuestions = false;
  DateTime? _userStartDate;
  bool _checkingStartDate = true;
  bool _isSubmitting = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initStartDateCheck();
    if (widget.initialDate != null) {
      final dateQuestion = widget.questionnaire.questions.firstWhere(
        (q) => q.type == 'date' || q.name.toLowerCase().contains('date'),
        orElse: () => Question(
          id: '',
          name: '',
          text: '',
          type: '',
          showWhenParentIs: null,
          options: [],
          subQuestions: [],
          lastDay: false,
        ),
      );
      if (dateQuestion.id.isNotEmpty) {
        _answers[dateQuestion.id] = widget.initialDate!.toIso8601String();
      }
    }
  }

  Future<void> _initStartDateCheck() async {
    final userState = ref.read(userIdProvider);
    final userId = userState.userId;
    if (userId != null && userId.isNotEmpty) {
      _userStartDate = await fetchUserStartDate(userId);
    }

    if (widget.dayNumber != null && widget.dayNumber == 10) {
      setState(() {
        _showLastDayQuestions = true;
      });
    } else if (_userStartDate != null && widget.dayNumber == null) {
      final now = DateTime.now();
      final diff = now.difference(_userStartDate!);
      if (diff.inDays >= 9) {
        setState(() {
          _showLastDayQuestions = true;
        });
      }
    }

    setState(() {
      _checkingStartDate = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onAnswered(String questionId, dynamic value) {
    setState(() {
      _answers[questionId] = value;
    });
  }

  List<Question> _getRegularQuestions() {
    return _filterQuestions(widget.questionnaire.questions,
        includeLastDay: false);
  }

  List<Question> _getLastDayQuestions() {
    List<Question> lastDayQuestions = [];
    void collectLastDay(List<Question> questions) {
      for (final q in questions) {
        if (q.lastDay) {
          lastDayQuestions.add(q);
        }
        collectLastDay(q.subQuestions);
      }
    }

    collectLastDay(widget.questionnaire.questions);
    return lastDayQuestions;
  }

  bool _hasLastDayQuestions() {
    return _getLastDayQuestions().isNotEmpty;
  }

  Map<String, dynamic> _collectAllAnswersForSubmit() {
    final Map<String, dynamic> allAnswers = {};
    void collect(Question question) {
      if (_answers.containsKey(question.id)) {
        final answer = _answers[question.id];
        final plainText = html_parser.parse(question.text).body?.text ?? '';
        final Map<String, dynamic> answerMap = {
          'questionName': question.name,
          'questionText': plainText,
        };
        if ((question.type == 'yesNo' || question.type == 'singleChoice') &&
            answer != null) {
          final selectedOption = question.options.firstWhere(
            (opt) => opt.id == answer.toString(),
            orElse: () => AnswerOption(id: '', displayText: '', valueText: ''),
          );
          answerMap['value'] = answer;
          answerMap['valueText'] = selectedOption.valueText ?? '';
        } else if (question.type == 'slider' && answer != null) {
          final selectedOption = question.options.firstWhere(
            (opt) =>
                opt.valueNumber != null &&
                opt.valueNumber.toString() == answer.toString(),
            orElse: () => AnswerOption(
                id: '', displayText: '', valueText: '', valueNumber: null),
          );
          answerMap['value'] = answer;
          answerMap['valueText'] =
              selectedOption.valueText ?? answer.toString();
        } else {
          answerMap['value'] = answer;
        }
        allAnswers[question.id] = answerMap;
      }
      for (final sub in question.subQuestions) {
        collect(sub);
      }
    }

    for (final q in widget.questionnaire.questions) {
      collect(q);
    }
    return allAnswers;
  }

  Future<void> _submitForm() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    final userState = ref.read(userIdProvider);
    final userId = userState.userId;
    if (userId == null || userId.isEmpty) {
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fel: Kunde inte hitta användar-ID.')),
        );
      }
      return;
    }

    final allAnswers = _collectAllAnswersForSubmit();

    try {
      bool success = await answerQuestionnaire(
        userId,
        widget.questionnaire.id,
        allAnswers,
        customDate: widget.initialDate,
      );

      setState(() {
        _isSubmitting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(success ? 'Svar sparade!' : 'Kunde inte spara svar.')),
        );
        if (success) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ett fel uppstod vid sparning.')),
        );
      }
    }
  }

  List<Question> _filterQuestions(List<Question> questions,
      {bool includeLastDay = false}) {
    List<Question> filtered = [];
    for (final q in questions) {
      if (!q.lastDay || includeLastDay) {
        final filteredSubs =
            _filterQuestions(q.subQuestions, includeLastDay: includeLastDay);
        filtered.add(
          Question(
              id: q.id,
              name: q.name,
              text: q.text,
              type: q.type,
              showWhenParentIs: q.showWhenParentIs,
              options: q.options,
              subQuestions: filteredSubs,
              lastDay: q.lastDay),
        );
      }
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingStartDate) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Nytt dagboksinlägg',
              style: TextStyle(color: AppTheme.primary)),
          backgroundColor: AppTheme.background,
          surfaceTintColor: AppTheme.background,
          elevation: 1,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final regularQuestions = _getRegularQuestions();
    final lastDayQuestions = _getLastDayQuestions();
    final hasLastDay = _hasLastDayQuestions() && _showLastDayQuestions;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Nytt dagboksinlägg',
            style: TextStyle(color: AppTheme.primary)),
        backgroundColor: AppTheme.background,
        surfaceTintColor: AppTheme.background,
        elevation: 1,
        bottom: hasLastDay
            ? TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor:
                    AppTheme.primary.withAlpha((0.6 * 255).round()),
                indicatorColor: AppTheme.accent,
                tabs: const [
                  Tab(text: 'Dagliga frågor'),
                  Tab(text: 'Avslutande frågor'),
                ],
              )
            : null,
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: hasLastDay
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    _buildQuestionsList(regularQuestions,
                        isRegularTab: true, isDay10: hasLastDay),
                    _buildQuestionsList(lastDayQuestions,
                        isRegularTab: false, isDay10: hasLastDay),
                  ],
                )
              : _buildQuestionsList(regularQuestions,
                  isRegularTab: false, isDay10: false),
        ),
      ),
    );
  }

  Widget _buildQuestionsList(List<Question> questions,
      {required bool isRegularTab, required bool isDay10}) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: questions.length + 1,
      itemBuilder: (context, index) {
        if (index < questions.length) {
          final question = questions[index];
          return QuestionWidget(
            question: question,
            onAnswered: _onAnswered,
            answers: _answers,
          );
        } else {
          if (isDay10 && isRegularTab) {
            return Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accent.withAlpha((0.1 * 255).round()),
                        AppTheme.primary.withAlpha((0.05 * 255).round()),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 32,
                        color: AppTheme.accent,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Nästan klar!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gå till fliken "Avslutande frågor" för att slutföra ditt dagboksinlägg.',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              AppTheme.primary.withAlpha((0.8 * 255).round()),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => _tabController.animateTo(1),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Gå till avslutande frågor'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.accent,
                          side: BorderSide(color: AppTheme.accent),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle:
                      const TextStyle(fontSize: 16, color: AppTheme.background),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: AppTheme.background,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Skicka'),
              ),
            );
          }
        }
      },
    );
  }
}
