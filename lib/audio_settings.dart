class AudioSettings {
  const AudioSettings({
    this.masterVolume = 1,
    this.musicVolume = 1,
    this.effectsVolume = 1,
    this.musicEnabled = true,
    this.effectsEnabled = true,
  });

  final double masterVolume;
  final double musicVolume;
  final double effectsVolume;
  final bool musicEnabled;
  final bool effectsEnabled;

  double get musicGain => musicEnabled ? masterVolume * musicVolume : 0;
  double get effectsGain => effectsEnabled ? masterVolume * effectsVolume : 0;

  AudioSettings copyWith({
    double? masterVolume,
    double? musicVolume,
    double? effectsVolume,
    bool? musicEnabled,
    bool? effectsEnabled,
  }) => AudioSettings(
    masterVolume: masterVolume ?? this.masterVolume,
    musicVolume: musicVolume ?? this.musicVolume,
    effectsVolume: effectsVolume ?? this.effectsVolume,
    musicEnabled: musicEnabled ?? this.musicEnabled,
    effectsEnabled: effectsEnabled ?? this.effectsEnabled,
  );

  Map<String, Object?> toJson() => {
    'masterVolume': masterVolume,
    'musicVolume': musicVolume,
    'effectsVolume': effectsVolume,
    'musicEnabled': musicEnabled,
    'effectsEnabled': effectsEnabled,
  };

  factory AudioSettings.fromJson(Map<String, Object?> json) {
    double volume(String key) {
      final value = json[key];
      return value is num && value.isFinite ? value.clamp(0, 1).toDouble() : 1;
    }

    return AudioSettings(
      masterVolume: volume('masterVolume'),
      musicVolume: volume('musicVolume'),
      effectsVolume: volume('effectsVolume'),
      musicEnabled: json['musicEnabled'] != false,
      effectsEnabled: json['effectsEnabled'] != false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AudioSettings &&
      other.masterVolume == masterVolume &&
      other.musicVolume == musicVolume &&
      other.effectsVolume == effectsVolume &&
      other.musicEnabled == musicEnabled &&
      other.effectsEnabled == effectsEnabled;

  @override
  int get hashCode => Object.hash(
    masterVolume,
    musicVolume,
    effectsVolume,
    musicEnabled,
    effectsEnabled,
  );
}
