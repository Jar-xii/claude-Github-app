/**
 * Timezone alias map: common names/abbreviations → IANA timezone names
 *
 * KNOWN AMBIGUITIES — use the explicit aliases listed below to avoid wrong results:
 *   IST  → Asia/Kolkata (India). For Ireland use Europe/Dublin, for Israel use Asia/Jerusalem.
 *   CST  → America/Chicago (US Central). For China use SHANGHAI or CHINA.
 *   AST  → Asia/Dubai (Arabia). For Atlantic use HALIFAX or America/Halifax.
 *   BST  → Europe/London (British Summer). Note: luxon uses the geographic zone
 *          Europe/London so DST is applied automatically — BST in winter resolves
 *          to GMT+0, BST in summer resolves to GMT+1. This is intentional.
 */

'use strict';

const { IANAZone } = require('luxon');

const ALIASES = {
  // ── United Kingdom / Ireland ─────────────────────────────────────────────
  UK:              'Europe/London',
  GB:              'Europe/London',
  BST:             'Europe/London',   // British Summer Time — geographic zone handles DST
  ENGLAND:         'Europe/London',
  SCOTLAND:        'Europe/London',
  WALES:           'Europe/London',
  IRELAND:         'Europe/Dublin',
  EIRE:            'Europe/Dublin',

  // ── UTC / GMT ─────────────────────────────────────────────────────────────
  UTC:             'UTC',
  GMT:             'UTC',
  Z:               'UTC',
  'GMT+0':         'UTC',
  'UTC+0':         'UTC',

  // ── Europe — Western ──────────────────────────────────────────────────────
  WET:             'Europe/Lisbon',
  LISBON:          'Europe/Lisbon',
  PORTUGAL:        'Europe/Lisbon',
  PARIS:           'Europe/Paris',
  FRANCE:          'Europe/Paris',
  CET:             'Europe/Paris',
  CEST:            'Europe/Paris',
  BERLIN:          'Europe/Berlin',
  GERMANY:         'Europe/Berlin',
  AMSTERDAM:       'Europe/Amsterdam',
  NETHERLANDS:     'Europe/Amsterdam',
  BRUSSELS:        'Europe/Brussels',
  BELGIUM:         'Europe/Brussels',
  MADRID:          'Europe/Madrid',
  SPAIN:           'Europe/Madrid',
  ROME:            'Europe/Rome',
  MILAN:           'Europe/Rome',
  ITALY:           'Europe/Rome',
  ZURICH:          'Europe/Zurich',
  SWITZERLAND:     'Europe/Zurich',
  VIENNA:          'Europe/Vienna',
  AUSTRIA:         'Europe/Vienna',
  PRAGUE:          'Europe/Prague',
  WARSAW:          'Europe/Warsaw',
  POLAND:          'Europe/Warsaw',

  // ── Europe — Northern ─────────────────────────────────────────────────────
  STOCKHOLM:       'Europe/Stockholm',
  SWEDEN:          'Europe/Stockholm',
  OSLO:            'Europe/Oslo',
  NORWAY:          'Europe/Oslo',
  COPENHAGEN:      'Europe/Copenhagen',
  DENMARK:         'Europe/Copenhagen',
  HELSINKI:        'Europe/Helsinki',
  FINLAND:         'Europe/Helsinki',

  // ── Europe — Eastern ──────────────────────────────────────────────────────
  EET:             'Europe/Athens',
  EEST:            'Europe/Athens',
  ATHENS:          'Europe/Athens',
  GREECE:          'Europe/Athens',
  BUCHAREST:       'Europe/Bucharest',
  ROMANIA:         'Europe/Bucharest',
  SOFIA:           'Europe/Sofia',
  BULGARIA:        'Europe/Sofia',
  ISTANBUL:        'Europe/Istanbul',
  TURKEY:          'Europe/Istanbul',
  KYIV:            'Europe/Kyiv',
  KIEV:            'Europe/Kyiv',
  UKRAINE:         'Europe/Kyiv',

  // ── Europe — Russia ───────────────────────────────────────────────────────
  MSK:             'Europe/Moscow',
  MOSCOW:          'Europe/Moscow',
  RUSSIA:          'Europe/Moscow',

  // ── North America — Eastern ───────────────────────────────────────────────
  EST:             'America/New_York',
  EDT:             'America/New_York',
  ET:              'America/New_York',
  EASTERN:         'America/New_York',
  'NEW YORK':      'America/New_York',
  NYC:             'America/New_York',
  TORONTO:         'America/Toronto',
  MONTREAL:        'America/Montreal',
  MIAMI:           'America/New_York',
  BOSTON:          'America/New_York',
  PHILADELPHIA:    'America/New_York',
  ATLANTA:         'America/New_York',

  // ── North America — Central ───────────────────────────────────────────────
  CST:             'America/Chicago',
  CDT:             'America/Chicago',
  CT:              'America/Chicago',
  CENTRAL:         'America/Chicago',
  CHICAGO:         'America/Chicago',
  DALLAS:          'America/Chicago',
  HOUSTON:         'America/Chicago',
  MINNEAPOLIS:     'America/Chicago',
  WINNIPEG:        'America/Winnipeg',

  // ── North America — Mountain ──────────────────────────────────────────────
  MST:             'America/Denver',
  MDT:             'America/Denver',
  MT:              'America/Denver',
  MOUNTAIN:        'America/Denver',
  DENVER:          'America/Denver',
  PHOENIX:         'America/Phoenix',  // No DST
  CALGARY:         'America/Edmonton',
  EDMONTON:        'America/Edmonton',

  // ── North America — Pacific ───────────────────────────────────────────────
  PST:             'America/Los_Angeles',
  PDT:             'America/Los_Angeles',
  PT:              'America/Los_Angeles',
  PACIFIC:         'America/Los_Angeles',
  LA:              'America/Los_Angeles',
  'LOS ANGELES':   'America/Los_Angeles',
  SF:              'America/Los_Angeles',
  'SAN FRANCISCO': 'America/Los_Angeles',
  SEATTLE:         'America/Seattle',
  PORTLAND:        'America/Los_Angeles',
  VANCOUVER:       'America/Vancouver',

  // ── North America — Alaska / Hawaii ──────────────────────────────────────
  AKST:            'America/Anchorage',
  AKDT:            'America/Anchorage',
  ALASKA:          'America/Anchorage',
  HST:             'Pacific/Honolulu',
  HAWAII:          'Pacific/Honolulu',

  // ── Middle East ───────────────────────────────────────────────────────────
  AST:             'Asia/Dubai',       // Arabia Standard Time (see ambiguity note)
  DUBAI:           'Asia/Dubai',
  UAE:             'Asia/Dubai',
  RIYADH:          'Asia/Riyadh',
  SAUDI:           'Asia/Riyadh',
  KUWAIT:          'Asia/Kuwait',
  DOHA:            'Asia/Qatar',
  QATAR:           'Asia/Qatar',
  BAHRAIN:         'Asia/Bahrain',
  TEHRAN:          'Asia/Tehran',
  IRAN:            'Asia/Tehran',
  IRST:            'Asia/Tehran',
  ISRAEL:          'Asia/Jerusalem',
  JERUSALEM:       'Asia/Jerusalem',
  TEL_AVIV:        'Asia/Jerusalem',
  AMMAN:           'Asia/Amman',
  JORDAN:          'Asia/Amman',
  BEIRUT:          'Asia/Beirut',
  LEBANON:         'Asia/Beirut',
  BAGHDAD:         'Asia/Baghdad',
  IRAQ:            'Asia/Baghdad',

  // ── Africa ────────────────────────────────────────────────────────────────
  CAIRO:           'Africa/Cairo',
  EGYPT:           'Africa/Cairo',
  EET_CAIRO:       'Africa/Cairo',
  JOHANNESBURG:    'Africa/Johannesburg',
  SAST:            'Africa/Johannesburg',
  'SOUTH AFRICA':  'Africa/Johannesburg',
  NAIROBI:         'Africa/Nairobi',
  EAT:             'Africa/Nairobi',
  KENYA:           'Africa/Nairobi',
  LAGOS:           'Africa/Lagos',
  WAT:             'Africa/Lagos',
  NIGERIA:         'Africa/Lagos',
  ACCRA:           'Africa/Accra',
  GHANA:           'Africa/Accra',
  CASABLANCA:      'Africa/Casablanca',
  MOROCCO:         'Africa/Casablanca',
  ADDIS_ABABA:     'Africa/Addis_Ababa',
  ETHIOPIA:        'Africa/Addis_Ababa',
  TUNIS:           'Africa/Tunis',
  TUNISIA:         'Africa/Tunis',

  // ── Asia — South ──────────────────────────────────────────────────────────
  IST:             'Asia/Kolkata',     // India Standard Time (see ambiguity note)
  INDIA:           'Asia/Kolkata',
  MUMBAI:          'Asia/Kolkata',
  DELHI:           'Asia/Kolkata',
  BANGALORE:       'Asia/Kolkata',
  KOLKATA:         'Asia/Kolkata',
  CHENNAI:         'Asia/Kolkata',
  KARACHI:         'Asia/Karachi',
  PAKISTAN:        'Asia/Karachi',
  PKT:             'Asia/Karachi',
  DHAKA:           'Asia/Dhaka',
  BANGLADESH:      'Asia/Dhaka',
  BST_BD:          'Asia/Dhaka',       // Bangladesh Standard Time
  COLOMBO:         'Asia/Colombo',
  SRILANKA:        'Asia/Colombo',
  KATHMANDU:       'Asia/Kathmandu',
  NEPAL:           'Asia/Kathmandu',
  NPT:             'Asia/Kathmandu',

  // ── Asia — Southeast ─────────────────────────────────────────────────────
  BANGKOK:         'Asia/Bangkok',
  THAILAND:        'Asia/Bangkok',
  ICT:             'Asia/Bangkok',
  JAKARTA:         'Asia/Jakarta',
  INDONESIA:       'Asia/Jakarta',
  WIB:             'Asia/Jakarta',
  SINGAPORE:       'Asia/Singapore',
  SGT:             'Asia/Singapore',
  SG:              'Asia/Singapore',
  MANILA:          'Asia/Manila',
  PHILIPPINES:     'Asia/Manila',
  PHT:             'Asia/Manila',
  'KUALA LUMPUR':  'Asia/Kuala_Lumpur',
  KL:              'Asia/Kuala_Lumpur',
  MALAYSIA:        'Asia/Kuala_Lumpur',
  MYT:             'Asia/Kuala_Lumpur',
  'HO CHI MINH':   'Asia/Ho_Chi_Minh',
  SAIGON:          'Asia/Ho_Chi_Minh',
  HANOI:           'Asia/Ho_Chi_Minh',
  VIETNAM:         'Asia/Ho_Chi_Minh',
  YANGON:          'Asia/Yangon',
  MYANMAR:         'Asia/Yangon',
  MMT:             'Asia/Yangon',
  PHNOM_PENH:      'Asia/Phnom_Penh',
  CAMBODIA:        'Asia/Phnom_Penh',
  VIENTIANE:       'Asia/Vientiane',
  LAOS:            'Asia/Vientiane',

  // ── Asia — East ───────────────────────────────────────────────────────────
  TOKYO:           'Asia/Tokyo',
  JAPAN:           'Asia/Tokyo',
  JST:             'Asia/Tokyo',
  OSAKA:           'Asia/Tokyo',
  SEOUL:           'Asia/Seoul',
  KOREA:           'Asia/Seoul',
  KST:             'Asia/Seoul',
  BEIJING:         'Asia/Shanghai',
  SHANGHAI:        'Asia/Shanghai',
  CHINA:           'Asia/Shanghai',
  CST_CHINA:       'Asia/Shanghai',    // Explicit alias to avoid CST ambiguity
  'HONG KONG':     'Asia/Hong_Kong',
  HK:              'Asia/Hong_Kong',
  HKT:             'Asia/Hong_Kong',
  TAIPEI:          'Asia/Taipei',
  TAIWAN:          'Asia/Taipei',
  TWN:             'Asia/Taipei',
  ULAANBAATAR:     'Asia/Ulaanbaatar',
  MONGOLIA:        'Asia/Ulaanbaatar',

  // ── Australia / Pacific ───────────────────────────────────────────────────
  SYDNEY:          'Australia/Sydney',
  AEST:            'Australia/Sydney',
  AEDT:            'Australia/Sydney',
  MELBOURNE:       'Australia/Melbourne',
  BRISBANE:        'Australia/Brisbane',
  PERTH:           'Australia/Perth',
  AWST:            'Australia/Perth',
  ADELAIDE:        'Australia/Adelaide',
  ACST:            'Australia/Adelaide',
  ACDT:            'Australia/Adelaide',
  DARWIN:          'Australia/Darwin',
  AUCKLAND:        'Pacific/Auckland',
  'NEW ZEALAND':   'Pacific/Auckland',
  NZST:            'Pacific/Auckland',
  NZDT:            'Pacific/Auckland',
  WELLINGTON:      'Pacific/Auckland',
  FIJI:            'Pacific/Fiji',
  FJT:             'Pacific/Fiji',
  GUAM:            'Pacific/Guam',
  CHST:            'Pacific/Guam',

  // ── South America ─────────────────────────────────────────────────────────
  'SAO PAULO':     'America/Sao_Paulo',
  BRAZIL:          'America/Sao_Paulo',
  BRT:             'America/Sao_Paulo',
  'BUENOS AIRES':  'America/Argentina/Buenos_Aires',
  ARGENTINA:       'America/Argentina/Buenos_Aires',
  ART:             'America/Argentina/Buenos_Aires',
  BOGOTA:          'America/Bogota',
  COLOMBIA:        'America/Bogota',
  COT:             'America/Bogota',
  LIMA:            'America/Lima',
  PERU:            'America/Lima',
  PET:             'America/Lima',
  SANTIAGO:        'America/Santiago',
  CHILE:           'America/Santiago',
  CLT:             'America/Santiago',
  CARACAS:         'America/Caracas',
  VENEZUELA:       'America/Caracas',
  VET:             'America/Caracas',
  QUITO:           'America/Guayaquil',
  ECUADOR:         'America/Guayaquil',
  ECT:             'America/Guayaquil',
  LA_PAZ:          'America/La_Paz',
  BOLIVIA:         'America/La_Paz',
  BOT:             'America/La_Paz',
  ASUNCION:        'America/Asuncion',
  PARAGUAY:        'America/Asuncion',
  MONTEVIDEO:      'America/Montevideo',
  URUGUAY:         'America/Montevideo',
  UYT:             'America/Montevideo',

  // ── Mexico / Central America / Caribbean ─────────────────────────────────
  MEXICO:          'America/Mexico_City',
  'MEXICO CITY':   'America/Mexico_City',
  CST_MX:          'America/Mexico_City',
  GUADALAJARA:     'America/Mexico_City',
  MONTERREY:       'America/Monterrey',
  TIJUANA:         'America/Tijuana',
  CANCUN:          'America/Cancun',
  HAVANA:          'America/Havana',
  CUBA:            'America/Havana',
  JAMAICA:         'America/Jamaica',
  KINGSTON:        'America/Jamaica',
  PANAMA:          'America/Panama',
  COSTA_RICA:      'America/Costa_Rica',
  SAN_JOSE:        'America/Costa_Rica',
  HALIFAX:         'America/Halifax',
  ATLANTIC:        'America/Halifax',
  AST_ATLANTIC:    'America/Halifax',  // Explicit alias to avoid AST ambiguity
};

