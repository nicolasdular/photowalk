import { useMutation, useQueryClient } from '@tanstack/react-query';
import {
  createFileRoute,
  Link,
  Outlet,
  useMatches,
} from '@tanstack/react-router';
import type { components } from '../../../api/schema';
import { useState } from 'react';
import client from '../../../api/client';
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
import { useCollectionQuery } from '@/lib/hooks/useCollectionQuery';

type Collection = components['schemas']['Collection'];
type Photo = components['schemas']['Photo'];

function CollectionDetailPage() {
  const { collectionId } = Route.useParams();
  const queryClient = useQueryClient();
  const [deleteError, setDeleteError] = useState<string | null>(null);
  const [pendingPhotoId, setPendingPhotoId] = useState<number | null>(null);
  const matches = useMatches();

  const collectionQuery = useCollectionQuery(collectionId);

  const collection = collectionQuery.data;
  const photos = (collection?.photos as Photo[] | undefined) ?? [];
  const isLoading = collectionQuery.isLoading;

  const isViewingPhoto = matches.some(
    match => match.routeId === '/_app/walks/$collectionId/photos/$photoId'
  );

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
      queryClient.invalidateQueries({
        queryKey: ['collection', Number(collectionId)],
      });
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
      <>
        <PageTitle
          title={collection.title}
          backLink={
            <Link to="/" className="inline-flex items-center gap-2">
              <ArrowLeft className="h-4 w-4" />
              Back to walks
            </Link>
          }
        />
        <EmptyState
          collectionId={collection.id}
          onSuccess={refetchCollection}
        />
      </>
    );
  }

  if (isViewingPhoto) {
    return <Outlet />;
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
        subTitle={
          <div>
            <p>{collection.photos?.length} photos</p>
          </div>
        }
      />

      <section className="space-y-6">
        {deleteError && (
          <div className="rounded-lg border border-destructive/50 bg-destructive/10 px-4 py-3 text-sm text-destructive">
            {deleteError}
          </div>
        )}

        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 md:grid-cols-3">
          {photos.map(photo => (
            <Link
              key={photo.id}
              to="/walks/$collectionId/photos/$photoId"
              params={{
                collectionId: collectionId,
                photoId: String(photo.id),
              }}
              className="group relative flex flex-col overflow-hidden rounded-2xl "
            >
              <div className="relative aspect-[4/5] w-full overflow-hidden">
                <img
                  src={photo.thumbnail_url}
                  className="h-full w-full object-cover"
                  loading="lazy"
                />
              </div>
            </Link>
          ))}
        </div>
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

export const Route = createFileRoute('/_app/walks/$collectionId')({
  component: CollectionDetailPage,
});
