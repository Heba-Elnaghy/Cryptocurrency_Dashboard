import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'okx_instrument_response.g.dart';

@JsonSerializable(explicitToJson: true)
class OKXInstrumentResponse extends Equatable {
  final String code;
  final String msg;
  final List<OKXInstrument> data;

  const OKXInstrumentResponse({
    required this.code,
    required this.msg,
    required this.data,
  });

  factory OKXInstrumentResponse.fromJson(Map<String, dynamic> json) =>
      _$OKXInstrumentResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OKXInstrumentResponseToJson(this);

  @override
  List<Object?> get props => [code, msg, data];
}

@JsonSerializable()
class OKXInstrument extends Equatable {
  final String instId;
  final String baseCcy;
  final String quoteCcy;
  final String state;
  final String instType;

  const OKXInstrument({
    required this.instId,
    required this.baseCcy,
    required this.quoteCcy,
    required this.state,
    required this.instType,
  });

  factory OKXInstrument.fromJson(Map<String, dynamic> json) =>
      _$OKXInstrumentFromJson(json);

  Map<String, dynamic> toJson() => _$OKXInstrumentToJson(this);

  @override
  List<Object?> get props => [instId, baseCcy, quoteCcy, state, instType];
}
