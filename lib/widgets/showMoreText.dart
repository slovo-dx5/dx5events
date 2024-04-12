import 'package:flutter/material.dart';

class ShowMoreText extends StatefulWidget {
  final String text;
  ShowMoreText({required this.text});

  @override
  _ShowMoreTextState createState() => _ShowMoreTextState();
}

class _ShowMoreTextState extends State<ShowMoreText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedCrossFade(
          firstChild: Text(
            widget.text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          secondChild: Text(widget.text),
          crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_isExpanded ? 'Show Less' : 'Show More'),
              Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
            ],
          ),
        ),
      ],
    );
  }
}