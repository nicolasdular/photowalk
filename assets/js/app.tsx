import { StrictMode } from 'preact/compat';
import 'vite/modulepreload-polyfill';
import { render } from 'preact';
import { Todos } from './pages/Todos';
import { SignUp } from './pages/SignUp';
import {
  Outlet,
  RouterProvider,
  Link,
  createRouter,
  createRoute,
  createRootRoute,
  useLoaderData,
} from '@tanstack/react-router';
import { TanStackRouterDevtools } from '@tanstack/react-router-devtools';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { getCurrentUser } from './auth';

const rootRoute = createRootRoute({
  loader: async () => {
    return { currentUser: await getCurrentUser() };
  },
  component: () => {
    // Access loader data using useLoaderData<typeof rootRoute>()
    const { currentUser } = useLoaderData({ from: rootRoute.id });

    if (!currentUser) {
      return <SignUp />;
    }

    return (
      <>
        <div className="p-2 flex gap-2">
          <div>{currentUser.email}</div>
          <Link to="/" className="[&.active]:font-bold">
            Home
          </Link>
        </div>
        <hr />
        <Outlet />
        <TanStackRouterDevtools />
      </>
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
