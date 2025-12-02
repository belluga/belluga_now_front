import 'package:belluga_now/domain/partners/engagement_data.dart';
import 'package:belluga_now/domain/partners/partner_model.dart';
import 'package:belluga_now/presentation/tenant/discovery/widgets/engagement_metric_mapper.dart';
import 'package:belluga_now/presentation/tenant/discovery/widgets/metric_chip.dart';
import 'package:flutter/material.dart';

class PartnerCardOverlay extends StatelessWidget {
  final PartnerModel partner;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;
  final bool showDetails;
  final bool isFavorite;

  const PartnerCardOverlay({
    super.key,
    required this.partner,
    required this.onFavoriteTap,
    required this.showDetails,
    this.onTap = _defaultOnTap,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (partner.distanceMeters != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.place, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    partner.distanceMeters! >= 1000
                        ? '${(partner.distanceMeters! / 1000).toStringAsFixed(1)} km'
                        : '${partner.distanceMeters!.toStringAsFixed(0)} m',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox.shrink(),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 22,
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.white,
                  ),
                  onPressed: onFavoriteTap,
                ),
              ),
              const SizedBox(height: 8),
              MetricChip(
                icon: Icons.rocket_launch,
                value: partner.acceptedInvites.toString(),
                tooltip: 'Convites aceitos',
              ),
              if (partner.engagementData != null)
                _buildEngagementMetric(partner.engagementData!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementMetric(EngagementData data) {
    final vm = EngagementMetricMapper.from(data);
    if (vm == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: MetricChip(
        icon: vm.icon,
        value: vm.value,
        tooltip: vm.tooltip,
      ),
    );
  }

  static void _defaultOnTap() {}
}
