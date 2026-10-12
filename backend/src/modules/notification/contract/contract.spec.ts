import { Channel, NOTIFICATION_SERVICE } from './index';

describe('notification contract', () => {
  it('matches the channel values of the Go backend', () => {
    expect(Object.values(Channel)).toEqual(['push', 'sms', 'inbox']);
  });

  it('names its injection token after the service', () => {
    expect(NOTIFICATION_SERVICE.description).toBe('NotificationService');
  });
});
