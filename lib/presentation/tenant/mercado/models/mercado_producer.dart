import 'package:flutter/material.dart';

class MercadoCategory {
  const MercadoCategory({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

class MercadoProduct {
  const MercadoProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final String description;
  final String imageUrl;
}

class MercadoProducer {
  const MercadoProducer({
    required this.id,
    required this.name,
    required this.tagline,
    required this.address,
    required this.categories,
    required this.heroImageUrl,
    required this.logoImageUrl,
    required this.about,
    required this.products,
    required this.galleryImages,
    this.whatsappNumber,
  });

  final String id;
  final String name;
  final String tagline;
  final String address;
  final List<String> categories;
  final String heroImageUrl;
  final String logoImageUrl;
  final String about;
  final List<MercadoProduct> products;
  final List<String> galleryImages;
  final String? whatsappNumber;
}
