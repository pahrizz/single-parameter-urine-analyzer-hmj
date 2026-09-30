import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/constants.dart';

class ResultCard extends StatelessWidget {
  const ResultCard({
    super.key,
    required this.parameterType,
    this.timestamp,
    this.value,
    this.status,
  });

  final String parameterType;
  final DateTime? timestamp;
  final double? value;
  final String? status;

  String _formattedValue() {
    if (value == null) {
      return '—';
    }
    switch (parameterType) {
      case AppConstants.parameterProtein:
        return value!.toStringAsFixed(1);
      case AppConstants.parameterGlucose:
      case AppConstants.parameterSalinity:
        return value!.round().toString();
      default:
        return value!.toStringAsFixed(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = AppConstants.unitForParameter(parameterType);
    final formattedDate = timestamp != null
        ? DateFormat('EEE, MMM d, yyyy · HH:mm').format(timestamp!.toLocal())
        : 'No measurement yet';

    final badgeColor = status != null
        ? AppConstants.statusBackgroundColor(status!)
        : AppConstants.clinicalBorder;
    final badgeFg = status != null
        ? AppConstants.statusForegroundOnBadge(status!)
        : theme.colorScheme.onSurfaceVariant;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppConstants.clinicalBorder),
      ),
      color: AppConstants.clinicalSurface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formattedDate,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _formattedValue(),
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppConstants.clinicalPrimary,
                letterSpacing: -0.5,
              ),
            ),
            if (value != null) ...[
              const SizedBox(height: 4),
              Text(
                unit,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: status != null
                    ? badgeColor.withOpacity(0.12)
                    : AppConstants.clinicalSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: status != null ? badgeColor : AppConstants.clinicalBorder,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (status != null) ...[
                    Icon(
                      Icons.label_important_outline_rounded,
                      size: 20,
                      color: badgeColor,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      status ?? 'Awaiting reading',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: status != null
                            ? AppConstants.statusLabelColor(status!)
                            : badgeFg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
