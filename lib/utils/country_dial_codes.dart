class CountryDialCode {
  final String name;
  final String dialCode;
  final String flag;

  const CountryDialCode({
    required this.name,
    required this.dialCode,
    required this.flag,
  });
}

class PhoneLengthRule {
  final int min;
  final int max;

  const PhoneLengthRule({required this.min, required this.max});
}

const PhoneLengthRule _defaultPhoneLengthRule =
    PhoneLengthRule(min: 9, max: 15);

const Map<String, PhoneLengthRule> _phoneLengthRulesByCountryName = {
  'Australia': PhoneLengthRule(min: 9, max: 9),
  'United Arab Emirates': PhoneLengthRule(min: 9, max: 9),
  'Canada': PhoneLengthRule(min: 10, max: 10),
  'Germany': PhoneLengthRule(min: 10, max: 11),
  'France': PhoneLengthRule(min: 9, max: 9),
  'United Kingdom': PhoneLengthRule(min: 10, max: 11),
  'Ireland': PhoneLengthRule(min: 9, max: 10),
  'India': PhoneLengthRule(min: 10, max: 10),
  'Sri Lanka': PhoneLengthRule(min: 9, max: 9),
  'Malaysia': PhoneLengthRule(min: 9, max: 10),
  'New Zealand': PhoneLengthRule(min: 8, max: 9),
  'Pakistan': PhoneLengthRule(min: 10, max: 10),
  'Singapore': PhoneLengthRule(min: 8, max: 8),
  'United States': PhoneLengthRule(min: 10, max: 10),
  'South Africa': PhoneLengthRule(min: 9, max: 9),
};

