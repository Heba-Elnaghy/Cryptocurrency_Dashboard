import 'package:equatable/equatable.dart';

class ConnectionStatus extends Equatable {
  final bool isConnected;
  final String statusMessage;
  final DateTime lastUpdate;

  const ConnectionStatus({
    required this.isConnected,
    required this.statusMessage,
    required this.lastUpdate,
  });

  ConnectionStatus copyWith({
    bool? isConnected,
    String? statusMessage,
    DateTime? lastUpdate,
  }) {
    return ConnectionStatus(
      isConnected: isConnected ?? this.isConnected,
      statusMessage: statusMessage ?? this.statusMessage,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  @override
  List<Object?> get props => [isConnected, statusMessage, lastUpdate];
}
