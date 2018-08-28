List<String> parseUrl(str){
  var urls = <String>[];
  String mode = "(http[s]?:\\/\\/([\\w-]+\\.)+[\\w-]+([\\w-./?%&*=]*))";
  RegExp reg = new RegExp(mode);
  Iterable<Match> matches = reg.allMatches(str);

  for (Match m in matches) {
    urls.add(m.group(0));
  }
  return urls;
}
List<String> getGifUrl(str){
  var urls = <String>[];
  parseUrl(str).forEach((_url){
    if(_url.contains("gif")){
      urls.add(_url);
    }
  });
  return urls;
}