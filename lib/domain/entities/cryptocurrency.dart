import 'package:equatable/equatable.dart';
import 'listing_status.dart';

class Cryptocurrency extends Equatable {
  final String symbol;
  final String name;
  final double price;
  final double priceChange24h;
  final double volume24h;
  final ListingStatus status;
  final DateTime lastUpdated;
  final bool hasVolumeSpike;

  const Cryptocurrency({
    required this.symbol,
    required this.name,
    required this.price,
    required this.priceChange24h,
    required this.volume24h,
    required this.status,
    required this.lastUpdated,
    this.hasVolumeSpike = false,
  });

  Cryptocurrency copyWith({
    String? symbol,
    String? name,
    double? price,
    double? priceChange24h,
    double? volume24h,
    ListingStatus? status,
    DateTime? lastUpdated,
    bool? hasVolumeSpike,
  }) {
    return Cryptocurrency(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      price: price ?? this.price,
      priceChange24h: priceChange24h ?? this.priceChange24h,
      volume24h: volume24h ?? this.volume24h,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hasVolumeSpike: hasVolumeSpike ?? this.hasVolumeSpike,
    );
  }

  @override
  List<Object?> get props => [
    symbol,
    name,
    price,
    priceChange24h,
    volume24h,
    status,
    lastUpdated,
    hasVolumeSpike,
  ];
}
