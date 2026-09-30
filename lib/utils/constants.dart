import 'package:flutter/material.dart';

abstract final class AppConstants {
  static const String parameterGlucose = 'Glucose';
  static const String parameterProtein = 'Protein';
  static const String parameterSalinity = 'Salinity';

  static const List<String> parameterOptions = [
    parameterGlucose,
    parameterProtein,
    parameterSalinity,
  ];

  static const String statusRendah = 'Rendah';
  static const String statusNormal = 'Normal';
  static const String statusTinggi = 'Tinggi';

  static const Color clinicalBackground = Color(0xFFF5F7FA);
  static const Color clinicalSurface = Color(0xFFFFFFFF);
  static const Color clinicalBorder = Color(0xFFE2E8F0);
  static const Color clinicalPrimary = Color(0xFF1E3A5F);
  static const Color statusNormalGreen = Color(0xFF2E7D32);
  static const Color statusRendahKuning = Color(0xFFF9A825);
  static const Color statusDangerRed = Color(0xFFC62828);
  static const Color statusRendahLabel = Color(0xFF6D4C00);

  static String unitForParameter(String parameterType) {
    switch (parameterType) {
      case parameterProtein:
        return 'g/dL';
      case parameterGlucose:
        return 'mg/dL';
      case parameterSalinity:
        return 'mEq/L';
      default:
        return '';
    }
  }

  static String categorizeValue(String parameterType, double value) {
    switch (parameterType) {
      case parameterProtein:
        return _categorizeProtein(value);
      case parameterGlucose:
        return _categorizeGlucose(value);
      case parameterSalinity:
        return _categorizeSalinity(value);
      default:
        return statusNormal;
    }
  }

  static Color statusBackgroundColor(String categoryStatus) {
    switch (categoryStatus) {
      case statusRendah:
        return statusRendahKuning;
      case statusNormal:
        return statusNormalGreen;
      case statusTinggi:
        return statusDangerRed;
      default:
        return clinicalBorder;
    }
  }

  static Color statusForegroundOnBadge(String _) => Colors.white;

  static Color statusLabelColor(String categoryStatus) {
    switch (categoryStatus) {
      case statusRendah:
        return statusRendahLabel;
      case statusNormal:
      case statusTinggi:
        return statusBackgroundColor(categoryStatus);
      default:
        return clinicalBorder;
    }
  }
}

String _categorizeProtein(double valueGPerDl) {
  if (valueGPerDl < 6.0) {
    return AppConstants.statusRendah;
  }
  if (valueGPerDl <= 8.3) {
    return AppConstants.statusNormal;
  }
  return AppConstants.statusTinggi;
}

String _categorizeGlucose(double valueMgPerDl) {
  if (valueMgPerDl < 70) {
    return AppConstants.statusRendah;
  }
  if (valueMgPerDl <= 99) {
    return AppConstants.statusNormal;
  }
  return AppConstants.statusTinggi;
}

String _categorizeSalinity(double valueMEqPerL) {
  if (valueMEqPerL < 135) {
    return AppConstants.statusRendah;
  }
  if (valueMEqPerL <= 145) {
    return AppConstants.statusNormal;
  }
  return AppConstants.statusTinggi;
}
