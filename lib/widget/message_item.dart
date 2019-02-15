import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_gsyplayer/flutter_gsyplayer.dart';
import '../bean/message.dart' as m;
import '../utils/image_util.dart';
import '../utils/string_util.dart';
import '../constant.dart';
import '../widget/clipboard_text.dart';
import '../utils/print_util.dart';

class MessageItem extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final m.Message message;
  final BuildContext context;
  var _textStyle;
  var _statusTextStyle;
  var _username;

  MessageItem(this.context, {this.scaffoldKey, this.message}) {
    _textStyle = TextStyle(color: Theme.of(context).textTheme.body1.color);
    _statusTextStyle = TextStyle(color: Theme.of(context).primaryColor);
  }

  @override
  Widget build(BuildContext context) {
    bool _isStausMessage = message.type != ConstantValue.NORMAL &&
        message.type != ConstantValue.VIDEO &&
        message.type != ConstantValue.GIF;

    _username = '${message.username} ：';
    if (message.type == ConstantValue.IMAGE) {
      return _buildImageItem(
          _username, _textStyle, CompressImage.getImageByte(message.message));
    }
    if (_isStausMessage) {
      _username = message.username;
    }
    var contentItem;
    var content = message.message;
    if (message.type == ConstantValue.GIF) {
      var gifUrls = getGifUrl(content);
      var gifItems = <Widget>[];
      gifUrls.forEach((_url) {
        gifItems.add(_buildGifItem(_url));
      });
      contentItem = new Expanded(
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: gifItems,
        ),
      );
    } else if (message.type == ConstantValue.VIDEO) {
      var videoUrls = getVideoUrl(content);
      var videoItems = <Widget>[];
      videoUrls.forEach((_url) {
        videoItems.add(_buildVideoItem(_url));
      });
      contentItem = new Expanded(
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: videoItems,
        ),
      );
    } else {
      contentItem = new Expanded(
        child: new ClipBoardText(
          style: _isStausMessage ? _statusTextStyle : _textStyle,
          text: message.message,
          onCopyComplete: () => _isStausMessage
              ? log("")
              : scaffoldKey.currentState
                  .showSnackBar(SnackBar(content: Text("信息复制完成"))),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(left: 5.0, right: 5.0),
      child: new Row(
        //对齐
        textBaseline: TextBaseline.alphabetic,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        children: <Widget>[
          new Text(
            _username,
            style: _isStausMessage ? _statusTextStyle : _textStyle,
          ),
          contentItem ?? Container(),
        ],
      ),
    );
  }

  Widget _buildImageItem(_username, _style, _file) => new Container(
        padding: EdgeInsets.only(left: 5.0, right: 5.0),
        child: new Row(
          //对齐
          textBaseline: TextBaseline.alphabetic,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          children: <Widget>[
            new Text(
              _username,
              style: _style,
            ),
            new GestureDetector(
              child: new Container(
                width: ConstantValue.IMAGE_WIDTH,
                height: ConstantValue.IMAGE_HEIGHT,
                child: new Image.memory(_file),
              ),
              onTap: () {
                _showImagePop(_file);
              },
            ),
          ],
        ),
      );

  Widget _buildVideoItem(_url) => Container(
        padding: EdgeInsets.only(left: 5.0, right: 5.0),
        child: new Container(
          width: ConstantValue.IMAGE_WIDTH,
          height: ConstantValue.IMAGE_HEIGHT,
          child: GSYPlayer(
            url: _url,
            autoPlay: true,
          ),
        ),
      );

  Widget _buildGifItem(_url) => new Container(
        padding: EdgeInsets.only(left: 5.0, right: 5.0),
        child: new GestureDetector(
          child: new Container(
            width: ConstantValue.IMAGE_WIDTH,
            height: ConstantValue.IMAGE_HEIGHT,
            child: new CachedNetworkImage(
              imageUrl: _url,
              placeholder: new CircularProgressIndicator(),
            ),
          ),
          onTap: () {
            _showGifPop(_url);
          },
        ),
      );

  void _showGifPop(_url) async {
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return new GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: new CachedNetworkImage(
              imageUrl: _url,
              placeholder: new RefreshProgressIndicator(),
            ),
          );
        });
  }

  void _showImagePop(bytes) async {
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return new GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: new Image.memory(bytes),
          );
        });
  }
}
