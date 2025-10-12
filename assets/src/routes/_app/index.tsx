import { useQuery } from '@tanstack/react-query';
import { createFileRoute, Link } from '@tanstack/react-router';
import client from '../../api/client';
import type { components } from '../../api/schema';
import { Button } from '../../catalyst/button';
import { Heading } from '../../catalyst/heading';
import { Text } from '../../catalyst/text';

type Collection = components['schemas']['Collection'];

function CollectionsDashboard() {
  const collectionsQuery = useQuery({
    queryKey: ['collections'],
    queryFn: async () => {
      const { data, error } = await client.GET('/api/collections');
      if (error) {
        throw error;
      }
      return data?.data ?? [];
    },
  });

  const collections = collectionsQuery.data ?? [];
  const isEmpty = !collections.length && !collectionsQuery.isLoading;

  return (
    <>
      <header className="space-y-4">
        <span className="inline-flex items-center gap-2 rounded-full bg-sky-100 px-4 py-1 text-xs font-semibold uppercase tracking-[0.28em] text-sky-700 shadow-sm shadow-sky-200">
          Your Collections
        </span>
        <div className="flex items-start justify-between gap-6">
          <div className="space-y-3">
            <Heading
              level={1}
              className="text-4xl font-semibold tracking-tight text-slate-900 sm:text-5xl"
            >
              Organize your photo walks into collections
            </Heading>
            <Text className="max-w-2xl text-base leading-relaxed text-slate-600">
              Create collections to group photos from your walks. Each
              collection can hold multiple photos and helps you keep your
              memories organized.
            </Text>
          </div>
          {!isEmpty && (
            <Link to="/collections/new">
              <Button color="sky" className="whitespace-nowrap">
                New Collection
              </Button>
            </Link>
          )}
        </div>
      </header>

      {collectionsQuery.isLoading ? (
        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {Array.from({ length: 6 }).map((_, index) => (
            <div
              key={`collection-skeleton-${index}`}
              className="h-48 rounded-3xl border border-slate-200 bg-white/70 shadow-inner shadow-slate-200/40 backdrop-blur animate-pulse"
            />
          ))}
        </div>
      ) : isEmpty ? (
        <EmptyState />
      ) : (
        <CollectionsGrid collections={collections} />
      )}
    </>
  );
}

function EmptyState() {
  return (
    <div className="flex flex-col items-center justify-center gap-6 rounded-3xl border border-slate-200 bg-white/90 p-16 text-center shadow-xl shadow-slate-200/70 backdrop-blur">
      <div className="flex h-20 w-20 items-center justify-center rounded-full bg-sky-100 text-sky-600 shadow-inner shadow-sky-200/80">
        <span className="text-4xl">📁</span>
      </div>
      <div className="space-y-4">
        <Heading level={2} className="text-2xl font-semibold text-slate-900">
          No collections yet
        </Heading>
        <Text className="max-w-md text-sm text-slate-600">
          Get started by creating your first collection. You can then add photos
          to it and organize your photo walks beautifully.
        </Text>
      </div>
      <Link to="/collections/new">
        <Button color="sky" className="mt-2">
          Create Your First Collection
        </Button>
      </Link>
    </div>
  );
}

interface CollectionsGridProps {
  collections: Collection[];
}

function CollectionsGrid({ collections }: CollectionsGridProps) {
  return (
    <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
      {collections.map(collection => (
        <Link
          key={collection.id}
          to="/collections/$collectionId"
          params={{ collectionId: collection.id?.toString() ?? '' }}
          className="group"
        >
          <article className="relative overflow-hidden rounded-3xl border border-slate-200 bg-white/95 p-6 shadow-xl shadow-slate-200/70 transition duration-200 hover:-translate-y-1 hover:shadow-2xl">
            <div className="space-y-4">
              <div className="flex items-start justify-between gap-4">
                <div className="flex h-12 w-12 items-center justify-center rounded-full bg-sky-100 text-sky-600 shadow-inner shadow-sky-200/70">
                  <span className="text-2xl">📸</span>
                </div>
                <span className="text-xs uppercase tracking-[0.2em] text-slate-500">
                  {formatDate(collection.inserted_at)}
                </span>
              </div>
              <div className="space-y-2">
                <Heading
                  level={3}
                  className="text-xl font-semibold text-slate-900"
                >
                  {collection.title}
                </Heading>
                {collection.description && (
                  <Text className="line-clamp-2 text-sm text-slate-600">
                    {collection.description}
                  </Text>
                )}
              </div>
            </div>
            <div className="pointer-events-none absolute inset-0 rounded-3xl border border-slate-100/80">
              <div className="absolute inset-0 rounded-3xl bg-gradient-to-tr from-sky-100/40 via-transparent to-transparent opacity-0 transition-opacity group-hover:opacity-100" />
            </div>
          </article>
        </Link>
      ))}
    </div>
  );
}

function formatDate(value?: string | null) {
  if (!value) return 'Just now';
  const date = new Date(value);
  return new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  }).format(date);
}

export const Route = createFileRoute('/_app/')({
  component: CollectionsDashboard,
});
