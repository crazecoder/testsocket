import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_html/flutter_html.dart';
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
      textWidget = new Html(
        data: content,
        onLinkTap: (url){
          _launchUrl(url);
        },
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

  void _launchUrl(url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
