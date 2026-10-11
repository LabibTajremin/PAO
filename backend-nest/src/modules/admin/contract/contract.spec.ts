import { ADMIN_SERVICE, AdminEvents } from './index';

describe('admin contract', () => {
  it('keeps the stored event names of the Go backend', () => {
    expect(AdminEvents).toEqual({
      ComplaintCreated: 'admin.ComplaintCreated',
      ComplaintResolved: 'admin.ComplaintResolved',
      SettingChanged: 'admin.SettingChanged',
    });
  });

  it('names its injection token after the service', () => {
    expect(ADMIN_SERVICE.description).toBe('AdminService');
  });
});
