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

type Photo = NonNullable<
  components['schemas']['CollectionShowResponse']['data']['photos']
>[0];

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

  const isEditingCollection = matches.some(
    match => match.routeId === '/_app/walks/$collectionId/edit'
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
        queryKey: ['collection', collectionId],
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

  // Check for child routes first
  if (isViewingPhoto || isEditingCollection) {
    return <Outlet />;
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
          actions={
            <Link to="/walks/$collectionId/edit" params={{ collectionId }}>
              <Button variant="outline" size="sm">
                Edit
              </Button>
            </Link>
          }
        />
        <EmptyState collectionId={collectionId} onSuccess={refetchCollection} />
      </>
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
          <div className="flex items-center gap-4">
            <Link to="/walks/$collectionId/edit" params={{ collectionId }}>
              <Button variant="outline" size="sm">
                Edit
              </Button>
            </Link>
            <UploadPhotosButton
              collectionId={collection.id}
              onSuccess={refetchCollection}
            />
          </div>
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

        <div className="columns-1 gap-6 sm:columns-2 md:columns-2 lg:columns-3">
          {photos.map(photo => (
            <Link
              key={photo.id}
              to="/walks/$collectionId/photos/$photoId"
              params={{
                collectionId: collectionId,
                photoId: String(photo.id),
              }}
              className="group relative mb-6 inline-block w-full overflow-hidden rounded-2xl break-inside-avoid"
            >
              <img
                src={photo.thumbnail_url}
                className="w-full object-cover"
                loading="lazy"
              />
              <div className="pointer-events-none absolute inset-0 z-10 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
                <div
                  className="h-full w-full rounded-2xl"
                  style={{
                    background:
                      'linear-gradient(180deg,rgba(0,0,0,.1),transparent 20%,transparent 80%,rgba(0,0,0,.3)) ',
                  }}
                />
              </div>
              <div className="absolute inset-0 flex items-end z-20 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
                <div className="w-full px-4 py-2 text-white text-sm rounded-b-2xl relative">
                  <span className="relative z-10">{photo.user.name}</span>
                </div>
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
  collectionId: string;
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
