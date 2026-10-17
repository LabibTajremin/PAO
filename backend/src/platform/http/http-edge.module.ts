import {
  type DynamicModule,
  Global,
  Inject,
  type MiddlewareConsumer,
  Module,
  type NestModule,
} from '@nestjs/common';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import cookieParser from 'cookie-parser';
import { APP_CONFIG, type AppConfig } from '../config/app-config';
import { Metrics, METRICS } from '../metrics/metrics';
import { type ApiRequest } from './api-request';
import { clientIpMiddleware } from './client-ip';
import {
  bodyReaderMiddleware,
  corsMiddleware,
  requestIdMiddleware,
  securityHeadersMiddleware,
} from './edge-middleware';
import { ErrorFilter } from './error.filter';
import {
  API_RATE_LIMITS,
  AuthenticationGuard,
  AuthorizationGuard,
  RATE_LIMITS,
  RateLimitGuard,
} from './guards';
import { IdempotencyInterceptor } from './idempotency.interceptor';
import { RequestValidationInterceptor } from './request-validation.interceptor';
import { RequestValidator } from './request-validator';
import { NON_SPEC_ROUTES, type NonSpecRoute, SpecMatchMiddleware } from './spec-match.middleware';
import {
  loadOpenApiDocument,
  OPENAPI_DOCUMENT,
  type OpenApiDocument,
  SpecRoutes,
} from './spec-routes';

/** What the HTTP edge needs to know about routes served outside the contract. */
export interface HttpEdgeOptions {
  readonly nonSpecRoutes?: readonly NonSpecRoute[];
}

/**
 * The HTTP edge every request passes, in this order (README.md in this folder):
 * middleware (client IP, request id, security headers, CORS, body, cookies, metrics,
 * operation matching) → guards (authentication, authorisation, rate limit) →
 * interceptors (request validation, idempotency) → controller; one filter answers errors.
 */
@Global()
@Module({})
export class HttpEdgeModule implements NestModule {
  constructor(
    @Inject(APP_CONFIG) private readonly config: AppConfig,
    @Inject(METRICS) private readonly metrics: Metrics,
  ) {}

  static forRoot(options: HttpEdgeOptions = {}): DynamicModule {
    return {
      module: HttpEdgeModule,
      providers: [
        { provide: OPENAPI_DOCUMENT, useFactory: () => loadOpenApiDocument() },
        {
          provide: SpecRoutes,
          inject: [OPENAPI_DOCUMENT],
          useFactory: (doc: OpenApiDocument) => new SpecRoutes(doc),
        },
        {
          provide: RequestValidator,
          inject: [OPENAPI_DOCUMENT],
          useFactory: (doc: OpenApiDocument) => new RequestValidator(doc),
        },
        { provide: NON_SPEC_ROUTES, useValue: options.nonSpecRoutes ?? [] },
        { provide: RATE_LIMITS, useValue: API_RATE_LIMITS },
        { provide: APP_GUARD, useClass: AuthenticationGuard },
        { provide: APP_GUARD, useClass: AuthorizationGuard },
        { provide: APP_GUARD, useClass: RateLimitGuard },
        { provide: APP_INTERCEPTOR, useClass: RequestValidationInterceptor },
        { provide: APP_INTERCEPTOR, useClass: IdempotencyInterceptor },
        { provide: APP_FILTER, useClass: ErrorFilter },
      ],
      exports: [OPENAPI_DOCUMENT, SpecRoutes],
    };
  }

  configure(consumer: MiddlewareConsumer): void {
    consumer
      .apply(
        clientIpMiddleware,
        requestIdMiddleware,
        securityHeadersMiddleware,
        corsMiddleware(this.config.adminCorsOrigin),
        bodyReaderMiddleware,
        cookieParser(),
        this.metrics.middleware((req) => (req as ApiRequest).routeTemplate),
        SpecMatchMiddleware,
      )
      .forRoutes('{*splat}');
  }
}
