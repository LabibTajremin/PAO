import { type ModuleRef } from '@nestjs/core';
import { DomainError } from '../../../../platform/errors/domain-error';
import { BOOKING_SERVICE } from '../../../booking/contract/booking-service';
import { BookingErrors } from '../../../booking/contract/errors';
import { CUSTOMER_SERVICE } from '../../../customer/contract/customer-service';
import { PROVIDER_SERVICE } from '../../../provider/contract/provider-service';
import { BookingDetails, ProfileLanguages } from './peers';

function refTo(contracts: Map<symbol, unknown>): ModuleRef {
  return { get: (token: symbol) => contracts.get(token) } as unknown as ModuleRef;
}

describe('ProfileLanguages', () => {
  it('reads the profile language and falls back to Bangla', async () => {
    const languages = new ProfileLanguages(
      refTo(
        new Map<symbol, unknown>([
          [
            CUSTOMER_SERVICE,
            {
              getCustomer: (id: string) =>
                id === 'c'
                  ? Promise.resolve({ language: 'en' })
                  : Promise.reject(new Error('none')),
            },
          ],
          [PROVIDER_SERVICE, { getProvider: () => Promise.resolve({ language: 'en' }) }],
        ]),
      ),
    );
    expect(await languages.language('c', 'customer')).toBe('en');
    expect(await languages.language('x', 'customer')).toBe('bn');
    expect(await languages.language('p', 'partner')).toBe('en');
  });
});

describe('BookingDetails', () => {
  it('reads booking text and treats an unknown booking as absent', async () => {
    const booking = {
      number: 'PAO-1',
      serviceName: { en: 'Fan', bn: 'ফ্যান' },
      area: 'Gulshan',
      providerName: 'Rahim',
      customerName: 'Nusrat',
    };
    const getBooking = (id: string) => {
      if (id === 'b1') {
        return Promise.resolve(booking);
      }
      return Promise.reject(
        id === 'gone' ? new DomainError(BookingErrors.NotFound) : new Error('db down'),
      );
    };
    const details = new BookingDetails(refTo(new Map([[BOOKING_SERVICE, { getBooking }]])));
    expect(await details.booking('b1')).toEqual({
      number: 'PAO-1',
      serviceEn: 'Fan',
      serviceBn: 'ফ্যান',
      area: 'Gulshan',
      providerName: 'Rahim',
      customerName: 'Nusrat',
    });
    expect(await details.booking('gone')).toBeUndefined();
    await expect(details.booking('x')).rejects.toThrow('db down');
  });
});
