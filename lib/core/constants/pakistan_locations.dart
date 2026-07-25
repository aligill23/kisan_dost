class PakistanLocations {
  static const Map<String, List<String>> provinces = {
    'پنجاب': [
      'پاکپتن',
      'ساہیوال',
      'اوکاڑہ',
    ],
  };

  static const Map<String, List<String>> tehsils = {
    'پاکپتن': [
      'پاکپتن',
      'عارفوالا',
    ],
    'ساہیوال': [
      'ساہیوال',
      'چیچہ وطنی',
    ],
    'اوکاڑہ': [
      'اوکاڑہ',
      'دیپالپور',
      'رینالہ خورد',
    ],
  };

  static List<String> getDistricts(String province) {
    return provinces[province] ?? [];
  }

  static List<String> getTehsils(String district) {
    return tehsils[district] ?? [district];
  }
}
