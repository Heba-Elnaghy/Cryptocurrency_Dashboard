import 'package:equatable/equatable.dart';

class PriceUpdateEvent extends Equatable {
  final String symbol;
  final double newPrice;
  final double priceChange;
  final DateTime timestamp;

  const PriceUpdateEvent({
    required this.symbol,
    required this.newPrice,
    required this.priceChange,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [symbol, newPrice, priceChange, timestamp];
}
