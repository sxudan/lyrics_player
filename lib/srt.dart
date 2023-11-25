import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';

class SRT {
  final pattern = RegExp(r'\d+:\d+:\d+(,\d+)?\s-->\s\d+:\d+:\d+(,\d+)?');
  List<String> list = [];

  late String path;
  SRT(this.path);

  Future<void> initialise() async {
    list = await File(path).readAsLines(encoding: utf8);
  }

  double getDuration() {
    final timelines = list.where((element) => pattern.hasMatch(element));
    final last = timelines.last;
    final times = last.split(' --> ');
    final date = DateFormat('hh:mm:ss,SSS').parse(times.last);
    return date.hour * 60 * 60 +
        date.minute * 60 +
        date.second +
        1 / date.millisecond;
  }
}
