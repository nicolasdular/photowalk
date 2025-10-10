import { useQuery } from '@tanstack/react-query';
import { createFileRoute, Link } from '@tanstack/react-router';
import client from '../../../api/client';
import type { components } from '../../../api/schema';
import { Heading } from '../../../catalyst/heading';
import { Text } from '../../../catalyst/text';
import { PhotoUpload } from '../../../components/PhotoUpload';

type Collection = components['schemas']['Collection'];
type Photo = components['schemas']['Photo'];

function CollectionDetailPage() {
  const { collectionId } = Route.useParams();

  const collectionQuery = useQuery({
    queryKey: ['collection', collectionId],
    queryFn: async () => {
      const { data, error } = await client.GET('/api/collections/{id}', {
        params: { path: { id: parseInt(collectionId) } },
      });
      if (error) {
        throw error;
      }
      return data?.data;
    },
  });

  const collection = collectionQuery.data;
  const photos = (collection as any)?.photos ?? [];
  const isLoading = collectionQuery.isLoading;

  if (isLoading) {
    return (
      <div className="min-h-[calc(100vh-4rem)] bg-slate-950 pb-24 pt-16 text-slate-50">
        <div className="mx-auto w-full max-w-6xl space-y-10 px-6 sm:px-10">
          <div className="h-32 animate-pulse rounded-3xl bg-slate-800/70" />
          <div className="h-64 animate-pulse rounded-3xl bg-slate-800/70" />
        </div>
      </div>
    );
  }

  if (!collection) {
    return (
      <div className="min-h-[calc(100vh-4rem)] bg-slate-950 pb-24 pt-16 text-slate-50">
        <div className="mx-auto w-full max-w-6xl space-y-10 px-6 sm:px-10">
          <div className="flex flex-col items-center justify-center gap-6 rounded-3xl border border-slate-800/80 bg-slate-900/70 p-16 text-center">
            <Heading level={2} className="text-2xl font-semibold text-white">
              Collection not found
            </Heading>
            <Link to="/" className="text-sky-200 hover:text-sky-100">
              ← Back to collections
            </Link>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-[calc(100vh-4rem)] bg-slate-950 pb-24 pt-16 text-slate-50">
      <div className="mx-auto w-full max-w-6xl space-y-10 px-6 sm:px-10">
        <header className="space-y-4">
          <Link
            to="/"
            className="inline-flex items-center gap-2 text-sm text-sky-200 hover:text-sky-100"
          >
            ← Back to collections
          </Link>
          <div className="space-y-3">
            <Heading
              level={1}
              className="text-4xl font-semibold tracking-tight text-white sm:text-5xl"
            >
              {collection.title}
            </Heading>
            {collection.description && (
              <Text className="max-w-2xl text-base leading-relaxed text-slate-300">
                {collection.description}
              </Text>
            )}
          </div>
        </header>

        <PhotoUpload
          collectionId={parseInt(collectionId)}
          queryKey={['collection', collectionId]}
        />

        <section className="space-y-6">
          <Heading level={2} className="text-2xl font-semibold text-white">
            Photos in this collection
          </Heading>

          {collectionQuery.isLoading ? (
            <div className="grid gap-6 sm:grid-cols-2 xl:grid-cols-3">
              {Array.from({ length: 6 }).map((_, index) => (
                <div
                  key={`skeleton-${index}`}
                  className="h-64 animate-pulse rounded-3xl bg-slate-800/70"
                />
              ))}
            </div>
          ) : photos.length === 0 ? (
            <div className="flex flex-col items-center justify-center gap-4 rounded-3xl border border-slate-800/80 bg-slate-900/70 p-12 text-center">
              <div className="flex h-14 w-14 items-center justify-center rounded-full bg-slate-800/80 text-slate-300">
                <span className="text-2xl">📷</span>
              </div>
              <div className="space-y-2">
                <Heading level={3} className="text-xl font-semibold text-white">
                  No photos yet
                </Heading>
                <Text className="text-sm text-slate-400">
                  Upload your first photo to this collection using the form
                  above.
                </Text>
              </div>
            </div>
          ) : (
            <div className="grid gap-6 sm:grid-cols-2 xl:grid-cols-3">
              {photos.map(photo => (
                <figure
                  key={photo.id}
                  className="group relative overflow-hidden rounded-3xl bg-slate-900/80 shadow-[0_25px_60px_-30px_rgba(15,23,42,0.9)] transition hover:-translate-y-1 hover:shadow-[0_30px_80px_-40px_rgba(59,130,246,0.5)]"
                >
                  <img
                    src={photo.thumbnail_url}
                    alt={photo.title || 'Photo'}
                    className="h-64 w-full object-cover transition duration-300 group-hover:scale-[1.03]"
                    loading="lazy"
                  />
                  <figcaption className="flex flex-col gap-3 border-t border-white/5 bg-gradient-to-b from-transparent via-slate-950/60 to-slate-950/90 p-5 text-sm text-slate-300">
                    <div className="flex items-center justify-between text-xs uppercase tracking-[0.2em] text-slate-500">
                      <span>{formatDate(photo.inserted_at)}</span>
                      <span className="rounded-full bg-sky-500/10 px-2 py-0.5 text-sky-200">
                        Full &amp; thumbnail
                      </span>
                    </div>
                    <div>
                      <p className="text-base font-semibold text-white">
                        {photo.title || 'Untitled capture'}
                      </p>
                      <p className="mt-1 text-xs text-slate-400">
                        Ready to share — optimized in two resolutions.
                      </p>
                    </div>
                    <div className="flex items-center justify-between text-xs">
                      <a
                        href={photo.full_url}
                        className="inline-flex items-center gap-1 rounded-full bg-sky-500/10 px-3 py-1 font-medium text-sky-200 transition hover:bg-sky-500/20"
                        target="_blank"
                        rel="noreferrer"
                      >
                        View full size ↗
                      </a>
                    </div>
                  </figcaption>
                </figure>
              ))}
            </div>
          )}
        </section>
      </div>
    </div>
  );
}

function formatDate(value?: string | null) {
  if (!value) return 'Just now';
  const date = new Date(value);
  return new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(date);
}

export const Route = createFileRoute('/_app/collections/$collectionId')({
  component: CollectionDetailPage,
});
