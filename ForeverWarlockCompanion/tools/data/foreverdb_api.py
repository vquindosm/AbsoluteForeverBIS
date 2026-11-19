"""Reviewed, deliberately small ForeverDB API adapter. No network or credentials here.

Consumes the original quarantined envelopes. Does not infer buying requirements from
vendor side/discount faction, or a currency identity from a similarly named bag item.
Source strings are retained without Unicode cleanup or removal of attribution marks.
"""
import datetime, hashlib, json, pathlib, re
from catalog import ROOT, atomic, validate

BASE = 'https://foreverdb.net'
ITEMS = (272411, 226404, 18407, 10019)
# Only reviewed ID + label pairs have a client key/unit. Hit's Forever unit remains
# unknown: a familiar numeric enum alone is not a build-specific unit conversion.
STATS = {
 (5, 'Intellect'): ('ITEM_MOD_INTELLECT_SHORT', 'points'),
 (6, 'Spirit'): ('ITEM_MOD_SPIRIT_SHORT', 'points'),
 (7, 'Stamina'): ('ITEM_MOD_STAMINA_SHORT', 'points'),
 (45, 'Spell Power'): ('ITEM_MOD_SPELL_POWER_SHORT', 'spell_power'),
 (88, 'Shadow Damage Done'): ('ITEM_MOD_DAMAGE_SHADOW_SHORT', 'spell_damage'),
}

def field(value, source):
 return {'status': 'UNKNOWN' if value is None else 'KNOWN', 'value': value, 'provenance': [source]}

def integer(value, name, minimum=0):
 if type(value) is not int or value < minimum: raise ValueError('Invalid API integer: '+name)
 return value

