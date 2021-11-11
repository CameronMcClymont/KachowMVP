import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Utils {
  /// Hides the current Snackbar and shows a new one with the given `text`.
  static void showInSnackBar(BuildContext context, String text) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Capitalises the first letter in a `str`.
  static String capitalise(String str) {
    return str[0].toUpperCase() + str.substring(1);
  }

  /// Generates a random String of length `len`.
  static String getRandomString(int len) {
    var random = Random.secure();
    var values = List<int>.generate(len, (i) => random.nextInt(255));
    return base64UrlEncode(values);
  }

  static bool isMerchantOpen(Map<String, String> hours) {
    final currentDate = DateTime.now();
    final String currentWeekday =
        DateFormat('EEEE').format(currentDate).toLowerCase();

    String openingTime =
        '${currentDate.year}-${currentDate.month}-${currentDate.day} ';
    String closingTime =
        '${currentDate.year}-${currentDate.month}-${currentDate.day} ';

    final String hoursToday = hours[currentWeekday]!;
    openingTime += hoursToday.substring(0, hoursToday.indexOf('-')).trim();
    closingTime += hoursToday.substring(hoursToday.indexOf('-') + 1).trim();

    final DateTime openingDatetime =
        DateFormat('yyyy-MM-dd HH:mm').parse(openingTime);
    final DateTime closingDatetime =
        DateFormat('yyyy-MM-dd HH:mm').parse(closingTime);

    return currentDate.isAfter(openingDatetime) &&
        currentDate.isBefore(closingDatetime);
  }
}
