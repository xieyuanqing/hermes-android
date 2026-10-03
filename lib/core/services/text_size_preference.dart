import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide, non-secret reading-size choices stored independently of profiles.
///
/// Explicit choices multiply the Android/OS [TextScaler], including its
/// nonlinear accessibility behavior. The multiplier is deliberately bounded
/// from 0.90 to 1.30 so the app can offer a predictable adjustment without
/// disabling the system accessibility setting.
enum TextSizePreference {
  system('system', '跟随系统', 1.0),
  small('small', '偏小', 0.90),
  standard('default', '默认', 1.0),
  large('large', '偏大', 1.15),
  extraLarge('extra_large', '超大', 1.30);

  const TextSizePreference(this.storageValue, this.label, this.multiplier);

  static const preferenceKey = 'app_text_size_preference';
  static const minimumExplicitMultiplier = 0.90;
  static const maximumExplicitMultiplier = 1.30;

  final String storageValue;
  final String label;
  final double multiplier;

  bool get followsSystemExactly => this == TextSizePreference.system;

  String get description => followsSystemExactly
      ? '完全依循 Android 无障碍文字大小。'
      : 'Android 文字大小的 ${(multiplier * 100).round()}%。';

  static TextSizePreference fromStorage(String? value) {
    return TextSizePreference.values.firstWhere(
      (preference) => preference.storageValue == value,
      orElse: () => TextSizePreference.system,
    );
  }

  /// Applies the explicit multiplier on top of the OS scaler. System returns
  /// the original instance, rather than a reconstructed approximation.
  TextScaler applyTo(TextScaler systemTextScaler) {
    if (followsSystemExactly) return systemTextScaler;
    return _MultiplierTextScaler(systemTextScaler, multiplier);
  }
}

class TextSizePreferenceStore {
  TextSizePreferenceStore(this._preferences);

  final SharedPreferences _preferences;

  TextSizePreference read() {
    return TextSizePreference.fromStorage(
      _preferences.getString(TextSizePreference.preferenceKey),
    );
  }

  Future<void> save(TextSizePreference preference) {
    return _preferences.setString(
      TextSizePreference.preferenceKey,
      preference.storageValue,
    );
  }
}

@immutable
class _MultiplierTextScaler extends TextScaler {
  const _MultiplierTextScaler(this.systemTextScaler, this.multiplier)
    : assert(
        multiplier >= TextSizePreference.minimumExplicitMultiplier &&
            multiplier <= TextSizePreference.maximumExplicitMultiplier,
      );

  final TextScaler systemTextScaler;
  final double multiplier;

  @override
  double get textScaleFactor => scale(14) / 14;

  @override
  double scale(double fontSize) =>
      systemTextScaler.scale(fontSize) * multiplier;

  @override
  bool operator ==(Object other) {
    return other is _MultiplierTextScaler &&
        other.systemTextScaler == systemTextScaler &&
        other.multiplier == multiplier;
  }

  @override
  int get hashCode => Object.hash(systemTextScaler, multiplier);
}