const List<CountryDialCode> countryDialCodes = [
  CountryDialCode(name: 'Australia', dialCode: '+61', flag: '🇦🇺'),
  CountryDialCode(name: 'Sri Lanka', dialCode: '+94', flag: '🇱🇰'),
  CountryDialCode(name: 'United States', dialCode: '+1', flag: '🇺🇸'),
  CountryDialCode(name: 'India', dialCode: '+91', flag: '🇮🇳'),
  CountryDialCode(name: 'United Kingdom', dialCode: '+44', flag: '🇬🇧'),
  CountryDialCode(name: 'New Zealand', dialCode: '+64', flag: '🇳🇿'),
  CountryDialCode(name: 'Canada', dialCode: '+1', flag: '🇨🇦'),
  CountryDialCode(name: 'Afghanistan', dialCode: '+93', flag: '🇦🇫'),
  CountryDialCode(name: 'Aland Islands', dialCode: '+358', flag: '🇦🇽'),
  CountryDialCode(name: 'Albania', dialCode: '+355', flag: '🇦🇱'),
  CountryDialCode(name: 'Algeria', dialCode: '+213', flag: '🇩🇿'),
  CountryDialCode(name: 'American Samoa', dialCode: '+1684', flag: '🇦🇸'),
  CountryDialCode(name: 'Andorra', dialCode: '+376', flag: '🇦🇩'),
  CountryDialCode(name: 'Angola', dialCode: '+244', flag: '🇦🇴'),
  CountryDialCode(name: 'Anguilla', dialCode: '+1264', flag: '🇦🇮'),
  CountryDialCode(name: 'Antarctica', dialCode: '+672', flag: '🇦🇶'),
  CountryDialCode(name: 'Antigua and Barbuda', dialCode: '+1268', flag: '🇦🇬'),
  CountryDialCode(name: 'Argentina', dialCode: '+54', flag: '🇦🇷'),
  CountryDialCode(name: 'Armenia', dialCode: '+374', flag: '🇦🇲'),
  CountryDialCode(name: 'Ascension Island', dialCode: '+247', flag: '🇦🇨'),
  CountryDialCode(name: 'Aruba', dialCode: '+297', flag: '🇦🇼'),
  CountryDialCode(name: 'Austria', dialCode: '+43', flag: '🇦🇹'),
  CountryDialCode(name: 'Azerbaijan', dialCode: '+994', flag: '🇦🇿'),
  CountryDialCode(name: 'Bahamas', dialCode: '+1242', flag: '🇧🇸'),
  CountryDialCode(name: 'Bahrain', dialCode: '+973', flag: '🇧🇭'),
  CountryDialCode(name: 'Bangladesh', dialCode: '+880', flag: '🇧🇩'),
  CountryDialCode(name: 'Barbados', dialCode: '+1246', flag: '🇧🇧'),
  CountryDialCode(name: 'Belarus', dialCode: '+375', flag: '🇧🇾'),
  CountryDialCode(name: 'Belgium', dialCode: '+32', flag: '🇧🇪'),
  CountryDialCode(name: 'Belize', dialCode: '+501', flag: '🇧🇿'),
  CountryDialCode(name: 'Benin', dialCode: '+229', flag: '🇧🇯'),
  CountryDialCode(name: 'Bermuda', dialCode: '+1441', flag: '🇧🇲'),
  CountryDialCode(name: 'Bhutan', dialCode: '+975', flag: '🇧🇹'),
  CountryDialCode(name: 'Bolivia', dialCode: '+591', flag: '🇧🇴'),
  CountryDialCode(
      name: 'Bosnia and Herzegovina', dialCode: '+387', flag: '🇧🇦'),
  CountryDialCode(name: 'Botswana', dialCode: '+267', flag: '🇧🇼'),
  CountryDialCode(name: 'Brazil', dialCode: '+55', flag: '🇧🇷'),
  CountryDialCode(
      name: 'British Virgin Islands', dialCode: '+1284', flag: '🇻🇬'),
  CountryDialCode(
      name: 'British Indian Ocean Territory', dialCode: '+246', flag: '🇮🇴'),
  CountryDialCode(name: 'Brunei', dialCode: '+673', flag: '🇧🇳'),
  CountryDialCode(name: 'Bulgaria', dialCode: '+359', flag: '🇧🇬'),
  CountryDialCode(name: 'Burkina Faso', dialCode: '+226', flag: '🇧🇫'),
  CountryDialCode(name: 'Burundi', dialCode: '+257', flag: '🇧🇮'),
  CountryDialCode(name: 'Cambodia', dialCode: '+855', flag: '🇰🇭'),
  CountryDialCode(name: 'Cameroon', dialCode: '+237', flag: '🇨🇲'),
  CountryDialCode(
      name: 'Caribbean Netherlands', dialCode: '+599', flag: '🇧🇶'),
  CountryDialCode(name: 'Cape Verde', dialCode: '+238', flag: '🇨🇻'),
  CountryDialCode(name: 'Cayman Islands', dialCode: '+1345', flag: '🇰🇾'),
  CountryDialCode(
      name: 'Central African Republic', dialCode: '+236', flag: '🇨🇫'),
  CountryDialCode(name: 'Chad', dialCode: '+235', flag: '🇹🇩'),
  CountryDialCode(name: 'Chile', dialCode: '+56', flag: '🇨🇱'),
  CountryDialCode(name: 'China', dialCode: '+86', flag: '🇨🇳'),
  CountryDialCode(name: 'Christmas Island', dialCode: '+61', flag: '🇨🇽'),
  CountryDialCode(name: 'Cocos Islands', dialCode: '+61', flag: '🇨🇨'),
  CountryDialCode(name: 'Colombia', dialCode: '+57', flag: '🇨🇴'),
  CountryDialCode(name: 'Comoros', dialCode: '+269', flag: '🇰🇲'),
  CountryDialCode(name: 'Cook Islands', dialCode: '+682', flag: '🇨🇰'),
  CountryDialCode(name: 'Costa Rica', dialCode: '+506', flag: '🇨🇷'),
  CountryDialCode(name: 'Croatia', dialCode: '+385', flag: '🇭🇷'),
  CountryDialCode(name: 'Cuba', dialCode: '+53', flag: '🇨🇺'),
  CountryDialCode(name: 'Curacao', dialCode: '+599', flag: '🇨🇼'),
  CountryDialCode(name: 'Cyprus', dialCode: '+357', flag: '🇨🇾'),
  CountryDialCode(name: 'Czech Republic', dialCode: '+420', flag: '🇨🇿'),
  CountryDialCode(
      name: 'Democratic Republic of the Congo', dialCode: '+243', flag: '🇨🇩'),
  CountryDialCode(name: 'Denmark', dialCode: '+45', flag: '🇩🇰'),
  CountryDialCode(name: 'Djibouti', dialCode: '+253', flag: '🇩🇯'),
  CountryDialCode(name: 'Dominica', dialCode: '+1767', flag: '🇩🇲'),
  CountryDialCode(name: 'Dominican Republic', dialCode: '+1809', flag: '🇩🇴'),
  CountryDialCode(name: 'Dominican Republic', dialCode: '+1829', flag: '🇩🇴'),
  CountryDialCode(name: 'Dominican Republic', dialCode: '+1849', flag: '🇩🇴'),
  CountryDialCode(name: 'Ecuador', dialCode: '+593', flag: '🇪🇨'),
  CountryDialCode(name: 'Egypt', dialCode: '+20', flag: '🇪🇬'),
  CountryDialCode(name: 'El Salvador', dialCode: '+503', flag: '🇸🇻'),
  CountryDialCode(name: 'Equatorial Guinea', dialCode: '+240', flag: '🇬🇶'),
  CountryDialCode(name: 'Eritrea', dialCode: '+291', flag: '🇪🇷'),
  CountryDialCode(name: 'Estonia', dialCode: '+372', flag: '🇪🇪'),
  CountryDialCode(name: 'Eswatini', dialCode: '+268', flag: '🇸🇿'),
  CountryDialCode(name: 'Ethiopia', dialCode: '+251', flag: '🇪🇹'),
  CountryDialCode(name: 'Falkland Islands', dialCode: '+500', flag: '🇫🇰'),
  CountryDialCode(name: 'Faroe Islands', dialCode: '+298', flag: '🇫🇴'),
  CountryDialCode(name: 'Fiji', dialCode: '+679', flag: '🇫🇯'),
  CountryDialCode(name: 'Finland', dialCode: '+358', flag: '🇫🇮'),
  CountryDialCode(name: 'France', dialCode: '+33', flag: '🇫🇷'),
  CountryDialCode(name: 'French Guiana', dialCode: '+594', flag: '🇬🇫'),
  CountryDialCode(name: 'French Polynesia', dialCode: '+689', flag: '🇵🇫'),
  CountryDialCode(name: 'Gabon', dialCode: '+241', flag: '🇬🇦'),
  CountryDialCode(name: 'Gambia', dialCode: '+220', flag: '🇬🇲'),
  CountryDialCode(name: 'Georgia', dialCode: '+995', flag: '🇬🇪'),
  CountryDialCode(name: 'Germany', dialCode: '+49', flag: '🇩🇪'),
  CountryDialCode(name: 'Ghana', dialCode: '+233', flag: '🇬🇭'),
  CountryDialCode(name: 'Gibraltar', dialCode: '+350', flag: '🇬🇮'),
  CountryDialCode(name: 'Greece', dialCode: '+30', flag: '🇬🇷'),
  CountryDialCode(name: 'Greenland', dialCode: '+299', flag: '🇬🇱'),
  CountryDialCode(name: 'Grenada', dialCode: '+1473', flag: '🇬🇩'),
  CountryDialCode(name: 'Guadeloupe', dialCode: '+590', flag: '🇬🇵'),
  CountryDialCode(name: 'Guam', dialCode: '+1671', flag: '🇬🇺'),
  CountryDialCode(name: 'Guatemala', dialCode: '+502', flag: '🇬🇹'),
  CountryDialCode(name: 'Guernsey', dialCode: '+44', flag: '🇬🇬'),
  CountryDialCode(name: 'Guinea', dialCode: '+224', flag: '🇬🇳'),
  CountryDialCode(name: 'Guinea-Bissau', dialCode: '+245', flag: '🇬🇼'),
  CountryDialCode(name: 'Guyana', dialCode: '+592', flag: '🇬🇾'),
  CountryDialCode(name: 'Haiti', dialCode: '+509', flag: '🇭🇹'),
  CountryDialCode(name: 'Honduras', dialCode: '+504', flag: '🇭🇳'),
  CountryDialCode(name: 'Hong Kong', dialCode: '+852', flag: '🇭🇰'),
  CountryDialCode(name: 'Hungary', dialCode: '+36', flag: '🇭🇺'),
  CountryDialCode(name: 'Iceland', dialCode: '+354', flag: '🇮🇸'),
  CountryDialCode(name: 'Indonesia', dialCode: '+62', flag: '🇮🇩'),
  CountryDialCode(name: 'Iran', dialCode: '+98', flag: '🇮🇷'),
  CountryDialCode(name: 'Iraq', dialCode: '+964', flag: '🇮🇶'),
  CountryDialCode(name: 'Ireland', dialCode: '+353', flag: '🇮🇪'),
  CountryDialCode(name: 'Isle of Man', dialCode: '+44', flag: '🇮🇲'),
  CountryDialCode(name: 'Israel', dialCode: '+972', flag: '🇮🇱'),
  CountryDialCode(name: 'Italy', dialCode: '+39', flag: '🇮🇹'),
  CountryDialCode(name: 'Ivory Coast', dialCode: '+225', flag: '🇨🇮'),
  CountryDialCode(name: 'Jamaica', dialCode: '+1876', flag: '🇯🇲'),
  CountryDialCode(name: 'Japan', dialCode: '+81', flag: '🇯🇵'),
  CountryDialCode(name: 'Jersey', dialCode: '+44', flag: '🇯🇪'),
  CountryDialCode(name: 'Jordan', dialCode: '+962', flag: '🇯🇴'),
  CountryDialCode(name: 'Kazakhstan', dialCode: '+7', flag: '🇰🇿'),
  CountryDialCode(name: 'Kenya', dialCode: '+254', flag: '🇰🇪'),
  CountryDialCode(name: 'Kiribati', dialCode: '+686', flag: '🇰🇮'),
  CountryDialCode(name: 'Kosovo', dialCode: '+383', flag: '🇽🇰'),
  CountryDialCode(name: 'Kuwait', dialCode: '+965', flag: '🇰🇼'),
  CountryDialCode(name: 'Kyrgyzstan', dialCode: '+996', flag: '🇰🇬'),
  CountryDialCode(name: 'Laos', dialCode: '+856', flag: '🇱🇦'),
  CountryDialCode(name: 'Latvia', dialCode: '+371', flag: '🇱🇻'),
  CountryDialCode(name: 'Lebanon', dialCode: '+961', flag: '🇱🇧'),
  CountryDialCode(name: 'Lesotho', dialCode: '+266', flag: '🇱🇸'),
  CountryDialCode(name: 'Liberia', dialCode: '+231', flag: '🇱🇷'),
  CountryDialCode(name: 'Libya', dialCode: '+218', flag: '🇱🇾'),
  CountryDialCode(name: 'Liechtenstein', dialCode: '+423', flag: '🇱🇮'),
  CountryDialCode(name: 'Lithuania', dialCode: '+370', flag: '🇱🇹'),
  CountryDialCode(name: 'Luxembourg', dialCode: '+352', flag: '🇱🇺'),
  CountryDialCode(name: 'Macau', dialCode: '+853', flag: '🇲🇴'),
  CountryDialCode(name: 'Madagascar', dialCode: '+261', flag: '🇲🇬'),
  CountryDialCode(name: 'Malawi', dialCode: '+265', flag: '🇲🇼'),
  CountryDialCode(name: 'Malaysia', dialCode: '+60', flag: '🇲🇾'),
  CountryDialCode(name: 'Maldives', dialCode: '+960', flag: '🇲🇻'),
  CountryDialCode(name: 'Mali', dialCode: '+223', flag: '🇲🇱'),
  CountryDialCode(name: 'Malta', dialCode: '+356', flag: '🇲🇹'),
  CountryDialCode(name: 'Marshall Islands', dialCode: '+692', flag: '🇲🇭'),
  CountryDialCode(name: 'Martinique', dialCode: '+596', flag: '🇲🇶'),
  CountryDialCode(name: 'Mauritania', dialCode: '+222', flag: '🇲🇷'),
  CountryDialCode(name: 'Mauritius', dialCode: '+230', flag: '🇲🇺'),
  CountryDialCode(name: 'Mayotte', dialCode: '+262', flag: '🇾🇹'),
  CountryDialCode(name: 'Mexico', dialCode: '+52', flag: '🇲🇽'),
  CountryDialCode(name: 'Micronesia', dialCode: '+691', flag: '🇫🇲'),
  CountryDialCode(name: 'Moldova', dialCode: '+373', flag: '🇲🇩'),
  CountryDialCode(name: 'Monaco', dialCode: '+377', flag: '🇲🇨'),
  CountryDialCode(name: 'Mongolia', dialCode: '+976', flag: '🇲🇳'),
  CountryDialCode(name: 'Montenegro', dialCode: '+382', flag: '🇲🇪'),
  CountryDialCode(name: 'Montserrat', dialCode: '+1664', flag: '🇲🇸'),
  CountryDialCode(name: 'Morocco', dialCode: '+212', flag: '🇲🇦'),
  CountryDialCode(name: 'Mozambique', dialCode: '+258', flag: '🇲🇿'),
  CountryDialCode(name: 'Myanmar', dialCode: '+95', flag: '🇲🇲'),
  CountryDialCode(name: 'Namibia', dialCode: '+264', flag: '🇳🇦'),
  CountryDialCode(name: 'Nauru', dialCode: '+674', flag: '🇳🇷'),
  CountryDialCode(name: 'Nepal', dialCode: '+977', flag: '🇳🇵'),
  CountryDialCode(name: 'Netherlands', dialCode: '+31', flag: '🇳🇱'),
  CountryDialCode(name: 'New Caledonia', dialCode: '+687', flag: '🇳🇨'),
  CountryDialCode(name: 'Nicaragua', dialCode: '+505', flag: '🇳🇮'),
  CountryDialCode(name: 'Niger', dialCode: '+227', flag: '🇳🇪'),
  CountryDialCode(name: 'Nigeria', dialCode: '+234', flag: '🇳🇬'),
  CountryDialCode(name: 'Niue', dialCode: '+683', flag: '🇳🇺'),
  CountryDialCode(name: 'North Korea', dialCode: '+850', flag: '🇰🇵'),
  CountryDialCode(name: 'North Macedonia', dialCode: '+389', flag: '🇲🇰'),
  CountryDialCode(
      name: 'Northern Mariana Islands', dialCode: '+1670', flag: '🇲🇵'),
  CountryDialCode(name: 'Norway', dialCode: '+47', flag: '🇳🇴'),
  CountryDialCode(name: 'Norfolk Island', dialCode: '+672', flag: '🇳🇫'),
  CountryDialCode(name: 'Oman', dialCode: '+968', flag: '🇴🇲'),
  CountryDialCode(name: 'Pakistan', dialCode: '+92', flag: '🇵🇰'),
  CountryDialCode(name: 'Palau', dialCode: '+680', flag: '🇵🇼'),
  CountryDialCode(name: 'Palestine', dialCode: '+970', flag: '🇵🇸'),
  CountryDialCode(name: 'Panama', dialCode: '+507', flag: '🇵🇦'),
  CountryDialCode(name: 'Papua New Guinea', dialCode: '+675', flag: '🇵🇬'),
  CountryDialCode(name: 'Paraguay', dialCode: '+595', flag: '🇵🇾'),
  CountryDialCode(name: 'Peru', dialCode: '+51', flag: '🇵🇪'),
  CountryDialCode(name: 'Philippines', dialCode: '+63', flag: '🇵🇭'),
  CountryDialCode(name: 'Pitcairn Islands', dialCode: '+64', flag: '🇵🇳'),
  CountryDialCode(name: 'Poland', dialCode: '+48', flag: '🇵🇱'),
  CountryDialCode(name: 'Portugal', dialCode: '+351', flag: '🇵🇹'),
  CountryDialCode(name: 'Puerto Rico', dialCode: '+1787', flag: '🇵🇷'),
  CountryDialCode(name: 'Puerto Rico', dialCode: '+1939', flag: '🇵🇷'),
  CountryDialCode(name: 'Qatar', dialCode: '+974', flag: '🇶🇦'),
  CountryDialCode(
      name: 'Republic of the Congo', dialCode: '+242', flag: '🇨🇬'),
  CountryDialCode(name: 'Reunion', dialCode: '+262', flag: '🇷🇪'),
  CountryDialCode(name: 'Romania', dialCode: '+40', flag: '🇷🇴'),
  CountryDialCode(name: 'Russia', dialCode: '+7', flag: '🇷🇺'),
  CountryDialCode(name: 'Rwanda', dialCode: '+250', flag: '🇷🇼'),
  CountryDialCode(name: 'Saint Barthelemy', dialCode: '+590', flag: '🇧🇱'),
  CountryDialCode(name: 'Saint Helena', dialCode: '+290', flag: '🇸🇭'),
  CountryDialCode(
      name: 'Saint Kitts and Nevis', dialCode: '+1869', flag: '🇰🇳'),
  CountryDialCode(name: 'Saint Lucia', dialCode: '+1758', flag: '🇱🇨'),
  CountryDialCode(name: 'Saint Martin', dialCode: '+590', flag: '🇲🇫'),
  CountryDialCode(
      name: 'Saint Pierre and Miquelon', dialCode: '+508', flag: '🇵🇲'),
  CountryDialCode(
      name: 'Saint Vincent and the Grenadines',
      dialCode: '+1784',
      flag: '🇻🇨'),
  CountryDialCode(name: 'Samoa', dialCode: '+685', flag: '🇼🇸'),
  CountryDialCode(name: 'San Marino', dialCode: '+378', flag: '🇸🇲'),
  CountryDialCode(
      name: 'Sao Tome and Principe', dialCode: '+239', flag: '🇸🇹'),
  CountryDialCode(name: 'Saudi Arabia', dialCode: '+966', flag: '🇸🇦'),
  CountryDialCode(name: 'Senegal', dialCode: '+221', flag: '🇸🇳'),
  CountryDialCode(name: 'Serbia', dialCode: '+381', flag: '🇷🇸'),
  CountryDialCode(name: 'Seychelles', dialCode: '+248', flag: '🇸🇨'),
  CountryDialCode(name: 'Sierra Leone', dialCode: '+232', flag: '🇸🇱'),
  CountryDialCode(name: 'Singapore', dialCode: '+65', flag: '🇸🇬'),
  CountryDialCode(name: 'Sint Maarten', dialCode: '+1721', flag: '🇸🇽'),
  CountryDialCode(name: 'Slovakia', dialCode: '+421', flag: '🇸🇰'),
  CountryDialCode(name: 'Slovenia', dialCode: '+386', flag: '🇸🇮'),
  CountryDialCode(name: 'Solomon Islands', dialCode: '+677', flag: '🇸🇧'),
  CountryDialCode(name: 'Somalia', dialCode: '+252', flag: '🇸🇴'),
  CountryDialCode(name: 'South Africa', dialCode: '+27', flag: '🇿🇦'),
  CountryDialCode(
      name: 'South Georgia and the South Sandwich Islands',
      dialCode: '+500',
      flag: '🇬🇸'),
  CountryDialCode(name: 'South Korea', dialCode: '+82', flag: '🇰🇷'),
  CountryDialCode(name: 'South Sudan', dialCode: '+211', flag: '🇸🇸'),
  CountryDialCode(name: 'Spain', dialCode: '+34', flag: '🇪🇸'),
  CountryDialCode(name: 'Sudan', dialCode: '+249', flag: '🇸🇩'),
  CountryDialCode(name: 'Suriname', dialCode: '+597', flag: '🇸🇷'),
  CountryDialCode(name: 'Sweden', dialCode: '+46', flag: '🇸🇪'),
  CountryDialCode(name: 'Switzerland', dialCode: '+41', flag: '🇨🇭'),
  CountryDialCode(
      name: 'Svalbard and Jan Mayen', dialCode: '+47', flag: '🇸🇯'),
  CountryDialCode(name: 'Syria', dialCode: '+963', flag: '🇸🇾'),
  CountryDialCode(name: 'Taiwan', dialCode: '+886', flag: '🇹🇼'),
  CountryDialCode(name: 'Tajikistan', dialCode: '+992', flag: '🇹🇯'),
  CountryDialCode(name: 'Tanzania', dialCode: '+255', flag: '🇹🇿'),
  CountryDialCode(name: 'Thailand', dialCode: '+66', flag: '🇹🇭'),
  CountryDialCode(name: 'Timor-Leste', dialCode: '+670', flag: '🇹🇱'),
  CountryDialCode(name: 'Togo', dialCode: '+228', flag: '🇹🇬'),
  CountryDialCode(name: 'Tokelau', dialCode: '+690', flag: '🇹🇰'),
  CountryDialCode(name: 'Tonga', dialCode: '+676', flag: '🇹🇴'),
  CountryDialCode(name: 'Trinidad and Tobago', dialCode: '+1868', flag: '🇹🇹'),
  CountryDialCode(name: 'Tunisia', dialCode: '+216', flag: '🇹🇳'),
  CountryDialCode(name: 'Turkey', dialCode: '+90', flag: '🇹🇷'),
  CountryDialCode(name: 'Turkmenistan', dialCode: '+993', flag: '🇹🇲'),
  CountryDialCode(
      name: 'Turks and Caicos Islands', dialCode: '+1649', flag: '🇹🇨'),
  CountryDialCode(name: 'Tuvalu', dialCode: '+688', flag: '🇹🇻'),
  CountryDialCode(name: 'U.S. Virgin Islands', dialCode: '+1340', flag: '🇻🇮'),
  CountryDialCode(name: 'Uganda', dialCode: '+256', flag: '🇺🇬'),
  CountryDialCode(name: 'Ukraine', dialCode: '+380', flag: '🇺🇦'),
  CountryDialCode(name: 'United Arab Emirates', dialCode: '+971', flag: '🇦🇪'),
  CountryDialCode(name: 'Uruguay', dialCode: '+598', flag: '🇺🇾'),
  CountryDialCode(name: 'Uzbekistan', dialCode: '+998', flag: '🇺🇿'),
  CountryDialCode(name: 'Vanuatu', dialCode: '+678', flag: '🇻🇺'),
  CountryDialCode(name: 'Vatican City', dialCode: '+379', flag: '🇻🇦'),
  CountryDialCode(name: 'Venezuela', dialCode: '+58', flag: '🇻🇪'),
  CountryDialCode(name: 'Vietnam', dialCode: '+84', flag: '🇻🇳'),
  CountryDialCode(name: 'Wallis and Futuna', dialCode: '+681', flag: '🇼🇫'),
  CountryDialCode(name: 'Western Sahara', dialCode: '+212', flag: '🇪🇭'),
  CountryDialCode(name: 'Yemen', dialCode: '+967', flag: '🇾🇪'),
  CountryDialCode(name: 'Zambia', dialCode: '+260', flag: '🇿🇲'),
  CountryDialCode(name: 'Zimbabwe', dialCode: '+263', flag: '🇿🇼'),
];

