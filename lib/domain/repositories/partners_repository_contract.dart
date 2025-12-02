import 'package:belluga_now/domain/partners/partner_model.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class PartnersRepositoryContract {
  /// Stream of all partners
  final allPartnersStreamValue =
      StreamValue<List<PartnerModel>>(defaultValue: const []);

  /// Stream of favorite partner IDs
  final favoritePartnerIdsStreamValue =
      StreamValue<Set<String>>(defaultValue: const {});

  /// Initialize repository and load data
  Future<void> init();

  /// Fetch all partners
  Future<List<PartnerModel>> fetchAllPartners();

  /// Search partners by query and optional type filter
  Future<List<PartnerModel>> searchPartners({
    String? query,
    PartnerType? typeFilter,
  });

  /// Get partner by slug
  Future<PartnerModel?> getPartnerBySlug(String slug);

  /// Toggle favorite status for a partner
  Future<void> toggleFavorite(String partnerId);

  /// Check if partner is favorited
  bool isFavorite(String partnerId);

  /// Get all favorite partners
  List<PartnerModel> getFavoritePartners();
}