def normalize(input_dir, output, imported_at=None):
 input_dir = pathlib.Path(input_dir).resolve()
 if input_dir == ROOT or ROOT in input_dir.parents:
  raise ValueError('Keep raw API envelopes outside the distributable addon')
 now = imported_at or datetime.datetime.now(datetime.timezone.utc).isoformat()
 datetime.datetime.fromisoformat(now.replace('Z', '+00:00'))
 data = {'schemaVersion': 1, 'provenance': {}, 'items': {}, 'vendors': {},
         'vendorOffers': {}, 'recipes': {}, 'quests': {}, 'acquisitions': {}, 'coverage': {}}
 builds = set()
 def read(endpoint, identity):
  raw = (input_dir/(endpoint.replace('/', '-')+'.json')).read_bytes()
  envelope = json.loads(raw); row, meta = envelope.get('data'), envelope.get('meta')
  if not isinstance(row, dict) or not isinstance(meta, dict) or row.get('id') != identity:
   raise ValueError('Unexpected API envelope/identity: '+endpoint)
  build = meta.get('build'); attribution = meta.get('attribution')
  if not isinstance(build, str) or not re.fullmatch(r'\d+(?:\.\d+)+', build):
   raise ValueError('Missing API build: '+endpoint)
  if not isinstance(attribution, str) or BASE not in attribution:
   raise ValueError('Missing API attribution: '+endpoint)
  builds.add(build)
  source = 'fdb-api-'+endpoint.replace('/', '-')
  data['provenance'][source] = {
   'sourceName': 'ForeverDB.net', 'sourceURL': BASE+'/api/v1/'+endpoint,
   'sourceBuild': build, 'importedAt': now, 'evidenceType': 'published_forever_api',
   'verifiedStatus': 'publisher_reported_not_locally_verified',
   'redistributionBasis': 'ForeverDB developer terms permit attributed bundled addon data; single reviewed slice',
   'documentationURL': BASE+'/developers', 'attribution': attribution, 'creditURL': BASE,
   'sha256': hashlib.sha256(raw).hexdigest()}
  # Account-specific meta.client stays in private quarantine, never the addon.
  return row, source, build

 for item_id in ITEMS:
  row, src, build = read('items/'+str(item_id), item_id)
  if not isinstance(row.get('name'), str) or not isinstance(row.get('stats'), list):
   raise ValueError('Unexpected item fields')
  if row.get('betaEvent') is not False or row.get('liveClient'):
   raise ValueError('Historical/event or live-delta item needs a separate reviewed adapter')
  source_build = row.get('dataFromBuild') or build
  if not isinstance(source_build, str) or not re.fullmatch(r'\d+(?:\.\d+)+', source_build):
   raise ValueError('Unreviewed item source build')
  stats = {}
  for stat in row['stats']:
   label = stat.get('stat'); stat_id = integer(stat.get('statId'), 'statId')
   if not isinstance(label, str) or not label or label in stats: raise ValueError('Duplicate/missing API stat label')
   value = stat.get('value')
   if type(value) not in (int, float): raise ValueError('Non-numeric API stat')
   key, unit = STATS.get((stat_id, label), (None, 'unknown'))
   stats[label] = {'value': value, 'statId': stat_id, 'statKey': key, 'unit': unit, 'provenance': [src]}
  data['items'][str(item_id)] = {
   'itemId': item_id, 'name': field(row['name'], src), 'quality': field(row.get('qualityId'), src),
   'slot': field(row.get('inventoryType'), src), 'requiredLevel': field(row.get('requiredLevel'), src),
   'stats': stats, 'effects': field(row.get('effects'), src), 'equipRestrictions': field(None, src),
   'availability': field({k: row[k] for k in ('betaEvent', 'speculation', 'speculationReasons') if k in row}, src),
   'buildVersion': source_build, 'statsCoverage': 'partial', 'sourceConfidence': 'publisher_reported',
   'provenance': [src]}

 vendor, src, _ = read('vendors/227853', 227853)
 if vendor.get('seenInForever') is not True or not isinstance(vendor.get('sells'), list):
  raise ValueError('Expected a vendor seen in Forever with published inventory')
 offers = [o for o in vendor['sells'] if o.get('itemId') == 272411]
 if len(offers) != 1: raise ValueError('Expected exactly one cloak offer')
 offer = offers[0]
 if offer.get('classicData') is not False or offer.get('seenInForever') is not True:
  raise ValueError('Legacy/unseen offer needs explicit review')
 stack = integer(offer.get('stack'), 'stack', 1)
 if stack != 1: raise ValueError('Pilot supports one item per purchase; review quantity scaling')
 if not isinstance(offer.get('costs'), list): raise ValueError('Missing extended costs is not free')
 currencies, items = [], []
 for cost in offer['costs']:
  kind = cost.get('type')
  if kind not in ('item', 'currency'): raise ValueError('Unreviewed extended cost type')
  cost_id = integer(cost.get('id'), 'cost ID', 1); amount = integer(cost.get('amount'), 'cost amount', 1)
  entry = {'kind': kind, 'currencyId' if kind == 'currency' else 'itemId': cost_id,
           'quantity': amount, 'provenance': [src]}
  if isinstance(cost.get('name'), str): entry['name'] = cost['name']
  (currencies if kind == 'currency' else items).append(entry)
 gold = integer(offer.get('price'), 'purchase price')  # NOT item.sellPrice or pricePerItem
 coords = None
 if all(type(vendor.get(k)) in (int, float) for k in ('x', 'y')):
  if not all(0 <= vendor[k] <= 100 for k in ('x', 'y')): raise ValueError('Coordinates outside map')
  coords = {'x': vendor['x'], 'y': vendor['y'], 'mapId': integer(vendor.get('mapId'), 'mapId', 1)}
 limit = None
 if offer.get('limited') is False: limit = 'unlimited_published'
 elif offer.get('limited') is True and offer.get('limitedStockCount') is not None:
  limit = integer(offer['limitedStockCount'], 'limitedStockCount')
 data['vendors']['pix-xizzix'] = {
  'vendorKey': 'pix-xizzix', 'npcId': field(227853, src), 'name': field(vendor.get('name'), src),
  'faction': field(vendor.get('side'), src), 'zone': field(vendor.get('zone'), src),
  'coordinates': field(coords, src), 'inventory': ['pix:272411'], 'provenance': [src]}
 data['vendorOffers']['pix:272411'] = {
  'offerId': 'pix:272411', 'vendorId': 'pix-xizzix', 'itemId': 272411,
  'goldCostCopper': field(gold, src), 'priceBasis': 'published_per_purchase', 'purchaseStack': field(stack, src),
  'additionalCurrencies': field(currencies, src), 'requiredItems': field(items, src),
  'stockLimit': field(limit, src), 'availabilityStatus': field('seen_in_forever', src),
  # reputationFaction is for discounts, not permission to buy. Null proves neither.
  'requiredReputationFaction': field(None, src), 'requiredReputationRank': field(None, src),
  'questPrerequisites': field(None, src), 'requirementsComplete': False, 'provenance': [src]}
 data['acquisitions']['vendor:272411:pix'] = {
  'acquisitionId': 'vendor:272411:pix', 'itemId': 272411, 'type': 'Vendor', 'sourceId': 'pix:272411',
  # RequiredTree composes the explicit level and purchase costs from their fields.
  'conditions': {'op': 'ALL', 'children': [{'op': 'UNKNOWN',
   'reason': 'Reputation, quest prerequisites and other buying restrictions are not fully published; inspect the vendor.'}]},
  'confidence': 'published_forever_observation_partial_requirements', 'provenance': [src]}
 if len(builds) != 1: raise ValueError('Mixed API builds; review before combining')
 professions = ['Alchemy','Blacksmithing','Enchanting','Engineering','Leatherworking','Tailoring',
                'Herbalism','Mining','Skinning','Cooking','First Aid','Fishing']
 data['coverage'] = {
  'professions': {p: {'imported': 0, 'status': 'NOT_IMPORTED'} for p in professions},
  'quests': {'imported': 0, 'status': 'NOT_IMPORTED'},
  'vendorSlice': {'offers': 1, 'requirementsComplete': False, 'liveClientValidated': False,
                  'source': 'authenticated_api'},
  'stats': {'items': 4, 'status': 'PARTIAL; unreviewed stat units remain unknown; no EP'}}
 validate(data)
 atomic(output, json.dumps(data, ensure_ascii=False, indent=2)+'\n')
 return pathlib.Path(output)
