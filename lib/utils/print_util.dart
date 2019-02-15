import 'package:flutter/foundation.dart';
void log(Object o) {
  bool isDebug = false;
  assert(isDebug = true);
  if (isDebug) debugPrint(o);
}
