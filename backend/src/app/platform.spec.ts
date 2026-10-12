import { type INestApplicationContext } from '@nestjs/common';
import { testHookSeams } from './platform';

describe('testHookSeams', () => {
  it('leaves out seams no module provides', () => {
    const app = {
      get: () => {
        throw new Error('no provider');
      },
    } as unknown as INestApplicationContext;
    expect(testHookSeams(app)).toEqual({ sms: undefined, push: undefined, expiry: undefined });
  });
});
