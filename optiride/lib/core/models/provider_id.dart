enum ProviderId { uber, bolt, heetch, freenow }

extension ProviderIdX on ProviderId {
  String get displayName => switch (this) {
        ProviderId.uber => 'Uber',
        ProviderId.bolt => 'Bolt',
        ProviderId.heetch => 'Heetch',
        ProviderId.freenow => 'FREE NOW',
      };

  String get deeplinkScheme => switch (this) {
        ProviderId.uber => 'uber://',
        ProviderId.bolt => 'bolt://',
        ProviderId.heetch => 'heetch://',
        ProviderId.freenow => 'freenow://',
      };
}
