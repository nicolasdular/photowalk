// Auth utilities for TanStack Router integration
import {
  currentUser,
  type CurrentUserFields,
  type SuccessDataFunc,
} from './ash_rpc';

// Define the fields we want from the user
export const USER_FIELDS: CurrentUserFields = [
  'id',
  'email',
  'avatarUrl',
] as const;

// Type for the current user data
export type CurrentUser = SuccessDataFunc<
  typeof currentUser<typeof USER_FIELDS>
>;

// Auth context type
export interface AuthContext {
  user: CurrentUser;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
  checkAuth: () => Promise<void>;
}

// Hook to get current user from RPC
export async function getCurrentUser(): Promise<CurrentUser> {
  try {
    const result = await currentUser({
      fields: USER_FIELDS,
    });

    if (result.success) {
      return result.data;
    } else {
      // User is not authenticated or there was an error
      return null;
    }
  } catch (error) {
    console.error('Error fetching current user:', error);
    return null;
  }
}
