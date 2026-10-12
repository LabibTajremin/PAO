import { Injectable } from '@nestjs/common';
import { type Language } from '../../../../platform/i18n/text';
import { SavedAddresses } from '../../app/addresses';
import { CustomerProfiles } from '../../app/profiles';
import { ServiceArea } from '../../app/service-area';
import { type CustomerQuery, type CustomerRecord } from '../../contract/admin-search';
import { type CustomerService } from '../../contract/customer-service';
import { type Address, type Customer } from '../../contract/dto';
import { type Point } from '../../domain/customer';

/** The customer contract for other modules. */
@Injectable()
export class CustomerContract implements CustomerService {
  constructor(
    private readonly profiles: CustomerProfiles,
    private readonly addresses: SavedAddresses,
    private readonly area: ServiceArea,
  ) {}

  async getCustomer(customerId: string): Promise<Customer> {
    const c = await this.profiles.customer(customerId);
    return {
      id: c.id,
      name: c.name,
      photoMediaId: c.photoMediaId,
      language: c.language as Language,
    };
  }

  async getAddress(customerId: string, addressId: string): Promise<Address> {
    const a = await this.addresses.get(customerId, addressId);
    return {
      id: a.id,
      customerId: a.customerId,
      label: a.label,
      line1: a.line1,
      line2: a.line2,
      area: a.area,
      location: a.location,
    };
  }

  isInServiceArea(point: Point): Promise<boolean> {
    return this.area.covers(point);
  }

  searchCustomers(query: CustomerQuery): Promise<CustomerRecord[]> {
    return this.profiles.search(query);
  }
}
