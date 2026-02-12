import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:gpx/gpx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class SparseLocationLogger {
  static const double distanceThresholdMiles = 0.25;
  static const double distanceThresholdMeters =
      distanceThresholdMiles * 1609.34;
  static const double headingChangeThresholdDeg = 35.0;
  static const double minSpeedForTurnKmh = 8.0;
  static const double minTime = 120.0; // seconds

  Position? _lastLoggedPosition;
  double? _lastHeading;
  DateTime? _lastLoggedTime;
  StreamSubscription<Position>? _positionStream;
  Timer? _timer;
  Function(Position position)? _onNewLogPoint;
  // GPX structures
  final Gpx _gpx = Gpx();
  Trkseg _currentSegment = Trkseg(); // one segment for the whole session

  File? _gpxFile;

  bool _isInitialized = false;

  void initialize(Function(Position position) onNewLogPoint) {
    _onNewLogPoint = onNewLogPoint;
  }

  Future<void> startLogging() async {
    // Permissions & service check (same as before)
    var status = await Permission.location.request();
    if (!status.isGranted) {
      print('Location permission denied');
      return;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services disabled');
      return;
    }

    // Prepare files
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    _gpxFile = File('${directory.path}/track_$timestamp.gpx');

    // Init GPX metadata
    _gpx.metadata = Metadata(
      name: 'Sparse Track ${DateTime.now().toString().split(' ').first}',
      desc: 'Sparse GPS log: ~every 1.5 mi or significant turns',
      time: DateTime.now(),
    );

    // Add one track with one segment
    final track = Trk(name: 'Main Track');
    _currentSegment = Trkseg();
    track.trksegs.add(_currentSegment);
    _gpx.trks.add(track);

    _isInitialized = true;

    // Start location stream
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 152, // meters (~0.16 mi) - helps battery
      ),
    ).listen(_onPositionReceived);

    // Also poll via timer as fallback
    _timer = Timer.periodic(Duration(seconds: (minTime / 2).toInt()), (
      _,
    ) async {
      final position = await Geolocator.getCurrentPosition();
      await _onPositionReceived(position);
    });

    _lastLoggedPosition = null;
    _lastHeading = null;
    _lastLoggedTime = null;

    print('Sparse GPX logging started → ${_gpxFile?.path}');
  }

  Future<void> stopLogging() async {
    await _positionStream?.cancel();
    _positionStream = null;
    _timer?.cancel();
    _timer = null;

    if (_isInitialized && _currentSegment.trkpts.isNotEmpty) {
      // Write GPX file on stop
      final xmlString = GpxWriter().asString(_gpx, pretty: true);

      await _gpxFile?.writeAsString(xmlString);

      final result = await SharePlus.instance.share(
        ShareParams(
          text: 'Sparse GPS track',
          subject: 'Sparse GPS track',
          files: [XFile(_gpxFile?.path ?? '')],
        ),
      );

      await _gpxFile?.delete();
    }

    print('Logging stopped');
  }

  Future<void> _onPositionReceived(Position position) async {
    final now = DateTime.now();
    final speedKmh = position.speed * 3.6;
    final heading = position.heading;

    bool shouldLog = false;
    String reason = '';

    if (_lastLoggedPosition == null) {
      shouldLog = true;
      reason = 'start';
    } else {
      final distanceMeters = Geolocator.distanceBetween(
        _lastLoggedPosition!.latitude,
        _lastLoggedPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      if (distanceMeters >= distanceThresholdMeters) {
        shouldLog = true;
        reason =
            'distance (${(distanceMeters / 1609.34).toStringAsFixed(2)} mi)';
      } else if (speedKmh > minSpeedForTurnKmh && _lastHeading != null) {
        double delta = (heading - _lastHeading!).abs();
        delta = math.min(delta, 360 - delta);
        if (delta > headingChangeThresholdDeg) {
          shouldLog = true;
          reason = 'turn (${delta.toStringAsFixed(1)}°)';
        }
      } else if (_lastLoggedTime != null) {
        final elapsed = now.difference(_lastLoggedTime!).inSeconds;
        if (elapsed >= minTime && distanceMeters >= distanceThresholdMeters) {
          shouldLog = true;
          reason = 'time (${elapsed}s)';
        }
      }
    }

    if (shouldLog) {
      // Create GPX Waypoint (trkpt)
      final pt = Wpt(
        lat: position.latitude,
        lon: position.longitude,
        ele: position.altitude, // if available
        time: now,
        extensions: {
          "course": ?heading.isFinite ? heading : null,
          "speed": ?speedKmh > 0 ? speedKmh / 3.6 : null, // GPX speed in m/s
        },
        // You can add hdop, vdop, etc. from position if desired
      );

      _currentSegment.trkpts.add(pt);
      _onNewLogPoint?.call(position);
      print('Logged point: ${pt.lat}, ${pt.lon} ($reason)');

      _lastLoggedPosition = position;
      _lastHeading = heading;
      _lastLoggedTime = now;
    } else {
      print('Skipped point: ${position.latitude}, ${position.longitude}');
    }
  }

  Position snapToGridCenter({
    required Position position,
    required double cellSizeDegrees, // e.g. 0.01 ≈ 1.1 km, 0.001 ≈ 110 m
  }) {
    Position snappedPosition = position;
    // Snap latitude
    final latFloor =
        (position.latitude / cellSizeDegrees).floor() * cellSizeDegrees;
    final snappedLat = latFloor + (cellSizeDegrees / 2);

    // Snap longitude
    final lonFloor =
        (position.longitude / cellSizeDegrees).floor() * cellSizeDegrees;
    final snappedLon = lonFloor + (cellSizeDegrees / 2);

    snappedPosition = Position(
      latitude: snappedLat,
      longitude: snappedLon,
      altitude: position.altitude,
      accuracy: position.accuracy,
      heading: position.heading,
      speed: position.speed,
      speedAccuracy: position.speedAccuracy,
      altitudeAccuracy: position.altitudeAccuracy,
      headingAccuracy: position.headingAccuracy,
      timestamp: position.timestamp,
    );

    return snappedPosition;
  }

  Future<String> getGpxFilePath() async => _gpxFile?.path ?? 'Not started';
  bool isLogging() => _positionStream != null;
  int getPointCount() => _currentSegment.trkpts.length;
}
