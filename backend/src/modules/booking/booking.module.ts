import { Global, Module } from '@nestjs/common';
import { CustomerBookingsController } from './adapter/http/customer.controller';
import { AdminBookingsController, NearbyController } from './adapter/http/discovery.controller';
import { EarningsController } from './adapter/http/earnings.controller';
import { ProviderJobsController } from './adapter/http/provider.controller';
import { BookingContract, BookingWorker } from './adapter/inproc/booking-contract';
import {
  AdminRules,
  CatalogPrices,
  CustomerProfiles,
  MediaPhotos,
  ProviderDirectory,
  RandomStartCodes,
  RatingReviews,
} from './adapter/peers/peers';
import {
  bookingOutboxProvider,
  PostgresBookingRepository,
} from './adapter/postgres/booking-repository';
import { BookingAccess } from './app/access';
import { CreateBooking } from './app/create-booking';
import { ProviderEarnings } from './app/earnings';
import { Eligibility } from './app/eligibility';
import { FindNearby } from './app/find-nearby';
import { Pricing } from './app/pricing';
import { ProgressJob } from './app/progress';
import { ReadBookings } from './app/read-bookings';
import { RespondToRequests } from './app/respond';
import { BOOKING_SERVICE } from './contract/booking-service';
import {
  CATALOG,
  CUSTOMERS,
  FINDER,
  MEDIA,
  PROVIDERS,
  REVIEWS,
  SETTINGS,
  START_CODES,
} from './port/peers';
import { BOOKING_REPOSITORY } from './port/repository';
import { BookingErasure } from './adapter/postgres/erasure';

/** The booking lifecycle, earnings and discovery (PRD §5). */
@Global()
@Module({
  controllers: [
    NearbyController,
    CustomerBookingsController,
    ProviderJobsController,
    EarningsController,
    AdminBookingsController,
  ],
  providers: [
    bookingOutboxProvider,
    { provide: BOOKING_REPOSITORY, useClass: PostgresBookingRepository },
    { provide: CATALOG, useClass: CatalogPrices },
    { provide: CUSTOMERS, useClass: CustomerProfiles },
    ProviderDirectory,
    { provide: PROVIDERS, useExisting: ProviderDirectory },
    { provide: FINDER, useExisting: ProviderDirectory },
    { provide: MEDIA, useClass: MediaPhotos },
    { provide: SETTINGS, useClass: AdminRules },
    { provide: REVIEWS, useClass: RatingReviews },
    { provide: START_CODES, useClass: RandomStartCodes },
    BookingAccess,
    Pricing,
    Eligibility,
    CreateBooking,
    RespondToRequests,
    ProgressJob,
    ReadBookings,
    ProviderEarnings,
    FindNearby,
    BookingWorker,
    BookingErasure,
    { provide: BOOKING_SERVICE, useClass: BookingContract },
  ],
  exports: [BOOKING_SERVICE],
})
export class BookingModule {}
