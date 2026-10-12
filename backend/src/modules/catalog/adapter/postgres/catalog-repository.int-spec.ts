import { onCleanup } from '../../../../../test/kit/cleanup';
import { migratedDatabase } from '../../../../../test/kit/postgres';
import { FakeClock } from '../../../../platform/clock/fake-clock';
import { connectDatabase } from '../../../../platform/db/database';
import { UuidV7Generator } from '../../../../platform/ids/id-generator';
import { PostgresCatalogRepository } from './catalog-repository';

describe('PostgresCatalogRepository', () => {
  it.each(['catalog.categories', 'catalog.services', 'catalog.sub_services'])(
    'reports a tree read with %s missing',
    async (table) => {
      const db = await connectDatabase(await migratedDatabase());
      onCleanup(() => db.close());
      const repo = new PostgresCatalogRepository(
        db,
        new FakeClock(new Date()),
        new UuidV7Generator(),
      );
      await db.query(`ALTER TABLE ${table} RENAME TO broken`);
      await expect(repo.tree()).rejects.toThrow();
    },
  );
});
