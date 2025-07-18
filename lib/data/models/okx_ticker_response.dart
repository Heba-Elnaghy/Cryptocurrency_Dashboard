import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'okx_ticker_response.g.dart';

@JsonSerializable(explicitToJson: true)
class OKXTickerResponse extends Equatable {
  final String code;
  final String msg;
  final List<OKXTicker> data;

  const OKXTickerResponse({
    required this.code,
    required this.msg,
    required this.data,
  });

  factory OKXTickerResponse.fromJson(Map<String, dynamic> json) =>
      _$OKXTickerResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OKXTickerResponseToJson(this);

  @override
  List<Object?> get props => [code, msg, data];
}

@JsonSerializable()
class OKXTicker extends Equatable {
  final String instId;
  final String last;
  final String vol24h;
  final String volCcy24h;
  final String open24h;
  final String high24h;
  final String low24h;
  final String ts;

  const OKXTicker({
    required this.instId,
    required this.last,
    required this.vol24h,
    required this.volCcy24h,
    required this.open24h,
    required this.high24h,
    required this.low24h,
    required this.ts,
  });

  factory OKXTicker.fromJson(Map<String, dynamic> json) =>
      _$OKXTickerFromJson(json);

  Map<String, dynamic> toJson() => _$OKXTickerToJson(this);

  @override
  List<Object?> get props => [
    instId,
    last,
    vol24h,
    volCcy24h,
    open24h,
    high24h,
    low24h,
    ts,
  ];
}
