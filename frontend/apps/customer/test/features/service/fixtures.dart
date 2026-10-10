/// IDs used by the catalog fixtures.
const electricianId = 'e0000000-0000-4000-8000-000000000001';

/// Fan repair, sold per unit.
const fanId = 'e0000000-0000-4000-8000-000000000011';

/// Switch repair, sold per job.
const switchId = 'e0000000-0000-4000-8000-000000000012';

/// Home salon, women providers only.
const salonId = 'e0000000-0000-4000-8000-000000000002';

/// Driver hire.
const driverId = 'e0000000-0000-4000-8000-000000000003';

/// Driver by the hour.
const hourlyId = 'e0000000-0000-4000-8000-000000000031';

/// Driver by the day.
const dailyId = 'e0000000-0000-4000-8000-000000000032';

/// Text in both languages.
Map<String, Object?> named(String en) => {'en': en, 'bn': '$en-bn'};

/// A sub-service.
Map<String, Object?> sub(
  String id,
  String name, {
  String serviceId = electricianId,
  String unit = 'unit',
  int price = 50000,
  int? max,
  bool published = true,
  bool details = false,
}) => {
  'id': id,
  'serviceId': serviceId,
  'name': named(name),
  'unit': unit,
  'price': price,
  'priceVersionId': 'p0000000-0000-4000-8000-000000000001',
  'maxQuantity': ?max,
  'published': published,
  if (details) ...{
    'description': named('Ceiling or table fan'),
    'inclusions': [named('Cleaning')],
    'exclusions': [named('Spare parts')],
  },
};

/// A service with its sub-services.
Map<String, Object?> service({
  String id = electricianId,
  String name = 'Electrician',
  String model = 'on_demand',
  String icon = 'bolt',
  bool women = false,
  bool published = true,
  List<Map<String, Object?>>? subs,
}) => {
  'id': id,
  'categoryId': 'c0000000-0000-4000-8000-000000000001',
  'name': named(name),
  'iconKey': icon,
  'serviceModel': model,
  'requiredLevel': 1,
  'searchRadiusM': 5000,
  'womenProvidersOnly': women,
  'requiresLevel2': false,
  'published': published,
  'subServices':
      subs ??
      [
        sub(fanId, 'Fan repair', max: 3, details: true),
        sub(switchId, 'Switch repair', unit: 'job', price: 30000),
        sub('e0000000-0000-4000-8000-000000000013', 'Hidden', published: false),
      ],
};

/// The salon service.
Map<String, Object?> salon() => service(
  id: salonId,
  name: 'Home salon',
  icon: 'salon',
  women: true,
  subs: [sub('s1', 'Haircut', serviceId: salonId, unit: 'job')],
);

/// The driver hire service.
Map<String, Object?> driver() => service(
  id: driverId,
  name: 'Driver',
  icon: 'car',
  model: 'duration_hire',
  subs: [
    sub(hourlyId, 'Hourly', serviceId: driverId, unit: 'hour', price: 25000),
    sub(dailyId, 'Daily', serviceId: driverId, unit: 'day', price: 150000),
  ],
);

/// A category.
Map<String, Object?> category(
  String id,
  String name,
  int order,
  List<Map<String, Object?>> services, {
  bool published = true,
}) => {
  'id': id,
  'name': named(name),
  'iconKey': 'home',
  'sortOrder': order,
  'published': published,
  'services': services,
};

/// `GET /v1/customer/catalog`.
Map<String, Object?> catalog() => {
  'version': 3,
  'categories': [
    category('c2', 'Beauty', 2, [salon(), service(published: false)]),
    category('c1', 'Repairs', 1, [service(), driver()]),
    category('c3', 'Hidden', 0, [service()], published: false),
    category('c4', 'Empty', 4, []),
  ],
};
