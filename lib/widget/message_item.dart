import 'package:flutter/material.dart';

//import 'package:flutter_gsyplayer/flutter_gsyplayer.dart';
import 'package:flutter_ijkplayer/flutter_ijkplayer.dart';
import '../bean/message.dart' as m;
import '../utils/image_util.dart';
import '../utils/string_util.dart';
import '../constant.dart';
import '../widget/clipboard_text.dart';
import '../utils/print_util.dart';

class MessageItem extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final m.Message message;
  final BuildContext context;

  MessageItem(this.context, {this.scaffoldKey, this.message});

  @override
  State<StatefulWidget> createState() => _MessageItemState();
}

class _MessageItemState extends State<MessageItem> {
  var _textStyle;
  var _statusTextStyle;
  var _username;
  bool _isStausMessage;

  @override
  void initState() {
    super.initState();
    _isStausMessage = widget.message.type != ConstantValue.NORMAL &&
        widget.message.type != ConstantValue.IMAGE &&
        widget.message.type != ConstantValue.VIDEO &&
        widget.message.type != ConstantValue.GIF;

    _username = '${widget.message.username} ：';
    if (_isStausMessage) {
      _username = widget.message.username;
    }
  }

  @override
  Widget build(BuildContext context) {
    _textStyle = TextStyle(color: Theme.of(context).textTheme.body1.color);
    _statusTextStyle = TextStyle(color: Theme.of(context).primaryColor);
    return widget.message.type == ConstantValue.IMAGE
        ? _buildImageItem(_username, _textStyle,
            CompressImage.getImageByte(widget.message.message))
        : Container(
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
                _buildContentItem() ?? Container(),
              ],
            ),
          );
  }

  Widget _buildContentItem(){
    var content = widget.message.message;
    if (widget.message.type == ConstantValue.GIF) {
      var gifUrls = getGifUrl(content);
      var gifItems = <Widget>[];
      gifUrls.forEach((_url) {
        gifItems.add(_buildGifItem(_url));
      });
      return new Expanded(
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: gifItems,
        ),
      );
    } else if (widget.message.type == ConstantValue.VIDEO) {
      var videoUrls = getVideoUrl(content);
      var videoItems = <Widget>[];
      videoUrls.forEach((_url) {
        videoItems.add(_buildVideoItem(_url));
      });
      return new Expanded(
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: videoItems,
        ),
      );
    } else {
      return new Expanded(
        child: new ClipBoardText(
          style: _isStausMessage ? _statusTextStyle : _textStyle,
          text: widget.message.message,
          onCopyComplete: () => _isStausMessage
              ? log("")
              : widget.scaffoldKey.currentState
              .showSnackBar(SnackBar(content: Text("信息复制完成"))),
        ),
      );
    }
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
//          child: GSYPlayer(
//            url: _url,
//            autoPlay: true,
//          ),
          child: Stack(
            children: <Widget>[
              FlutterIjkplayer(
                url: _url,
                autoPlay: true,
                previewMills: 10 * 1000,
              ),
              GestureDetector(
                onTap: () => play(url: _url),
                child: Center(
                  child: CircleAvatar(
                    child: Icon(Icons.play_arrow),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildGifItem(_url) => new Container(
        padding: EdgeInsets.only(left: 5.0, right: 5.0),
        child: new GestureDetector(
          child: new Container(
            width: ConstantValue.IMAGE_WIDTH,
            height: ConstantValue.IMAGE_HEIGHT,
            child: new Image.network(
              _url,
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
            child: new Image.network(
              _url,
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

  @override
  void dispose() {
    super.dispose();
  }
}
