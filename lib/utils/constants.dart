import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:kachow_mvp/utils/utils.dart';
import 'package:shimmer/shimmer.dart';

class Constants {
  static const int couponCodeLength = 20;

  static const Color themeColor = Color.fromRGBO(234, 68, 118, 1);

  static const List<String> weekdays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  static const SpinKitFoldingCube loadingIndicator = SpinKitFoldingCube(
    duration: Duration(seconds: 1),
    color: themeColor,
    size: 32,
  );

  /// Formats a Map of opening `hours` into a widget.
  ///
  /// The `hours` Map should be of the form
  /// {'monday': '10:00 - 18:00', 'tuesday': '10:00 - 18:00', ...}
  static Row formattedHoursWidget(Map<String, String> hours) {
    final String currentWeekday =
        DateFormat('EEEE').format(DateTime.now()).toLowerCase();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: Constants.weekdays
              .map((day) => Text(
                    Utils.capitalise(day),
                    style: day == currentWeekday
                        ? const TextStyle(
                            fontWeight: FontWeight.bold,
                          )
                        : null,
                  ))
              .toList(),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: Constants.weekdays
              .map(
                (day) => Text(
                  hours[day]!,
                  style: day == currentWeekday
                      ? const TextStyle(
                          fontWeight: FontWeight.bold,
                        )
                      : null,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  static CachedNetworkImage networkImage(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      progressIndicatorBuilder: (_, __, ___) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(color: Colors.grey),
      ),
      errorWidget: (_, __, ___) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.error,
            color: Colors.red,
          ),
          Text('Error loading image'),
        ],
      ),
    );
  }
}
