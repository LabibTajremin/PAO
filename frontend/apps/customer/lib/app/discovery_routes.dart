import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/home/presentation/services_page.dart';
import 'package:pao_customer/features/location/presentation/address_page.dart';
import 'package:pao_customer/features/providers/presentation/provider_profile_page.dart';
import 'package:pao_customer/features/providers/presentation/providers_page.dart';
import 'package:pao_customer/features/providers/presentation/reviews_page.dart';
import 'package:pao_customer/features/search/presentation/search_page.dart';
import 'package:pao_customer/features/service/presentation/service_page.dart';

/// Keyed by the full location so moving between two services or providers
/// on the same route starts a fresh screen instead of keeping the old state.
GoRoute _page(String path, Widget Function(GoRouterState state) build) =>
    GoRoute(
      path: path,
      builder: (_, state) => KeyedSubtree(
        key: ValueKey(state.uri.toString()),
        child: build(state),
      ),
    );

/// Addresses, catalog, search, service detail and providers (C08–C11, C25,
/// C37–C44), opened full screen over the tabs.
List<RouteBase> discoveryRoutes(AppServices s) => [
  _page(Routes.addressNew, (_) => AddressPage(services: s)),
  _page(
    '/account/addresses/:id',
    (st) => AddressPage(services: s, addressId: st.pathParameters['id']),
  ),
  _page(
    Routes.services,
    (st) => ServicesPage(
      services: s,
      categoryId: st.uri.queryParameters['category'],
    ),
  ),
  _page(Routes.search, (_) => SearchPage(services: s)),
  _page(
    Routes.service,
    (st) => ServicePage(
      services: s,
      serviceId: st.pathParameters['id']!,
      preselect: st.uri.queryParameters['sub'],
    ),
  ),
  ..._providerRoutes(s),
];

List<RouteBase> _providerRoutes(AppServices s) => [
  _page(
    Routes.providers,
    (st) => ProvidersPage(
      services: s,
      serviceId: st.pathParameters['id']!,
      query: st.uri.queryParameters,
    ),
  ),
  _page(
    Routes.provider,
    (st) => ProviderProfilePage(
      services: s,
      providerId: st.pathParameters['id']!,
      query: st.uri.queryParameters,
    ),
  ),
  _page(
    Routes.providerReviews,
    (st) => ReviewsPage(services: s, providerId: st.pathParameters['id']!),
  ),
];
