import { Global, Module } from '@nestjs/common';
import { AddressesController, ServiceAreaController } from './adapter/http/addresses.controller';
import { CustomerProfileController } from './adapter/http/profile.controller';
import { CustomerContract } from './adapter/inproc/customer-contract';
import { AdminLaunchArea, IdentityAccounts, MediaPhotos } from './adapter/peers/peers';
import { PostgresCustomerRepository } from './adapter/postgres/customer-repository';
import { CustomerSubscribers } from './adapter/postgres/subscribers';
import { SavedAddresses } from './app/addresses';
import { CustomerProfiles } from './app/profiles';
import { ServiceArea } from './app/service-area';
import { CUSTOMER_SERVICE } from './contract/customer-service';
import { ACCOUNTS, LAUNCH_AREA, PHOTOS } from './port/peers';
import { CUSTOMER_REPOSITORY } from './port/repository';

/** Customer profiles, saved addresses and the launch-area check. */
@Global()
@Module({
  controllers: [CustomerProfileController, AddressesController, ServiceAreaController],
  providers: [
    { provide: CUSTOMER_REPOSITORY, useClass: PostgresCustomerRepository },
    { provide: PHOTOS, useClass: MediaPhotos },
    { provide: ACCOUNTS, useClass: IdentityAccounts },
    { provide: LAUNCH_AREA, useClass: AdminLaunchArea },
    CustomerProfiles,
    SavedAddresses,
    ServiceArea,
    CustomerSubscribers,
    { provide: CUSTOMER_SERVICE, useClass: CustomerContract },
  ],
  exports: [CUSTOMER_SERVICE],
})
export class CustomerModule {}
