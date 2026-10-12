import { FakeClock } from '../../../platform/clock/fake-clock';
import { DomainError } from '../../../platform/errors/domain-error';
import { type DomainEvent } from '../../../platform/events/domain-event';
import { UuidV7Generator } from '../../../platform/ids/id-generator';
import { type CustomerRecord } from '../contract/admin-search';
import { type Address, type Customer } from '../domain/customer';
import { type Accounts, type LaunchArea, type Photos } from '../port/peers';
import { type CustomerRepository, type StoredCustomer } from '../port/repository';
import { SavedAddresses } from './addresses';
import { CustomerReasons } from './errors';
import { CustomerProfiles } from './profiles';
import { ServiceArea } from './service-area';

const boom = new Error('boom');

class FakeRepo implements CustomerRepository {
  customers = new Map<string, StoredCustomer>();
  addresses = new Map<string, Address>();
  events: DomainEvent[] = [];
  down = false;

  private fail(): Promise<never> | undefined {
    return this.down ? Promise.reject(boom) : undefined;
  }

  saveCustomer(c: StoredCustomer, e: DomainEvent) {
    this.customers.set(c.id, c);
    this.events.push(e);
    return this.fail() ?? Promise.resolve();
  }

  getCustomer(id: string): Promise<Customer> {
    const c = this.customers.get(id);
    return c ? Promise.resolve(c) : Promise.reject(new DomainError(CustomerReasons.NotFound));
  }

  search(): Promise<CustomerRecord[]> {
    return Promise.resolve([]);
  }

  addAddress(a: Address) {
    this.addresses.set(a.id, a);
    return Promise.resolve(a);
  }

  updateAddress(a: Address) {
    this.addresses.set(a.id, a);
    return this.fail() ?? Promise.resolve();
  }

  setDefault() {
    return this.fail() ?? Promise.resolve();
  }

  deleteAddress() {
    return this.fail() ?? Promise.resolve();
  }

  listAddresses() {
    return Promise.resolve([...this.addresses.values()]);
  }

  getAddress(_customerId: string, id: string) {
    const a = this.addresses.get(id);
    return a ? Promise.resolve(a) : Promise.reject(new Error('missing'));
  }
}

class FakePeers implements Photos, Accounts, LaunchArea {
  photoErr: Error | undefined;
  accountErr: Error | undefined;
  area = '';
  attached: string[] = [];

  attachAvatar(_owner: string, id: string) {
    this.attached.push(id);
    return this.photoErr ? Promise.reject(this.photoErr) : Promise.resolve();
  }

  url() {
    return Promise.resolve('https://photo');
  }

  account() {
    return this.accountErr
      ? Promise.reject(this.accountErr)
      : Promise.resolve({ phone: '+8801712345678', status: 'active' });
  }

  geoJson() {
    return this.area === 'down' ? Promise.reject(boom) : Promise.resolve(this.area);
  }
}

function setup() {
  const repo = new FakeRepo();
  const peers = new FakePeers();
  const clock = new FakeClock(new Date('2026-10-11T10:00:00Z'));
  return {
    repo,
    peers,
    profiles: new CustomerProfiles(repo, peers, peers, clock),
    addresses: new SavedAddresses(repo, clock, new UuidV7Generator()),
    area: new ServiceArea(peers),
  };
}

const home = {
  label: 'home',
  line1: 'House 12, Road 5',
  line2: '',
  area: '',
  location: { lat: 23.79, lng: 90.41 },
  isDefault: false,
};

describe('customer profiles', () => {
  it('saves a trimmed profile with the account phone and photo', async () => {
    const { repo, peers, profiles } = setup();
    const input = { name: ' Nusrat ', language: 'bn', photoMediaId: 'p1' };
    const got = await profiles.save('c1', input);
    expect(got).toMatchObject({
      name: 'Nusrat',
      phone: '+8801712345678',
      photoUrl: 'https://photo',
    });
    expect(peers.attached).toEqual(['p1']);
    expect(repo.customers.get('c1')?.status).toBe('active');
    expect(repo.events).toEqual([
      { name: 'customer.CustomerProfileSaved', customerId: 'c1', customerName: 'Nusrat' },
    ]);
    expect((await profiles.customer('c1')).name).toBe('Nusrat');
    expect(await profiles.search({} as never)).toEqual([]);
  });

  it('shows no photo URL without a photo', async () => {
    const { profiles } = setup();
    const got = await profiles.save('c1', { name: 'Nusrat', language: 'en', photoMediaId: null });
    expect(got.photoUrl).toBe('');
  });

  it('refuses bad details and passes peer and store failures on', async () => {
    const { repo, peers, profiles } = setup();
    const ok = { name: 'Nusrat', language: 'bn', photoMediaId: null };
    await expect(profiles.save('c1', { ...ok, name: ' x ' })).rejects.toMatchObject({
      reason: CustomerReasons.Invalid,
    });
    await expect(profiles.profile('nobody')).rejects.toMatchObject({
      reason: CustomerReasons.NotFound,
    });
    peers.photoErr = boom;
    await expect(profiles.save('c1', { ...ok, photoMediaId: 'p1' })).rejects.toBe(boom);
    peers.accountErr = boom;
    await expect(profiles.save('c1', ok)).rejects.toBe(boom);
    peers.accountErr = undefined;
    await profiles.save('c1', ok);
    peers.accountErr = boom;
    await expect(profiles.profile('c1')).rejects.toBe(boom);
    peers.accountErr = undefined;
    repo.down = true;
    await expect(profiles.save('c1', ok)).rejects.toBe(boom);
  });
});

describe('saved addresses', () => {
  it('adds, edits, lists and switches the default', async () => {
    const { addresses } = setup();
    const a = await addresses.add('c1', home);
    expect(a.customerId).toBe('c1');
    const edited = await addresses.update('c1', a.id, { ...home, line1: 'House 14, Road 5' });
    expect(edited.line1).toBe('House 14, Road 5');
    expect((await addresses.setDefault('c1', a.id)).id).toBe(a.id);
    expect(await addresses.list('c1')).toHaveLength(1);
    expect((await addresses.get('c1', a.id)).id).toBe(a.id);
    await addresses.delete('c1', a.id);
  });

  it('refuses bad fields and pins abroad', async () => {
    const { addresses } = setup();
    const farm = { ...home, label: 'farm' };
    await expect(addresses.add('c1', farm)).rejects.toMatchObject({
      reason: CustomerReasons.Invalid,
    });
    await expect(addresses.update('c1', 'a', farm)).rejects.toMatchObject({
      reason: CustomerReasons.Invalid,
    });
    const london = { ...home, location: { lat: 51.5, lng: -0.12 } };
    await expect(addresses.add('c1', london)).rejects.toMatchObject({
      reason: CustomerReasons.OutsideCountry,
    });
  });

  it('passes store failures on', async () => {
    const { repo, addresses } = setup();
    const a = await addresses.add('c1', home);
    repo.down = true;
    await expect(addresses.update('c1', a.id, home)).rejects.toBe(boom);
    await expect(addresses.setDefault('c1', a.id)).rejects.toBe(boom);
    await expect(addresses.delete('c1', a.id)).rejects.toBe(boom);
  });
});

describe('service area', () => {
  it('checks the point against the launch area', async () => {
    const { peers, area } = setup();
    expect(await area.covers(home.location)).toBe(true);
    peers.area = '{';
    expect(await area.covers(home.location)).toBe(false);
    peers.area = 'down';
    await expect(area.covers(home.location)).rejects.toBe(boom);
  });
});
