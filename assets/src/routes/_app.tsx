import {
  Outlet,
  createFileRoute,
  redirect,
  useLoaderData,
} from '@tanstack/react-router';
import { useMutation } from '@tanstack/react-query';
import { SignedInLayout } from '../layouts/SignedInLayout';
import client from '../api/client';

export const Route = createFileRoute('/_app')({
  loader: async ({ context }) => {
    const currentUser = await context.queryClient.ensureQueryData({
      queryKey: ['currentUser'],
      staleTime: Infinity,
      queryFn: async () => {
        const response = await client.GET('/api/user/me');
        if (!response.data) {
          throw redirect({ to: '/signin' });
        }

        return response.data.data;
      },
    });

    return { currentUser } as const;
  },
  component: () => {
    const { currentUser } = useLoaderData({ from: Route.id });

    const signOut = useMutation({
      mutationFn: async () => {
        const csrf =
          document
            .querySelector('meta[name="csrf-token"]')
            ?.getAttribute('content') || '';

        const res = await fetch('/auth/sign_out', {
          method: 'DELETE',
          headers: {
            'x-csrf-token': csrf,
            accept: 'text/html,application/json,*/*',
          },
          credentials: 'same-origin',
          redirect: 'follow',
        });

        if (res.status >= 400) {
          throw new Error('Failed to sign out');
        }
      },
      onSuccess: async () => {
        window.location.replace('/');
      },
    });

    return (
      <SignedInLayout
        onSignOut={() => signOut.mutate()}
        signingOut={signOut.isPending}
        currentUser={currentUser}
      >
        <Outlet />
      </SignedInLayout>
    );
  },
});