/**
 * Resolve a user-typed timezone string to an IANA zone name.
 * 1. Normalizes to uppercase and trims whitespace.
 * 2. Checks the alias map.
 * 3. Falls back to checking if it's a valid IANA zone name directly.
 *
 * @param {string} raw - User-provided timezone string (normalized/uppercase is fine for aliases)
 * @param {string} [rawOrig] - Optional: original-case version for IANA zone passthrough
 * @returns {string|null} IANA zone name, or null if unresolvable
 */
function resolveAlias(raw, rawOrig) {
  if (!raw || typeof raw !== 'string') return null;

  const normalized = raw.trim().toUpperCase().replace(/\s+/g, ' ');

  if (ALIASES[normalized]) {
    return ALIASES[normalized];
  }

  // Try direct IANA zone with original case (e.g. "Europe/London", "America/New_York")
  // IANA zone names are case-sensitive, so we must use original case here.
  const candidates = [];
  if (rawOrig) candidates.push(rawOrig.trim());
  candidates.push(raw.trim()); // also try as-provided (handles user passing original case directly)

  for (const candidate of candidates) {
    if (IANAZone.isValidZone(candidate)) {
      return candidate;
    }
  }

  return null;
}

/**
 * Returns an array of alias keys for autocomplete, optionally filtered by a prefix.
 * @param {string} [prefix] - Optional prefix to filter by (case-insensitive)
 * @returns {Array<{alias: string, ianaZone: string}>}
 */
function searchAliases(prefix) {
  const upper = prefix ? prefix.toUpperCase() : '';
  return Object.entries(ALIASES)
    .filter(([alias]) => !upper || alias.startsWith(upper))
    .map(([alias, ianaZone]) => ({ alias, ianaZone }))
    .slice(0, 25);
}

module.exports = { ALIASES, resolveAlias, searchAliases };
