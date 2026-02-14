import 'package:flutter/material.dart';
import 'package:meshcore_open/widgets/snr_indicator.dart';

import '../connector/meshcore_connector.dart';

class BatteryUi {
  final IconData icon;
  final Color? color;
  const BatteryUi(this.icon, this.color);
}

BatteryUi batteryUiForPercent(int? percent) {
  if (percent == null) {
    return const BatteryUi(Icons.battery_unknown, Colors.grey);
  }

  final p = percent.clamp(0, 100);

  return switch (p) {
    <= 5 => const BatteryUi(Icons.battery_alert, Colors.redAccent),
    <= 15 => const BatteryUi(Icons.battery_0_bar, Colors.redAccent),
    <= 30 => const BatteryUi(Icons.battery_1_bar, Colors.orange),
    <= 45 => const BatteryUi(Icons.battery_2_bar, Colors.amber),
    <= 60 => const BatteryUi(Icons.battery_3_bar, Colors.lightGreen),
    <= 80 => const BatteryUi(Icons.battery_5_bar, Colors.green),
    _ => const BatteryUi(Icons.battery_full, Colors.green),
  };
}

class BatteryIndicator extends StatefulWidget {
  final MeshCoreConnector connector;

  const BatteryIndicator({super.key, required this.connector});

  @override
  State<BatteryIndicator> createState() => _BatteryIndicatorState();
}

class _BatteryIndicatorState extends State<BatteryIndicator> {
  bool _showBatteryVoltage = false;

  @override
  Widget build(BuildContext context) {
    final percent = widget.connector.batteryPercent;
    final millivolts = widget.connector.batteryMillivolts;
    final directRepeaters = widget.connector.directRepeaters;

    if (millivolts == null) {
      return const SizedBox.shrink();
    }

    final String displayText;
    if (_showBatteryVoltage) {
      displayText = '${(millivolts / 1000.0).toStringAsFixed(2)}V';
    } else {
      displayText = percent != null ? '$percent%' : '—';
    }

    final batteryUi = batteryUiForPercent(percent);
    final directBestRepeaters = List.of(directRepeaters)
      ..sort((a, b) {
        final dateCompare = b.lastUpdated.compareTo(a.lastUpdated);
        if (dateCompare != 0) return dateCompare;
        return (b.snr).compareTo(a.snr);
      });
    final directRepeater = directBestRepeaters.isEmpty
        ? null
        : directBestRepeaters.first;

    final snrUi = snrUiFromSNR(
      directBestRepeaters.isNotEmpty ? directRepeater!.snr : null,
      widget.connector.currentSf,
    );

    return InkWell(
      onTap: () {
        setState(() {
          _showBatteryVoltage = !_showBatteryVoltage;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(batteryUi.icon, size: 18, color: batteryUi.color),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: batteryUi.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(snrUi.icon, size: 18, color: snrUi.color),
                      Text(
                        snrUi.text,
                        style: TextStyle(fontSize: 12, color: snrUi.color),
                      ),
                    ],
                  ),
                  if (directRepeater != null)
                    Text(
                      '${directRepeaters.length}: ${directRepeater.pubkeyFirstByte.toRadixString(16).padLeft(2, '0')}: ${_formatLastUpdated(directRepeater.lastUpdated)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastUpdated(DateTime lastSeen) {
    final now = DateTime.now();
    final diff = now.difference(lastSeen);

    if (diff.isNegative || diff.inMinutes < 1) {
      return "${diff.inSeconds}s";
    }
    if (diff.inMinutes < 60) {
      return "${diff.inMinutes}m";
    }
    if (diff.inHours < 24) {
      final hours = diff.inHours;
      return hours == 1 ? "1h" : "${hours}hs";
    }
    final days = diff.inDays;
    return days == 1 ? "1d" : "${days}ds";
  }
}
