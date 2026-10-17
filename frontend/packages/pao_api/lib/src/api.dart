//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:dio/dio.dart';
import 'package:pao_api/src/auth/api_key_auth.dart';
import 'package:pao_api/src/auth/basic_auth.dart';
import 'package:pao_api/src/auth/bearer_auth.dart';
import 'package:pao_api/src/auth/oauth.dart';
import 'package:pao_api/src/api/admin_api.dart';
import 'package:pao_api/src/api/admin_bookings_api.dart';
import 'package:pao_api/src/api/admin_catalog_api.dart';
import 'package:pao_api/src/api/admin_complaints_api.dart';
import 'package:pao_api/src/api/admin_people_api.dart';
import 'package:pao_api/src/api/admin_settings_api.dart';
import 'package:pao_api/src/api/admin_verification_api.dart';
import 'package:pao_api/src/api/auth_api.dart';
import 'package:pao_api/src/api/customer_api.dart';
import 'package:pao_api/src/api/customer_bookings_api.dart';
import 'package:pao_api/src/api/me_api.dart';
import 'package:pao_api/src/api/provider_api.dart';
import 'package:pao_api/src/api/provider_enrolment_api.dart';
import 'package:pao_api/src/api/provider_jobs_api.dart';

class PaoApi {
  static const String basePath = r'http://localhost:8080';

  final Dio dio;
  PaoApi({Dio? dio, String? basePathOverride, List<Interceptor>? interceptors})
    : this.dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: basePathOverride ?? basePath,
              connectTimeout: const Duration(milliseconds: 5000),
              receiveTimeout: const Duration(milliseconds: 3000),
            ),
          ) {
    if (interceptors == null) {
      this.dio.interceptors.addAll([
        OAuthInterceptor(),
        BasicAuthInterceptor(),
        BearerAuthInterceptor(),
        ApiKeyAuthInterceptor(),
      ]);
    } else {
      this.dio.interceptors.addAll(interceptors);
    }
  }

  void setOAuthToken(String name, String token) {
    if (this.dio.interceptors.any((i) => i is OAuthInterceptor)) {
      (this.dio.interceptors.firstWhere(
        (i) => i is OAuthInterceptor,
      ) as OAuthInterceptor).tokens[name] = token;
    }
  }

  void setBearerAuth(String name, String token) {
    if (this.dio.interceptors.any((i) => i is BearerAuthInterceptor)) {
      (this.dio.interceptors.firstWhere(
        (i) => i is BearerAuthInterceptor,
      ) as BearerAuthInterceptor).tokens[name] = token;
    }
  }

  void setBasicAuth(String name, String username, String password) {
    if (this.dio.interceptors.any((i) => i is BasicAuthInterceptor)) {
      (this.dio.interceptors.firstWhere(
        (i) => i is BasicAuthInterceptor,
      ) as BasicAuthInterceptor).authInfo[name] = BasicAuthInfo(
        username,
        password,
      );
    }
  }

  void setApiKey(String name, String apiKey) {
    if (this.dio.interceptors.any((i) => i is ApiKeyAuthInterceptor)) {
      (this.dio.interceptors.firstWhere(
        (element) => element is ApiKeyAuthInterceptor,
      ) as ApiKeyAuthInterceptor).apiKeys[name] = apiKey;
    }
  }

  /// Get AdminApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AdminApi getAdminApi() {
    return AdminApi(dio);
  }

  /// Get AdminBookingsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AdminBookingsApi getAdminBookingsApi() {
    return AdminBookingsApi(dio);
  }

  /// Get AdminCatalogApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AdminCatalogApi getAdminCatalogApi() {
    return AdminCatalogApi(dio);
  }

  /// Get AdminComplaintsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AdminComplaintsApi getAdminComplaintsApi() {
    return AdminComplaintsApi(dio);
  }

  /// Get AdminPeopleApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AdminPeopleApi getAdminPeopleApi() {
    return AdminPeopleApi(dio);
  }

  /// Get AdminSettingsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AdminSettingsApi getAdminSettingsApi() {
    return AdminSettingsApi(dio);
  }

  /// Get AdminVerificationApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AdminVerificationApi getAdminVerificationApi() {
    return AdminVerificationApi(dio);
  }

  /// Get AuthApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AuthApi getAuthApi() {
    return AuthApi(dio);
  }

  /// Get CustomerApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  CustomerApi getCustomerApi() {
    return CustomerApi(dio);
  }

  /// Get CustomerBookingsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  CustomerBookingsApi getCustomerBookingsApi() {
    return CustomerBookingsApi(dio);
  }

  /// Get MeApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  MeApi getMeApi() {
    return MeApi(dio);
  }

  /// Get ProviderApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  ProviderApi getProviderApi() {
    return ProviderApi(dio);
  }

  /// Get ProviderEnrolmentApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  ProviderEnrolmentApi getProviderEnrolmentApi() {
    return ProviderEnrolmentApi(dio);
  }

  /// Get ProviderJobsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  ProviderJobsApi getProviderJobsApi() {
    return ProviderJobsApi(dio);
  }
}
