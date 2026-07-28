import 'package:flutter/material.dart';
import '../core/models/enums.dart';

/// App-wide constants used across every phase.
class AppConstants {
  AppConstants._();

  static const String appName = 'Academic Assistant';

  // Local storage root (mirrors the plan's folder structure):
  // AcademicAssistant/Semester_X/Subject/Theory|Lab|.../...
  static const String rootFolderName = 'AcademicAssistant';

  // Standard spacing scale — keep every screen visually consistent.
  static const double spaceXS = 4;
  static const double spaceS = 8;
  static const double spaceM = 16;
  static const double spaceL = 24;
  static const double spaceXL = 32;

  static const double radiusM = 14;
  static const double radiusL = 20;
}

