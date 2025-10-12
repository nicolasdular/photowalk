import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { createFileRoute, Link } from '@tanstack/react-router';
import client from '../../../api/client';
import type { components } from '../../../api/schema';
import { useState } from 'react';
import { Heading } from '../../../catalyst/heading';
import { Text } from '../../../catalyst/text';
import { PhotoUpload } from '../../../components/PhotoUpload';
import { Button } from '../../../catalyst/button';

type Collection = components['schemas']['Collection'];
type Photo = components['schemas']['Photo'];

function CollectionDetailPage() {
  const { collectionId } = Route.useParams();
  const queryClient = useQueryClient();
  const [deleteError, setDeleteError] = useState<string | null>(null);
  const [pendingPhotoId, setPendingPhotoId] = useState<number | null>(null);

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
  const photos = (collection?.photos as Photo[] | undefined) ?? [];
  const isLoading = collectionQuery.isLoading;

  const deletePhotoMutation = useMutation({
    mutationFn: async (photoId: number) => {
      const { error } = await client.DELETE('/api/photos/{id}', {
        params: { path: { id: photoId } },
      });

      if (error) {
        throw error;
      }
    },
    onMutate: photoId => {
      setDeleteError(null);
      setPendingPhotoId(photoId);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['collection', collectionId] });
    },
    onError: error => {
      console.error('Failed to delete photo', error);
      setDeleteError('We could not delete this photo. Please try again.');
    },
    onSettled: () => {
      setPendingPhotoId(null);
    },
  });

  const handleDeletePhoto = (photoId: number) => {
    deletePhotoMutation.mutate(photoId);
  };

  if (isLoading) {
    return null;
  }

  if (!collection) {
    return (
      <div className="min-h-[calc(100vh-4rem)] bg-gradient-to-br from-slate-50 via-white to-sky-50 pb-24 pt-16 text-slate-900">
        <div className="mx-auto w-full max-w-6xl space-y-10 px-6 sm:px-10">
          <div className="flex flex-col items-center justify-center gap-6 rounded-3xl border border-slate-200 bg-white/95 p-16 text-center shadow-xl shadow-slate-200/70">
            <Heading level={2} className="text-2xl font-semibold text-slate-900">
              Collection not found
            </Heading>
            <Link to="/" className="text-sky-600 hover:text-sky-500">
              ← Back to collections
            </Link>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-[calc(100vh-4rem)] bg-gradient-to-br from-slate-50 via-white to-sky-50 pb-24 pt-16 text-slate-900">
      <div className="mx-auto w-full max-w-6xl space-y-10 px-6 sm:px-10">
        <header className="space-y-4">
          <Link
            to="/"
            className="inline-flex items-center gap-2 text-sm text-sky-600 hover:text-sky-500"
          >
            ← Back to collections
          </Link>
          <div className="space-y-3">
            <Heading
              level={1}
              className="text-4xl font-semibold tracking-tight text-slate-900 sm:text-5xl"
            >
              {collection.title}
            </Heading>
            {collection.description && (
              <Text className="max-w-2xl text-base leading-relaxed text-slate-600">
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
          <Heading level={2} className="text-2xl font-semibold text-slate-900">
            Photos in this collection
          </Heading>

          {deleteError && (
            <div className="rounded-xl border border-rose-200 bg-rose-50/80 px-4 py-3 text-sm text-rose-700 shadow-sm">
              {deleteError}
            </div>
          )}

          {collectionQuery.isLoading ? (
            <div className="grid gap-6 sm:grid-cols-2 xl:grid-cols-3">
              {Array.from({ length: 6 }).map((_, index) => (
                <div
                  key={`skeleton-${index}`}
                  className="h-64 animate-pulse rounded-3xl border border-slate-200 bg-white/70 shadow-inner shadow-slate-200/40"
                />
              ))}
            </div>
          ) : photos.length === 0 ? (
            <div className="flex flex-col items-center justify-center gap-4 rounded-3xl border border-slate-200 bg-white/95 p-12 text-center shadow-xl shadow-slate-200/70">
              <div className="flex h-14 w-14 items-center justify-center rounded-full bg-sky-100 text-sky-600 shadow-inner shadow-sky-200/80">
                <span className="text-2xl">📷</span>
              </div>
              <div className="space-y-2">
                <Heading level={3} className="text-xl font-semibold text-slate-900">
                  No photos yet
                </Heading>
                <Text className="text-sm text-slate-600">
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
                  className="group relative overflow-hidden rounded-3xl border border-slate-200 bg-white/95 shadow-xl shadow-slate-200/70 transition duration-200 hover:-translate-y-1 hover:shadow-2xl"
                >
                  <img
                    src={photo.thumbnail_url}
                    alt={photo.title || 'Photo'}
                    className="h-64 w-full object-cover transition duration-300 group-hover:scale-[1.03]"
                    loading="lazy"
                  />
                  <figcaption className="flex flex-col gap-3 border-t border-slate-100 bg-gradient-to-b from-white via-white to-slate-50 p-5 text-sm text-slate-600">
                    <div className="flex items-center justify-between text-xs uppercase tracking-[0.2em] text-slate-500">
                      <span>{formatDate(photo.inserted_at)}</span>
                      <span className="rounded-full bg-sky-100 px-2 py-0.5 text-sky-700">
                        Full &amp; thumbnail
                      </span>
                    </div>
                    <div>
                      <p className="text-base font-semibold text-slate-900">
                        {photo.title || 'Untitled capture'}
                      </p>
                      <p className="mt-1 text-xs text-slate-500">
                        Ready to share — optimized in two resolutions.
                      </p>
                    </div>
                    <div className="flex items-center justify-between text-xs">
                      <a
                        href={photo.full_url}
                        className="inline-flex items-center gap-1 rounded-full bg-sky-100 px-3 py-1 font-medium text-sky-700 transition hover:bg-sky-200"
                        target="_blank"
                        rel="noreferrer"
                      >
                        View full size ↗
                      </a>
                      {photo.allowed_to_delete && (
                        <Button
                          color="rose"
                          onClick={() => handleDeletePhoto(photo.id)}
                          disabled={pendingPhotoId === photo.id}
                          className="!px-3 !py-1 text-xs font-semibold uppercase tracking-[0.18em]"
                        >
                          {pendingPhotoId === photo.id ? 'Deleting…' : 'Delete'}
                        </Button>
                      )}
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
