// This file is "main.dart"
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

// required: associates our `main.dart` with the code generated by Freezed
part 'Setting.freezed.dart';
// optional: Since our Person class is serializable, we must add this line.
// But if Person was not serializable, we could skip it.
part 'Setting.g.dart';

@freezed
class Setting with _$Setting {
  @JsonSerializable(explicitToJson: true)
  const factory Setting(
      {@JsonKey(name: '"thMeter"') required int thMeter,
      @JsonKey(name: '"failed"') required bool faliled}) = _Setting;

  factory Setting.fromJson(Map<String, Object?> json) =>
      _$SettingFromJson(json);
}
