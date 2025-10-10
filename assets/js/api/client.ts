import createClient from 'openapi-fetch';
import type { paths } from './schema';

/**
 * Get CSRF token from the meta tag in the document head
 */
export function getCsrfToken(): string | null {
  const meta = document.querySelector('meta[name="csrf-token"]');
  return meta ? meta.getAttribute('content') : null;
}

/**
 * Create a configured API client with CSRF token
 * The baseUrl is set to "/api" since we're on the same origin
 */
export const client = createClient<paths>({
  baseUrl: '/',
  headers: {
    'Content-Type': 'application/json',
    accept: 'application/json',
  },
});

// Add CSRF token to all requests that modify data
const csrfToken = getCsrfToken();
if (csrfToken) {
  // Add CSRF token to requests that need it (POST, PUT, PATCH, DELETE)
  client.use({
    onRequest({ request, options }) {
      const body = options?.body;
      if (body instanceof FormData) {
        request.headers.delete('Content-Type');
      }

      const method = request.method.toUpperCase();
      if (['POST', 'PUT', 'PATCH', 'DELETE'].includes(method)) {
        request.headers.set('x-csrf-token', csrfToken);
      }
      return request;
    },
  });
}

export default client;
