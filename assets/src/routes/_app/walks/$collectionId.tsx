import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { createFileRoute, Link } from '@tanstack/react-router';
import client from '../../../api/client';
import type { components } from '../../../api/schema';
import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Spinner } from '@/components/ui/spinner';
import { ArrowLeft, CameraIcon, ExternalLink } from 'lucide-react';
import { PageTitle } from '@/components/ui/page-title';
import { PageLoading } from '@/components/ui/page-loading';
import {
  Empty,
  EmptyContent,
  EmptyDescription,
  EmptyHeader,
  EmptyMedia,
  EmptyTitle,
} from '@/components/ui/empty';
import { UploadPhotosButton } from '@/components/upload-photos-button';

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
    return <PageLoading title={<span>Loading walk...</span>} />;
  }

  const refetchCollection = () => {
    collectionQuery.refetch();
  };

  if (!collection) {
    return (
      <div className="container mx-auto max-w-6xl py-8 px-4">
        <div className="text-center py-12">
          <h2 className="text-2xl font-semibold mb-4">Walk not found</h2>
          <Link
            to="/"
            className="text-primary hover:underline inline-flex items-center gap-2"
          >
            <ArrowLeft className="h-4 w-4" />
            Back to walks
          </Link>
        </div>
      </div>
    );
  }

  if (collection?.photos?.length === 0) {
    return (
      <EmptyState collectionId={collection.id} onSuccess={refetchCollection} />
    );
  }

  return (
    <>
      <PageTitle
        backLink={
          <Link to="/" className="inline-flex items-center gap-2">
            <ArrowLeft className="h-4 w-4" />
            Back to walks
          </Link>
        }
        actions={
          <UploadPhotosButton
            collectionId={collection.id}
            onSuccess={refetchCollection}
          />
        }
        title={collection.title}
        subTitle={<span>{collection.photos?.length} Photos</span>}
      ></PageTitle>
      {collection.description && (
        <p className="text-muted-foreground">{collection.description}</p>
      )}

      <section className="space-y-6">
        {deleteError && (
          <div className="rounded-lg border border-destructive/50 bg-destructive/10 px-4 py-3 text-sm text-destructive">
            {deleteError}
          </div>
        )}

        {collectionQuery.isLoading ? (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {Array.from({ length: 6 }).map((_, index) => (
              <div
                key={`skeleton-${index}`}
                className="h-64 animate-pulse rounded-lg bg-muted"
              />
            ))}
          </div>
        ) : photos.length === 0 ? (
          <div className="text-center py-12 border rounded-lg bg-muted/20">
            <h3 className="text-lg font-semibold mb-2">No photos yet</h3>
            <p className="text-sm text-muted-foreground">
              Upload your first photo to this collection.
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-6">
            {photos.map(photo => (
              <div key={photo.id} className="group relative flex flex-col ">
                <div className="aspect-[4/5] w-full overflow-hidden bg-muted">
                  <img
                    src={photo.thumbnail_url}
                    alt={photo.title || 'Photo'}
                    className="h-full w-full object-cover rounded-xl"
                    loading="lazy"
                  />
                </div>
                <div className="flex-1 flex flex-col justify-between p-4 space-y-2">
                  <div className="flex items-center justify-between text-xs text-muted-foreground">
                    <span>{formatDate(photo.inserted_at)}</span>
                  </div>
                  <div>
                    <p className="font-semibold truncate">
                      {photo.title || 'Untitled'}
                    </p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </section>
    </>
  );
}

function EmptyState({
  collectionId,
  onSuccess,
}: {
  collectionId: number;
  onSuccess: () => void;
}) {
  return (
    <Empty>
      <EmptyHeader>
        <EmptyMedia variant="icon">
          <CameraIcon />
        </EmptyMedia>
        <EmptyTitle>No photos yet</EmptyTitle>
        <EmptyDescription>Upload your first photos</EmptyDescription>
      </EmptyHeader>
      <EmptyContent>
        <UploadPhotosButton collectionId={collectionId} onSuccess={onSuccess} />
      </EmptyContent>
    </Empty>
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

export const Route = createFileRoute('/_app/walks/$collectionId')({
  component: CollectionDetailPage,
});