CountryDialCode? detectCountryFromPhoneNumber(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty || !normalized.startsWith('+')) return null;

  final sorted = [...countryDialCodes]
    ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));

  for (final country in sorted) {
    if (normalized.startsWith(country.dialCode)) {
      return country;
    }
  }
  return null;
}

PhoneLengthRule phoneLengthRuleForCountryName(String? countryName) {
  if (countryName == null || countryName.trim().isEmpty) {
    return _defaultPhoneLengthRule;
  }
  return _phoneLengthRulesByCountryName[countryName.trim()] ??
      _defaultPhoneLengthRule;
}

String _normalizeNationalDigits(String digits) {
  final trimmed = digits.replaceAll(RegExp(r'^0+'), '');
  return trimmed.isEmpty ? digits : trimmed;
}

String? validateNationalPhoneNumber(
  String? value, {
  required String? countryName,
  bool optional = false,
  String requiredMessage = 'Please enter a mobile number.',
  String invalidMessage = 'Please enter a valid mobile number.',
}) {
  final rawDigits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (rawDigits.isEmpty) return optional ? null : requiredMessage;

  final phoneDigits = _normalizeNationalDigits(rawDigits);
  final rule = phoneLengthRuleForCountryName(countryName);

  if (phoneDigits.length < rule.min || phoneDigits.length > rule.max) {
    if (countryName != null && countryName.trim().isNotEmpty) {
      return 'Please enter a valid ${countryName.trim()} mobile number.';
    }
    return invalidMessage;
  }

  return null;
}

