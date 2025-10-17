import { StrictMode, Suspense } from 'react';
import { createRoot } from 'react-dom/client';
import { RouterProvider, createRouter } from '@tanstack/react-router';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { routeTree } from './routeTree.gen';

const queryClient = new QueryClient();

const router = createRouter({
  routeTree,
  context: {
    queryClient,
  },
});

declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router;
  }
}

const reactContainer = document.getElementById('react-app');

if (reactContainer) {
  const root = createRoot(reactContainer);
  root.render(
    <StrictMode>
      <QueryClientProvider client={queryClient}>
        <Suspense fallback={<div />}>
          <RouterProvider router={router} />
        </Suspense>
      </QueryClientProvider>
    </StrictMode>
  );
}
