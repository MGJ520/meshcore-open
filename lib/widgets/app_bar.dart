import 'package:flutter/material.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/widgets/battery_indicator.dart';
import 'package:provider/provider.dart';

import 'snr_indicator.dart';

class AppBarTitle extends StatelessWidget {
  final String title;
  final TextStyle? style;
  final Widget? leading;
  final Widget? trailing;
  const AppBarTitle(
    this.title,
    this.style, {
    this.leading,
    this.trailing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final connector = context.watch<MeshCoreConnector>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leading != null) leading!,
            Text(title),
            if (connector.isConnected && connector.selfName != null)
              Center(
                child: Text(
                  '(${connector.selfName})',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BatteryIndicator(connector: connector),
            SNRIndicator(connector: connector),
          ],
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
