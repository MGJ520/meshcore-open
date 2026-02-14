import 'package:flutter/material.dart';

class SNRUi {
  final IconData icon;
  final Color color;
  final String text;
  const SNRUi(this.icon, this.color, this.text);
}

List<double> getSNRfromSF(int spreadingFactor) {
  switch (spreadingFactor) {
    case 7:
      return [4.0, -2.0, -4.0, -6.0];
    case 8:
      return [4.0, -4.0, -6.0, -8.0];
    case 9:
      return [4.0, -6.0, -8.0, -10.0];
    case 10:
      return [4.0, -8.0, -10.0, -13.0];
    case 11:
      return [4.0, -10.0, -12.5, -15.0];
    case 12:
      return [4.0, -12.5, -15.0, -18.0];
    default:
      return []; // Or throw Exception('Invalid SF: $spreadingFactor');
  }
}

SNRUi snrUiFromSNR(double? snr, int? spreadingFactor) {
  if (snr == null || spreadingFactor == null) {
    return const SNRUi(Icons.signal_cellular_off, Colors.grey, '—');
  }

  final snrLevels = getSNRfromSF(spreadingFactor);

  IconData icon;
  Color color;
  String text = '${snr.toStringAsFixed(1)} dB';

  if (snr >= snrLevels[0]) {
    icon = Icons.signal_cellular_alt;
    color = Colors.green;
  } else if (snr >= snrLevels[1]) {
    icon = Icons.signal_cellular_alt;
    color = Colors.lightGreen;
  } else if (snr >= snrLevels[2]) {
    icon = Icons.signal_cellular_alt;
    color = Colors.yellow;
  } else if (snr >= snrLevels[3]) {
    icon = Icons.signal_cellular_alt_2_bar;
    color = Colors.orange;
  } else {
    icon = Icons.signal_cellular_alt_1_bar;
    color = Colors.red;
  }

  return SNRUi(icon, color, text);
}
