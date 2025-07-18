// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'okx_ticker_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OKXTickerResponse _$OKXTickerResponseFromJson(Map<String, dynamic> json) =>
    OKXTickerResponse(
      code: json['code'] as String,
      msg: json['msg'] as String,
      data: (json['data'] as List<dynamic>)
          .map((e) => OKXTicker.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OKXTickerResponseToJson(OKXTickerResponse instance) =>
    <String, dynamic>{
      'code': instance.code,
      'msg': instance.msg,
      'data': instance.data.map((e) => e.toJson()).toList(),
    };

OKXTicker _$OKXTickerFromJson(Map<String, dynamic> json) => OKXTicker(
  instId: json['instId'] as String,
  last: json['last'] as String,
  vol24h: json['vol24h'] as String,
  volCcy24h: json['volCcy24h'] as String,
  open24h: json['open24h'] as String,
  high24h: json['high24h'] as String,
  low24h: json['low24h'] as String,
  ts: json['ts'] as String,
);

Map<String, dynamic> _$OKXTickerToJson(OKXTicker instance) => <String, dynamic>{
  'instId': instance.instId,
  'last': instance.last,
  'vol24h': instance.vol24h,
  'volCcy24h': instance.volCcy24h,
  'open24h': instance.open24h,
  'high24h': instance.high24h,
  'low24h': instance.low24h,
  'ts': instance.ts,
};
