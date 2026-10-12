import { Global, Inject, Injectable, Module } from '@nestjs/common';
import { ModuleRef } from '@nestjs/core';
import { Test } from '@nestjs/testing';
import { LazyContract } from './lazy-contract';

const LEVELS = Symbol('Levels');
const ACCOUNTS = Symbol('Accounts');

interface Levels {
  level(id: string): number;
}

interface Accounts {
  name(id: string): string;
}

@Injectable()
class AccountsService implements Accounts {
  private readonly levels: LazyContract<Levels>;

  constructor(@Inject(ModuleRef) moduleRef: ModuleRef) {
    this.levels = new LazyContract<Levels>(moduleRef, LEVELS);
  }

  name(id: string): string {
    return `${id} at level ${this.levels.get().level(id)}`;
  }
}

@Injectable()
class LevelsService implements Levels {
  constructor(@Inject(ACCOUNTS) private readonly accounts: Accounts) {}

  level(id: string): number {
    return id === 'p1' ? 2 : this.accounts.name('p1').length;
  }
}

@Global()
@Module({
  providers: [{ provide: ACCOUNTS, useClass: AccountsService }],
  exports: [ACCOUNTS],
})
class IdentityModule {}

@Global()
@Module({ providers: [{ provide: LEVELS, useClass: LevelsService }], exports: [LEVELS] })
class VerificationModule {}

describe('LazyContract', () => {
  it('breaks a cycle between two modules and resolves once', async () => {
    const ref = await Test.createTestingModule({
      imports: [IdentityModule, VerificationModule],
    }).compile();
    const accounts = ref.get<Accounts>(ACCOUNTS);
    expect(accounts.name('p1')).toBe('p1 at level 2');
    expect(accounts.name('p1')).toBe('p1 at level 2');
    expect(ref.get<Levels>(LEVELS).level('p2')).toBe('p1 at level 2'.length);
  });
});
