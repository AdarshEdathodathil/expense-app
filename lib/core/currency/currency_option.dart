class CurrencyOption {
  const CurrencyOption({
    required this.code,
    required this.country,
    required this.name,
    required this.symbol,
    required this.flag,
  });

  final String code;
  final String country;
  final String name;
  final String symbol;
  final String flag;

  String get label => '$country — $name';
  String get detail => '$code · $symbol';
}

const supportedCurrencies = <CurrencyOption>[
  CurrencyOption(
    code: 'INR',
    country: 'India',
    name: 'Indian Rupee',
    symbol: '₹',
    flag: '🇮🇳',
  ),
  CurrencyOption(
    code: 'USD',
    country: 'United States',
    name: 'US Dollar',
    symbol: r'$',
    flag: '🇺🇸',
  ),
  CurrencyOption(
    code: 'EUR',
    country: 'European Union',
    name: 'Euro',
    symbol: '€',
    flag: '🇪🇺',
  ),
  CurrencyOption(
    code: 'GBP',
    country: 'United Kingdom',
    name: 'British Pound',
    symbol: '£',
    flag: '🇬🇧',
  ),
  CurrencyOption(
    code: 'AED',
    country: 'United Arab Emirates',
    name: 'UAE Dirham',
    symbol: 'د.إ',
    flag: '🇦🇪',
  ),
  CurrencyOption(
    code: 'AUD',
    country: 'Australia',
    name: 'Australian Dollar',
    symbol: r'A$',
    flag: '🇦🇺',
  ),
  CurrencyOption(
    code: 'BHD',
    country: 'Bahrain',
    name: 'Bahraini Dinar',
    symbol: 'د.ب',
    flag: '🇧🇭',
  ),
  CurrencyOption(
    code: 'BRL',
    country: 'Brazil',
    name: 'Brazilian Real',
    symbol: r'R$',
    flag: '🇧🇷',
  ),
  CurrencyOption(
    code: 'CAD',
    country: 'Canada',
    name: 'Canadian Dollar',
    symbol: r'C$',
    flag: '🇨🇦',
  ),
  CurrencyOption(
    code: 'JPY',
    country: 'Japan',
    name: 'Japanese Yen',
    symbol: '¥',
    flag: '🇯🇵',
  ),
  CurrencyOption(
    code: 'SAR',
    country: 'Saudi Arabia',
    name: 'Saudi Riyal',
    symbol: 'ر.س',
    flag: '🇸🇦',
  ),
  CurrencyOption(
    code: 'SGD',
    country: 'Singapore',
    name: 'Singapore Dollar',
    symbol: r'S$',
    flag: '🇸🇬',
  ),
];

CurrencyOption currencyOption(String code) => supportedCurrencies.firstWhere(
  (currency) => currency.code == code,
  orElse: () => supportedCurrencies.first,
);
