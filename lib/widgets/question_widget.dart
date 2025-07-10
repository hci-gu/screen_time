import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../api.dart';

class QuestionWidget extends StatefulWidget {
  final Question question;
  final Function(String questionId, dynamic value) onAnswered;
  final Map<String, dynamic> answers;

  const QuestionWidget({
    super.key,
    required this.question,
    required this.onAnswered,
    required this.answers,
  });

  @override
  State<QuestionWidget> createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends State<QuestionWidget> {
  TextEditingController? _textController;

  @override
  void initState() {
    super.initState();
    if (widget.question.type == 'freeText' ||
        widget.question.type == 'number') {
      _textController = TextEditingController(
        text: widget.answers[widget.question.id]?.toString() ?? '',
      );
    }
  }

  @override
  void didUpdateWidget(QuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_textController != null) {
      final currentAnswer =
          widget.answers[widget.question.id]?.toString() ?? '';
      if (_textController!.text != currentAnswer) {
        _textController!.text = currentAnswer;
      }
    }
  }

  @override
  void dispose() {
    _textController?.dispose();
    super.dispose();
  }

  bool _shouldShowSubQuestion(Question subQuestion) {
    if (subQuestion.showWhenParentIs == null) {
      return true;
    }
    return widget.answers[widget.question.id]?.toString() ==
        subQuestion.showWhenParentIs?.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isGroupHeader = widget.question.type == 'groupHeader';
    final questionContent = isGroupHeader
        ? Padding(
            padding: const EdgeInsets.fromLTRB(8, 24, 8, 16),
            child: Html(data: widget.question.text, style: {
              "body": Style(
                  fontSize: FontSize.large,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 28, 37, 65),
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero),
            }),
          )
        : Padding(
            padding: const EdgeInsets.all(20.0),
            child: _buildQuestionInput(context),
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(255, 224, 227, 231)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            questionContent,
            if (widget.question.subQuestions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ...widget.question.subQuestions.map((subQuestion) {
                          if (_shouldShowSubQuestion(subQuestion)) {
                            return QuestionWidget(
                              question: subQuestion,
                              onAnswered: widget.onAnswered,
                              answers: widget.answers,
                            );
                          }
                          return const SizedBox.shrink();
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionText(String text) {
    return Html(
      data: text,
      style: {
        "body": Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontSize: FontSize.medium,
          color: const Color.fromARGB(255, 28, 37, 65),
          fontWeight: FontWeight.w500,
          lineHeight: LineHeight.number(1.5),
        ),
      },
    );
  }

  Widget _buildQuestionInput(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    const primaryTextColor = Color.fromARGB(255, 28, 37, 65);
    const accentColor = Color.fromARGB(255, 91, 192, 190);
    const borderColor = Color.fromARGB(255, 224, 227, 231);
    const inputFillColor = Color.fromARGB(255, 245, 247, 250);

    switch (widget.question.type) {
      case 'yesNo':
      case 'singleChoice':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestionText(widget.question.text),
            const SizedBox(height: 16),
            ...widget.question.options.map((option) {
              final isSelected =
                  widget.answers[widget.question.id]?.toString() == option.id;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? accentColor : borderColor,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: RadioListTile<String>(
                  title: Text(option.displayText,
                      style: textTheme.bodyLarge
                          ?.copyWith(color: primaryTextColor)),
                  value: option.id,
                  groupValue: widget.answers[widget.question.id]?.toString(),
                  onChanged: (value) =>
                      widget.onAnswered(widget.question.id, option.id),
                  activeColor: accentColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  controlAffinity: ListTileControlAffinity.trailing,
                  tileColor: isSelected ? accentColor.withOpacity(0.05) : null,
                ),
              );
            }).toList(),
          ],
        );

      case 'number':
      case 'freeText':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestionText(widget.question.text),
            const SizedBox(height: 12),
            TextFormField(
              controller: _textController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: accentColor, width: 1.5),
                ),
                filled: true,
                fillColor: inputFillColor,
              ),
              keyboardType: widget.question.type == 'number'
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              onChanged: (value) => widget.onAnswered(
                  widget.question.id,
                  widget.question.type == 'number'
                      ? num.tryParse(value)
                      : value),
            ),
          ],
        );

      case 'slider':
        final double currentValue =
            (widget.answers[widget.question.id] as num? ?? 1.0).toDouble();
        final int divisions = widget.question.options.length > 1
            ? widget.question.options.length - 1
            : 1;
        String currentLabel = widget.question.options.first.displayText;
        if (widget.answers[widget.question.id] != null) {
          final index = (widget.answers[widget.question.id] as num).round() - 1;
          if (index >= 0 && index < widget.question.options.length) {
            currentLabel = widget.question.options[index].displayText;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestionText(widget.question.text),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: accentColor,
                inactiveTrackColor: accentColor.withOpacity(0.3),
                thumbColor: accentColor,
                overlayColor: accentColor.withOpacity(0.2),
                valueIndicatorColor: primaryTextColor,
                valueIndicatorTextStyle: const TextStyle(color: Colors.white),
              ),
              child: Slider(
                value: currentValue,
                min: 1,
                max: widget.question.options.length.toDouble(),
                divisions: divisions,
                label: currentLabel,
                onChanged: (value) =>
                    widget.onAnswered(widget.question.id, value.round()),
              ),
            ),
            Center(
              child: Text(
                currentLabel,
                style: textTheme.bodyMedium?.copyWith(
                    color: primaryTextColor.withOpacity(0.8),
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );

      case 'dateTime':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestionText(widget.question.text),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                  builder: (context, child) {
                    return Theme(
                      data: theme.copyWith(
                        colorScheme: theme.colorScheme.copyWith(
                          primary: accentColor,
                          onPrimary: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (time != null) {
                  widget.onAnswered(widget.question.id, time.format(context));
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                  color: inputFillColor,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.answers[widget.question.id]?.toString() ??
                          'Välj tid',
                      style: textTheme.bodyLarge
                          ?.copyWith(color: primaryTextColor),
                    ),
                    const Icon(Icons.access_time_outlined,
                        color: primaryTextColor),
                  ],
                ),
              ),
            ),
          ],
        );

      default:
        return Text('Okänd frågetyp: ${widget.question.type}',
            style: const TextStyle(color: Colors.red));
    }
  }
}
