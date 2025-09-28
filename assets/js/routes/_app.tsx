import { Outlet, createFileRoute, redirect, useLoaderData } from '@tanstack/react-router';
import { useMutation } from '@tanstack/react-query';
import { getCurrentUser } from '../auth';
import { SignedInLayout } from '../layouts/SignedInLayout';

export const Route = createFileRoute('/_app')({
  loader: async () => {
    const currentUser = await getCurrentUser();
    if (!currentUser) {
      throw redirect({ to: '/signup' });
    }
    return { currentUser } as const;
  },
  component: () => {
    const { currentUser } = useLoaderData({ from: Route.id }) as { currentUser: any };

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
        currentUserAvatarUrl={currentUser?.avatarUrl ?? null}
      >
        <Outlet />
      </SignedInLayout>
    );
  },
});
