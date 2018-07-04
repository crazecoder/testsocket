class Message {
  final String username;
  final String message;
  final int type;
  final int count;
  final int id;

  Message(this.id,this.message, this.username, this.type, {this.count = 0});

  Message.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        username = json['username'],
        message = json['message'],
        type = json['type'],
        count = json['count'];

//  Map<String, dynamic> toJson() =>
//      {
//        'username': username,
//        'message': message,
//      };
  String toJson() =>
      '{"id": $id,"username": "$username","message": "$message","type":$type,"count":$count}';
}
