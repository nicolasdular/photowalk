import { useCallback, useEffect, useMemo } from 'react';
import { createFileRoute, Link } from '@tanstack/react-router';
import { ArrowLeft, ArrowRight, Cross, Crosshair, X } from 'lucide-react';

import type { components } from '@/api/schema';
import { Spinner } from '@/components/ui/spinner';
import { useCollectionQuery } from '@/lib/hooks/useCollectionQuery';
import { PageTitle } from '@/components/ui/page-title';
import { Avatar, AvatarImage } from '@/components/ui/avatar';

export const Route = createFileRoute(
  '/_app/walks/$collectionId/photos/$photoId'
)({
  component: PhotoDetailRoute,
});

type Photo = components['schemas']['Photo'];

function PhotoDetailRoute() {
  const params = Route.useParams();
  const navigate = Route.useNavigate();
  const {
    data: collection,
    isLoading,
    isError,
  } = useCollectionQuery(params.collectionId);

  const photos = useMemo(
    () => (collection?.photos as Photo[] | undefined) ?? [],
    [collection?.photos]
  );

  const currentIndex = useMemo(
    () => photos.findIndex(photo => String(photo.id) === params.photoId),
    [photos, params.photoId]
  );
  const current = currentIndex >= 0 ? photos[currentIndex] : undefined;
  const prev = currentIndex > 0 ? photos[currentIndex - 1] : undefined;
  const next =
    currentIndex >= 0 && currentIndex < photos.length - 1
      ? photos[currentIndex + 1]
      : undefined;

  const progressLabel = photos.length
    ? `Photo ${Math.max(currentIndex + 1, 1)}/${photos.length}`
    : 'Photo';

  const goToPhoto = useCallback(
    (photo?: Photo) => {
      if (!photo) return;
      navigate({
        to: '/walks/$collectionId/photos/$photoId',
        params: {
          collectionId: params.collectionId,
          photoId: String(photo.id),
        },
      });
    },
    [navigate, params.collectionId]
  );

  const goNext = useCallback(() => goToPhoto(next), [goToPhoto, next]);
  const goPrev = useCallback(() => goToPhoto(prev), [goToPhoto, prev]);

  useEffect(() => {
    if (!isLoading && !current && !isError) {
      navigate({
        to: '/walks/$collectionId',
        params: { collectionId: params.collectionId },
        replace: true,
      });
    }
  }, [navigate, params.collectionId, current, isError, isLoading]);

  useEffect(() => {
    const handleKeydown = (event: KeyboardEvent) => {
      if (event.key === 'ArrowRight') {
        event.preventDefault();
        goNext();
      }

      if (event.key === 'ArrowLeft') {
        event.preventDefault();
        goPrev();
      }

      if (event.key === 'Escape') {
        event.preventDefault();
        navigate({
          to: '/walks/$collectionId',
          params: { collectionId: params.collectionId },
          replace: true,
        });
      }
    };

    window.addEventListener('keydown', handleKeydown);
    return () => window.removeEventListener('keydown', handleKeydown);
  }, [goNext, goPrev]);

  if (isLoading) {
    return (
      <div className="flex min-h-[60vh] w-full items-center justify-center">
        <Spinner className="h-10 w-10" />
      </div>
    );
  }

  if (isError) {
    return <ErrorState />;
  }

  if (!current) {
    return (
      <div className="flex min-h-[60vh] w-full flex-col items-center justify-center gap-4">
        <p className="text-lg font-medium">This photo could not be found.</p>
        <Link
          to="/walks/$collectionId"
          params={{ collectionId: params.collectionId }}
          className="text-primary hover:underline inline-flex items-center gap-2"
        >
          <ArrowLeft className="h-4 w-4" />
          Back to walk
        </Link>
      </div>
    );
  }
  console.log(current.user);

  return (
    <>
      <PageTitle
        title={
          <Avatar>
            <AvatarImage src={current.user?.avatar_url} />
          </Avatar>
        }
        backLink={
          <Link
            to="/walks/$collectionId"
            params={{ collectionId: params.collectionId }}
            className="inline-flex items-center gap-2"
          >
            <X className="h-4 w-4" />
          </Link>
        }
        actions={
          <div>
            <div className="flex items-center justify-end">
              <button
                type="button"
                onClick={goPrev}
                disabled={!prev}
                className="group disabled:opacity-40 disabled:cursor-not-allowed"
              >
                <ArrowLeft
                  className={`h-4 w-4 transition-colors ${
                    !prev
                      ? 'text-gray-400'
                      : 'text-primary group-hover:text-primary-700'
                  }`}
                />
              </button>
              <button
                type="button"
                onClick={goNext}
                disabled={!next}
                className="group disabled:opacity-40 disabled:cursor-not-allowed"
              >
                <ArrowRight
                  className={`h-4 w-4 transition-colors ${
                    !next
                      ? 'text-gray-400'
                      : 'text-primary group-hover:text-primary-700'
                  }`}
                />
              </button>
            </div>
            <span className="text-xs uppercase tracking-[0.2em] opacity-70">
              {progressLabel}
            </span>
          </div>
        }
      />

      <div className="space-y-6">
        <div className="relative flex items-center justify-center overflow-hidden rounded-2xl ">
          <img
            src={current.full_url}
            alt={current.title || 'Photo'}
            className="max-h-[70vh] w-full object-contain"
          />
        </div>
      </div>
    </>
  );
}

function ErrorState() {
  return (
    <div className="flex min-h-[60vh] w-full flex-col items-center justify-center gap-4 text-center">
      <p className="text-lg font-medium">We couldn't load this photo.</p>
    </div>
  );
}
