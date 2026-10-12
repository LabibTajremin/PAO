import { type ModuleRef } from '@nestjs/core';
import { DomainError } from '../../../platform/errors/domain-error';
import { type Principal } from '../../../platform/http/principal';
import { MediaErrors } from '../../media/contract/errors';
import { type MediaObject } from '../../media/contract/dto';
import { type SavedAddresses } from '../app/addresses';
import { CustomerReasons } from '../app/errors';
import { type CustomerProfiles } from '../app/profiles';
import { type ServiceArea } from '../app/service-area';
import { AddressesController, ServiceAreaController } from './http/addresses.controller';
import { customerErrors } from './http/error-map';
import { CustomerProfileController } from './http/profile.controller';
import { CustomerContract } from './inproc/customer-contract';
import { AdminLaunchArea, IdentityAccounts, MediaPhotos } from './peers/peers';

const boom = new Error('boom');

async function failure(p: Promise<unknown>): Promise<unknown> {
  return p.then(
    () => undefined,
    (e: unknown) => e,
  );
}

function moduleRef(byToken: Record<string, unknown>): ModuleRef {
  return { get: (token: symbol) => byToken[token.description ?? ''] } as unknown as ModuleRef;
}

const avatar: MediaObject = {
  id: 'm1',
  ownerId: 'c1',
  purpose: 'avatar',
  contentType: 'image/png',
  sizeBytes: 3,
  confirmed: true,
};

function fakeMedia(objects: Record<string, MediaObject | Error>) {
  const attached: string[] = [];
  const media = {
    attached,
    getObject: (id: string) => {
      const o = objects[id];
      if (o === undefined) {
        return Promise.reject(new DomainError(MediaErrors.NotFound));
      }
      return o instanceof Error ? Promise.reject(o) : Promise.resolve(o);
    },
    markAttached: (id: string) => {
      attached.push(id);
      return Promise.resolve();
    },
    getViewUrl: () => Promise.resolve({ url: 'https://photo', expiresAt: new Date() }),
  };
  return media;
}

describe('MediaPhotos', () => {
  it('attaches only the owner confirmed avatar', async () => {
    const media = fakeMedia({
      m1: avatar,
      other: { ...avatar, ownerId: 'c2' },
      doc: { ...avatar, purpose: 'level2_photo' },
      raw: { ...avatar, confirmed: false },
      down: boom,
    });
    const photos = new MediaPhotos(moduleRef({ MediaService: media }));
    await photos.attachAvatar('c1', 'm1');
    expect(media.attached).toEqual(['m1']);
    for (const id of ['other', 'doc', 'raw', 'missing']) {
      expect(await failure(photos.attachAvatar('c1', id))).toMatchObject({
        reason: CustomerReasons.InvalidPhoto,
      });
    }
    expect(await failure(photos.attachAvatar('c1', 'down'))).toBe(boom);
    expect(await photos.url('c1', 'm1')).toBe('https://photo');
  });
});

describe('identity and admin peers', () => {
  it('reads the account and the launch area', async () => {
    const ref = moduleRef({
      IdentityService: {
        getAccount: () => Promise.resolve({ phone: '+880', status: 'active', roles: [] }),
      },
      AdminService: { getSettings: () => Promise.resolve({ serviceAreaGeoJson: '{}' }) },
    });
    expect(await new IdentityAccounts(ref).account('c1')).toEqual({
      phone: '+880',
      status: 'active',
    });
    expect(await new AdminLaunchArea(ref).geoJson()).toBe('{}');
  });
});

const address = {
  id: 'a1',
  customerId: 'c1',
  label: 'home',
  line1: 'House 12, Road 5',
  line2: '',
  area: 'Banani',
  location: { lat: 23.79, lng: 90.41 },
  isDefault: true,
  createdAt: new Date(0),
};

describe('CustomerContract', () => {
  it('maps profiles and addresses to the contract shapes', async () => {
    const profiles = {
      customer: () =>
        Promise.resolve({
          id: 'c1',
          name: 'N',
          photoMediaId: null,
          language: 'bn',
          updatedAt: new Date(),
        }),
      search: () => Promise.resolve([]),
    } as unknown as CustomerProfiles;
    const addresses = { get: () => Promise.resolve(address) } as unknown as SavedAddresses;
    const area = { covers: () => Promise.resolve(true) } as unknown as ServiceArea;
    const c = new CustomerContract(profiles, addresses, area);
    expect(await c.getCustomer('c1')).toEqual({
      id: 'c1',
      name: 'N',
      photoMediaId: null,
      language: 'bn',
    });
    const plain = { id: 'a1', customerId: 'c1', label: 'home', line1: address.line1 };
    expect(await c.getAddress('c1', 'a1')).toMatchObject({
      ...plain,
      line2: '',
      area: 'Banani',
      location: address.location,
    });
    expect(await c.isInServiceArea(address.location)).toBe(true);
    expect(await c.searchCustomers({} as never)).toEqual([]);
  });
});

const me = { accountId: 'c1' } as Principal;

describe('customer controllers', () => {
  it('serves the profile views', async () => {
    const profile = { id: 'c1', name: 'N', language: 'bn', phone: '+880', photoUrl: '' };
    const profiles = {
      profile: () => Promise.resolve(profile),
      save: (_id: string, input: { photoMediaId: string | null }) =>
        Promise.resolve({ ...profile, photoUrl: input.photoMediaId === null ? '' : 'https://p' }),
    } as unknown as CustomerProfiles;
    const ctl = new CustomerProfileController(profiles);
    expect(await ctl.get(me)).toEqual({ id: 'c1', name: 'N', language: 'bn', phone: '+880' });
    const body = { name: 'N', language: 'bn' as const };
    expect(await ctl.update(me, { ...body, photoMediaId: 'm1' })).toMatchObject({
      photoUrl: 'https://p',
    });
    expect(await ctl.update(me, body)).not.toHaveProperty('photoUrl');
  });

  it('serves the address views and the area check', async () => {
    const seen: unknown[] = [];
    const addresses = {
      list: () => Promise.resolve([address]),
      add: (_c: string, input: unknown) => (seen.push(input), Promise.resolve(address)),
      update: () => Promise.resolve(address),
      setDefault: () => Promise.resolve(address),
      delete: () => Promise.resolve(),
    } as unknown as SavedAddresses;
    const ctl = new AddressesController(addresses);

    const expected = {
      id: 'a1',
      label: 'home',
      line1: address.line1,
      line2: '',
      area: 'Banani',
      location: address.location,
      isDefault: true,
    };
    expect(await ctl.list(me)).toEqual({ items: [expected] });
    const body = { label: 'home' as const, line1: 'Road 5', location: address.location };
    expect(await ctl.create(me, body)).toEqual(expected);
    expect(seen).toEqual([{ ...body, line2: '', area: '', isDefault: false }]);
    await ctl.create(me, { ...body, line2: 'B', area: 'A', isDefault: true });
    expect(await ctl.update(me, 'a1', body)).toEqual(expected);
    expect(await ctl.setDefault(me, 'a1')).toEqual(expected);
    await ctl.delete(me, 'a1');
    const area = new ServiceAreaController({
      covers: () => Promise.resolve(false),
    } as unknown as ServiceArea);
    expect(await area.check({ lat: 23.8, lng: 90.4 })).toEqual({ covered: false });
  });

  it('maps every reason the module raises', () => {
    const reasons = Object.values(CustomerReasons);
    expect(Object.keys(customerErrors).sort()).toEqual([...reasons].sort());
  });
});
