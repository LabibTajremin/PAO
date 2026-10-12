import { JWT } from 'google-auth-library';
import { type Push } from '../../domain/notification';
import { InvalidTokenError, type Pusher } from '../../port/ports';

const FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';

/** Returns a bearer token for the FCM API. */
export type AccessToken = () => Promise<string>;

/** Sends through the Firebase Cloud Messaging HTTP v1 API. */
export class FcmPusher implements Pusher {
  constructor(
    readonly endpoint: string,
    private readonly accessToken: AccessToken,
  ) {}

  /**
   * FCM answers 404 (UNREGISTERED) or 400 for tokens that will never work again; those
   * become {@link InvalidTokenError}.
   */
  async push(token: string, p: Push): Promise<void> {
    const message = {
      token,
      notification: { title: p.title, body: p.body },
      data: p.data,
      android: { priority: 'high' },
    };
    const res = await fetch(this.endpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${await this.accessToken()}`,
      },
      body: JSON.stringify({ message }),
    });
    if (res.status === 404 || res.status === 400) {
      throw new InvalidTokenError();
    }
    if (res.status >= 300) {
      const body = (await res.text()).slice(0, 512);
      throw new Error(`fcm: ${res.status} ${body}`);
    }
  }
}

interface ServiceAccount {
  readonly project_id: string;
  readonly client_email: string;
  readonly private_key: string;
}

function serviceAccount(json: string): ServiceAccount {
  const raw = JSON.parse(json) as Partial<Record<keyof ServiceAccount, unknown>>;
  const { project_id: project, client_email: email, private_key: key } = raw;
  if (typeof project !== 'string' || typeof email !== 'string' || typeof key !== 'string') {
    throw new Error('fcm credentials: project_id, client_email and private_key are required');
  }
  return { project_id: project, client_email: email, private_key: key };
}

/** Authenticates with a service-account key (the contents of FCM_CREDENTIALS_FILE). */
export function fcmFromCredentials(json: string): FcmPusher {
  const account = serviceAccount(json);
  const jwt = new JWT({
    email: account.client_email,
    key: account.private_key,
    scopes: [FCM_SCOPE],
  });
  const endpoint = `https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`;
  return new FcmPusher(endpoint, async () => {
    const { token } = await jwt.getAccessToken();
    if (!token) {
      throw new Error('fcm: no access token');
    }
    return token;
  });
}
