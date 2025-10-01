// Auth utilities for TanStack Router integration
import { client } from './api/client';

// Type for the current user data from OpenAPI
export type CurrentUser = {
  id: number;
  email: string;
  confirmed_at?: string | null;
} | null;

// Auth context type
export interface AuthContext {
  user: CurrentUser;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
  checkAuth: () => Promise<void>;
}

// Hook to get current user from OpenAPI endpoint
export async function getCurrentUser(): Promise<CurrentUser> {
  try {
    const response = await client.GET('/api/user/me');

    if (response.error) {
      // User is not authenticated or there was an error
      return null;
    }

    return response.data?.data || null;
  } catch (error) {
    console.error('Error fetching current user:', error);
    return null;
  }
}
