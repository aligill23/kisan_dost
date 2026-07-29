class PakistanLocations {
  static const Map<String, List<String>> provinces = {
    'پنجاب': [
      'پاکپتن',
      'ساہیوال',
      'اوکاڑہ',
      'لاہور',
      'قصور',
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
    'لاہور': [
      'رائیونڈ',
      'اقبال ٹاؤن',
      'نشتر',
      'ماڈل ٹاؤن',
      'لاہور کینٹ',
      'صدر',
      'واہگہ',
      'شالیمار',
      'راوی',
      'لاہور سٹی',
    ],
    'قصور': [
      'قصور',
      'چونیاں',
      'پتوکی',
      'کوٹ رادھا کشن',
    ],
  };

  static List<String> getDistricts(String province) {
    return provinces[province] ?? [];
  }

  static List<String> getTehsils(String district) {
    return tehsils[district] ?? [district];
  }
}
