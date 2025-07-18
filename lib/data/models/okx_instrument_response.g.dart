// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'okx_instrument_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OKXInstrumentResponse _$OKXInstrumentResponseFromJson(
  Map<String, dynamic> json,
) => OKXInstrumentResponse(
  code: json['code'] as String,
  msg: json['msg'] as String,
  data: (json['data'] as List<dynamic>)
      .map((e) => OKXInstrument.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$OKXInstrumentResponseToJson(
  OKXInstrumentResponse instance,
) => <String, dynamic>{
  'code': instance.code,
  'msg': instance.msg,
  'data': instance.data.map((e) => e.toJson()).toList(),
};

OKXInstrument _$OKXInstrumentFromJson(Map<String, dynamic> json) =>
    OKXInstrument(
      instId: json['instId'] as String,
      baseCcy: json['baseCcy'] as String,
      quoteCcy: json['quoteCcy'] as String,
      state: json['state'] as String,
      instType: json['instType'] as String,
    );

Map<String, dynamic> _$OKXInstrumentToJson(OKXInstrument instance) =>
    <String, dynamic>{
      'instId': instance.instId,
      'baseCcy': instance.baseCcy,
      'quoteCcy': instance.quoteCcy,
      'state': instance.state,
      'instType': instance.instType,
    };
