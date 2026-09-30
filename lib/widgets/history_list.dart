import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/measurement_model.dart';
import '../utils/constants.dart';

class HistoryList extends StatelessWidget {
  const HistoryList({
    super.key,
    required this.measurements,
  });

  final List<Measurement> measurements;

  String _valueWithUnit(Measurement m) {
    final unit = AppConstants.unitForParameter(m.parameterType);
    switch (m.parameterType) {
      case AppConstants.parameterProtein:
        return '${m.value.toStringAsFixed(1)} $unit';
      case AppConstants.parameterGlucose:
      case AppConstants.parameterSalinity:
        return '${m.value.round()} $unit';
      default:
        return '${m.value} $unit';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (measurements.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'History is empty.\nSimulate a reading to record results.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: measurements.length,
      itemBuilder: (context, index) {
        final m = measurements[index];
        final dt = DateFormat('MMM d, HH:mm').format(m.timestamp.toLocal());
        final indicator = AppConstants.statusBackgroundColor(m.categoryStatus);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppConstants.clinicalBorder),
          ),
          color: AppConstants.clinicalSurface,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: SizedBox(
              width: 8,
              height: 44,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: indicator,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            title: Text(
              m.parameterType,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppConstants.clinicalPrimary,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                dt,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _valueWithUnit(m),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  m.categoryStatus,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppConstants.statusLabelColor(m.categoryStatus),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
