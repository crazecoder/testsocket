import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html_view/flutter_html_text.dart';
import '../utils/string_util.dart';

class ClipBoardText extends StatelessWidget {
  final text;
  final Function onCopyComplete;
  final style;

  ClipBoardText({this.text, this.onCopyComplete, this.style});

  @override
  Widget build(BuildContext context) {
    var textWidget;
    var content = text;
    var urls = parseUrl(content);

    urls.forEach((_url) {
      content = content.replaceAll(_url, '<a href="$_url">$_url</a>');
    });

    if (urls.length > 0) {
      textWidget = new HtmlText(
        data: content,
      );
    } else {
      textWidget = new Text(
        content,
        style: style,
      );
    }
    return new GestureDetector(
      child: textWidget,
      onLongPress: () {
        Clipboard.setData(new ClipboardData(text: text)).then((_) {
          onCopyComplete();
        });
      },
    );
  }
}
