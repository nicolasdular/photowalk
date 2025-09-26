import { StrictMode } from 'preact/compat';
import 'vite/modulepreload-polyfill';
import { render } from 'preact';
import { Todos } from './pages/Todos';
import { SignUp } from './pages/SignUp';
import {
  Outlet,
  RouterProvider,
  createRouter,
  createRoute,
  createRootRoute,
  useLoaderData,
} from '@tanstack/react-router';
import {
  QueryClient,
  QueryClientProvider,
  useMutation,
} from '@tanstack/react-query';
import { getCurrentUser } from './auth';
import { SignedInLayout } from './layouts/SignedInLayout';

const rootRoute = createRootRoute({
  loader: async () => {
    return { currentUser: await getCurrentUser() };
  },
  component: () => {
    // Access loader data using useLoaderData<typeof rootRoute>()
    const { currentUser } = useLoaderData({ from: rootRoute.id });
    // Authenticated root layout below renders the app chrome

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
        console.log('SUCCESS');
        // Force a full page reload so SPA state is reset
        window.location.replace('/');
      },
    });

    if (!currentUser) {
      return <SignUp />;
    }

    return (
      <SignedInLayout
        onSignOut={() => signOut.mutate()}
        signingOut={signOut.isPending}
        currentUserAvatarUrl={currentUser.avatarUrl}
      >
        <Outlet />
      </SignedInLayout>
    );
  },
  errorComponent: ({ error }) => (
    <div className="p-4 text-red-600">
      <h2>Something went wrong!</h2>
      <pre>{error.message}</pre>
    </div>
  ),
});

const indexRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/',
  component: Todos,
});

const aboutRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/signup',
  component: SignUp,
});

const routeTree = rootRoute.addChildren([indexRoute, aboutRoute]);

const router = createRouter({ routeTree });

declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router;
  }
}

const queryClient = new QueryClient();
const preactContainer = document.getElementById('preact-app');

if (preactContainer) {
  render(
    <StrictMode>
      <QueryClientProvider client={queryClient}>
        <RouterProvider router={router} />
      </QueryClientProvider>
    </StrictMode>,
    preactContainer
  );
}
