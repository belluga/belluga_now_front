import 'package:belluga_now/domain/artist/artist_resume.dart';
import 'package:belluga_now/infrastructure/dal/dto/artist/artist_resume_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_artist_dto.dart';

mixin ArtistDtoMapper {
  ArtistResume mapArtistResumeDto(ArtistResumeDto dto) {
    return ArtistResume.fromPrimitives(
      id: dto.id,
      name: dto.name,
      avatarUrl: dto.avatarUrl,
      isHighlight: dto.isHighlight,
      genres: dto.genres,
    );
  }

  ArtistResume mapEventArtistDto(EventArtistDTO dto) {
    return ArtistResume.fromPrimitives(
      id: dto.id,
      name: dto.name,
      avatarUrl: dto.avatarUrl,
      isHighlight: dto.highlight ?? false,
      genres: dto.genres,
    );
  }
}
