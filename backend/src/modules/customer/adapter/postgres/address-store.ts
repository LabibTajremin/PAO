import { type PoolClient } from 'pg';
import { type Database, type SqlClient } from '../../../../platform/db/database';
import { DomainError } from '../../../../platform/errors/domain-error';
import { CustomerReasons } from '../../app/errors';
import { type Address } from '../../domain/customer';
import {
  addressByID,
  type AddressByIDRow,
  clearDefault,
  countAddresses,
  deleteAddress,
  insertAddress,
  listAddresses,
  lockCustomer,
  markDefaultQuery,
  promoteNewest,
  updateAddressQuery,
} from './sqlc/queries_sql';

function toAddress(r: AddressByIDRow): Address {
  return {
    id: r.id,
    customerId: r.customerId,
    label: r.label,
    line1: r.line1,
    line2: r.line2,
    area: r.area,
    location: { lat: r.lat, lng: r.lng },
    isDefault: r.isDefault,
    createdAt: r.createdAt,
  };
}

const notFound = (): DomainError => new DomainError(CustomerReasons.AddressNotFound);

async function markDefault(tx: SqlClient, customerId: string, addressId: string): Promise<void> {
  await clearDefault(tx, { customerId });
  // sqlc's TypeScript plugin has no :execrows, so the row count is read here.
  const res = await tx.query(markDefaultQuery, [addressId, customerId]);
  if (res.rowCount === 0) {
    throw notFound();
  }
}

/** Saved addresses; writes hold the customer's row lock so limit and default checks race no one. */
export abstract class AddressStore {
  constructor(protected readonly db: Database) {}

  addAddress(a: Address, limit: number): Promise<Address> {
    return this.locked(a.customerId, async (tx) => {
      const count = Number((await countAddresses(tx, { customerId: a.customerId }))?.count);
      if (count >= limit) {
        throw new DomainError(CustomerReasons.AddressLimit);
      }
      const saved = { ...a, isDefault: a.isDefault || count === 0 };
      if (saved.isDefault) {
        await clearDefault(tx, { customerId: a.customerId });
      }
      await insertAddress(tx, { ...saved, ...saved.location });
      return saved;
    });
  }

  /** Turning the default off is not possible here: a customer picks another address instead. */
  updateAddress(a: Address, updatedAt: Date): Promise<void> {
    return this.locked(a.customerId, async (tx) => {
      const { lat, lng } = a.location;
      const values = [a.label, a.line1, a.line2, a.area, lng, lat, updatedAt, a.id, a.customerId];
      if ((await tx.query(updateAddressQuery, values)).rowCount === 0) {
        throw notFound();
      }
      if (a.isDefault) {
        await markDefault(tx, a.customerId, a.id);
      }
    });
  }

  setDefault(customerId: string, addressId: string): Promise<void> {
    return this.locked(customerId, (tx) => markDefault(tx, customerId, addressId));
  }

  deleteAddress(customerId: string, addressId: string): Promise<void> {
    return this.locked(customerId, async (tx) => {
      const row = await deleteAddress(tx, { id: addressId, customerId });
      if (row === null) {
        throw notFound();
      }
      if (row.isDefault) {
        await promoteNewest(tx, { customerId });
      }
    });
  }

  async listAddresses(customerId: string): Promise<Address[]> {
    return (await listAddresses(this.db.pool, { customerId })).map(toAddress);
  }

  async getAddress(customerId: string, addressId: string): Promise<Address> {
    const row = await addressByID(this.db.pool, { id: addressId, customerId });
    if (row === null) {
      throw notFound();
    }
    return toAddress(row);
  }

  private locked<T>(customerId: string, fn: (tx: PoolClient) => Promise<T>): Promise<T> {
    return this.db.transaction(async (tx) => {
      if ((await lockCustomer(tx, { id: customerId })) === null) {
        throw new DomainError(CustomerReasons.ProfileRequired);
      }
      return fn(tx);
    });
  }
}
