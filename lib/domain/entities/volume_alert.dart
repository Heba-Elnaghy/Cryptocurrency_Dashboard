import 'package:equatable/equatable.dart';

class VolumeAlert extends Equatable {
  final String symbol;
  final double currentVolume;
  final double previousVolume;
  final double spikePercentage;

  const VolumeAlert({
    required this.symbol,
    required this.currentVolume,
    required this.previousVolume,
    required this.spikePercentage,
  });

  @override
  List<Object?> get props => [
    symbol,
    currentVolume,
    previousVolume,
    spikePercentage,
  ];
}
