class ProfileLinkDTO {
  ProfileLinkDTO({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String icon; // e.g., 'pix', 'book', 'link'
}