String? validateInternationalPhoneNumber(
  String? value, {
  String? countryName,
  bool optional = false,
  String requiredMessage = 'Please enter a mobile number.',
  String invalidMessage = 'Please enter a valid mobile number.',
}) {
  final phone = (value ?? '').trim().replaceAll(RegExp(r'[\s\-()]'), '');
  if (phone.isEmpty) return optional ? null : requiredMessage;

  final detectedCountry = detectCountryFromPhoneNumber(phone);
  final effectiveCountryName =
      (countryName != null && countryName.trim().isNotEmpty)
          ? countryName.trim()
          : detectedCountry?.name;

  final allDigits = phone.replaceAll(RegExp(r'\D'), '');
  var nationalDigits = allDigits;

  if (detectedCountry != null) {
    final dialDigits = detectedCountry.dialCode.replaceAll(RegExp(r'\D'), '');
    if (allDigits.startsWith(dialDigits)) {
      nationalDigits = allDigits.substring(dialDigits.length);
    }
  }

  nationalDigits = _normalizeNationalDigits(nationalDigits);

  final rule = phoneLengthRuleForCountryName(effectiveCountryName);
  if (nationalDigits.length < rule.min || nationalDigits.length > rule.max) {
    if (effectiveCountryName != null && effectiveCountryName.isNotEmpty) {
      return 'Please enter a valid $effectiveCountryName mobile number.';
    }
    return invalidMessage;
  }

  return null;
}
