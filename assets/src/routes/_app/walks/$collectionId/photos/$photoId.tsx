import { useCallback, useEffect, useMemo } from 'react';
import { createFileRoute, Link } from '@tanstack/react-router';
import { ArrowLeft, ArrowRight } from 'lucide-react';

import type { components } from '@/api/schema';
import { Spinner } from '@/components/ui/spinner';
import { useCollectionQuery } from '@/lib/hooks/useCollectionQuery';
import { UserAvatar } from '@/components/user-avatar';

export const Route = createFileRoute('/_app/walks/$collectionId/photos/$photoId')({
  component: PhotoDetailRoute,
});

type Photo = components['schemas']['CollectionDetail']['photos'][0];

function PhotoDetailRoute() {
  const params = Route.useParams();
  const navigate = Route.useNavigate();
  const { data: collection, isLoading, isError } = useCollectionQuery(params.collectionId);

  const photos = useMemo(() => (collection?.photos as Photo[] | undefined) ?? [], [collection?.photos]);

  const currentIndex = useMemo(
    () => photos.findIndex(photo => String(photo.id) === params.photoId),
    [photos, params.photoId]
  );
  const current = currentIndex >= 0 ? photos[currentIndex] : undefined;
  const prev = currentIndex > 0 ? photos[currentIndex - 1] : undefined;
  const next = currentIndex >= 0 && currentIndex < photos.length - 1 ? photos[currentIndex + 1] : undefined;

  const progressLabel = photos.length ? `Photo ${Math.max(currentIndex + 1, 1)}/${photos.length}` : 'Photo';

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

  return (
    <div className="h-[calc(100vh-8rem)] flex flex-col">
      {/* Compact header */}
      <div className="flex items-center justify-between px-4 py-2 border-b flex-shrink-0">
        <Link
          to="/walks/$collectionId"
          params={{ collectionId: params.collectionId }}
          className="inline-flex items-center gap-2 text-foreground hover:text-foreground/80 transition-colors text-sm"
        >
          <ArrowLeft className="h-4 w-4" />
          Back
        </Link>
        <span className="text-sm text-muted-foreground">{progressLabel}</span>
        <UserAvatar user={current.user} />
      </div>

      {/* Full-screen image */}
      <div className="flex-1 flex items-center justify-center p-4 overflow-hidden">
        <img src={current.full_url} alt={current.title || 'Photo'} className="max-w-full max-h-full object-contain" />
      </div>

      {/* Bottom navigation */}
      <div className="flex items-center justify-center p-4 border-t flex-shrink-0">
        <div className="flex items-center gap-6">
          <button
            type="button"
            onClick={goPrev}
            disabled={!prev}
            className="group disabled:opacity-40 disabled:cursor-not-allowed"
          >
            <ArrowLeft
              className={`h-6 w-6 transition-colors ${
                !prev ? 'text-muted-foreground' : 'text-foreground group-hover:text-foreground/80'
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
              className={`h-6 w-6 transition-colors ${
                !next ? 'text-muted-foreground' : 'text-foreground group-hover:text-foreground/80'
              }`}
            />
          </button>
        </div>
      </div>
    </div>
  );
}

function ErrorState() {
  return (
    <div className="flex min-h-[60vh] w-full flex-col items-center justify-center gap-4 text-center">
      <p className="text-lg font-medium">We couldn't load this photo.</p>
    </div>
  );
}
