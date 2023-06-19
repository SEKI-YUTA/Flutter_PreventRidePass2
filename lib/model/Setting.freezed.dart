// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'Setting.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

Setting _$SettingFromJson(Map<String, dynamic> json) {
  return _Setting.fromJson(json);
}

/// @nodoc
mixin _$Setting {
  @JsonKey(name: '"thMeter"')
  int get thMeter => throw _privateConstructorUsedError;
  @JsonKey(name: '"failed"')
  bool get faliled => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SettingCopyWith<Setting> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SettingCopyWith<$Res> {
  factory $SettingCopyWith(Setting value, $Res Function(Setting) then) =
      _$SettingCopyWithImpl<$Res, Setting>;
  @useResult
  $Res call(
      {@JsonKey(name: '"thMeter"') int thMeter,
      @JsonKey(name: '"failed"') bool faliled});
}

/// @nodoc
class _$SettingCopyWithImpl<$Res, $Val extends Setting>
    implements $SettingCopyWith<$Res> {
  _$SettingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? thMeter = null,
    Object? faliled = null,
  }) {
    return _then(_value.copyWith(
      thMeter: null == thMeter
          ? _value.thMeter
          : thMeter // ignore: cast_nullable_to_non_nullable
              as int,
      faliled: null == faliled
          ? _value.faliled
          : faliled // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_SettingCopyWith<$Res> implements $SettingCopyWith<$Res> {
  factory _$$_SettingCopyWith(
          _$_Setting value, $Res Function(_$_Setting) then) =
      __$$_SettingCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: '"thMeter"') int thMeter,
      @JsonKey(name: '"failed"') bool faliled});
}

/// @nodoc
class __$$_SettingCopyWithImpl<$Res>
    extends _$SettingCopyWithImpl<$Res, _$_Setting>
    implements _$$_SettingCopyWith<$Res> {
  __$$_SettingCopyWithImpl(_$_Setting _value, $Res Function(_$_Setting) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? thMeter = null,
    Object? faliled = null,
  }) {
    return _then(_$_Setting(
      thMeter: null == thMeter
          ? _value.thMeter
          : thMeter // ignore: cast_nullable_to_non_nullable
              as int,
      faliled: null == faliled
          ? _value.faliled
          : faliled // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$_Setting with DiagnosticableTreeMixin implements _Setting {
  const _$_Setting(
      {@JsonKey(name: '"thMeter"') required this.thMeter,
      @JsonKey(name: '"failed"') required this.faliled});

  factory _$_Setting.fromJson(Map<String, dynamic> json) =>
      _$$_SettingFromJson(json);

  @override
  @JsonKey(name: '"thMeter"')
  final int thMeter;
  @override
  @JsonKey(name: '"failed"')
  final bool faliled;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Setting(thMeter: $thMeter, faliled: $faliled)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'Setting'))
      ..add(DiagnosticsProperty('thMeter', thMeter))
      ..add(DiagnosticsProperty('faliled', faliled));
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_Setting &&
            (identical(other.thMeter, thMeter) || other.thMeter == thMeter) &&
            (identical(other.faliled, faliled) || other.faliled == faliled));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, thMeter, faliled);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_SettingCopyWith<_$_Setting> get copyWith =>
      __$$_SettingCopyWithImpl<_$_Setting>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_SettingToJson(
      this,
    );
  }
}

abstract class _Setting implements Setting {
  const factory _Setting(
      {@JsonKey(name: '"thMeter"') required final int thMeter,
      @JsonKey(name: '"failed"') required final bool faliled}) = _$_Setting;

  factory _Setting.fromJson(Map<String, dynamic> json) = _$_Setting.fromJson;

  @override
  @JsonKey(name: '"thMeter"')
  int get thMeter;
  @override
  @JsonKey(name: '"failed"')
  bool get faliled;
  @override
  @JsonKey(ignore: true)
  _$$_SettingCopyWith<_$_Setting> get copyWith =>
      throw _privateConstructorUsedError;
}
