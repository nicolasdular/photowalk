import { useQuery } from '@tanstack/react-query';
import { createFileRoute, Link } from '@tanstack/react-router';
import client from '../../api/client';
import type { components } from '../../api/schema';
import { Button } from '@/components/ui/button';
import { PageTitle } from '@/components/ui/page-title';
import { Spinner } from '@/components/ui/spinner';
import { Plus, CameraIcon } from 'lucide-react';
import {
  Empty,
  EmptyContent,
  EmptyDescription,
  EmptyHeader,
  EmptyMedia,
  EmptyTitle,
} from '@/components/ui/empty';
import { PageLoading } from '@/components/ui/page-loading';

type Collection = components['schemas']['CollectionListResponse']['data'][0];

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

  if (isEmpty) {
    return <EmptyState />;
  }

  if (collectionsQuery.isLoading) {
    return <PageLoading title={<span>Loading walks...</span>} />;
  }

  return (
    <>
      <PageTitle actions={<NewWalkButton />} title={'Walks'} />
      <CollectionsGrid collections={collections} />
    </>
  );
}

function EmptyState() {
  return (
    <Empty>
      <EmptyHeader>
        <EmptyMedia variant="icon">
          <CameraIcon />
        </EmptyMedia>
        <EmptyTitle>No walks yet</EmptyTitle>
        <EmptyDescription>
          Create your first walk to get started!
        </EmptyDescription>
      </EmptyHeader>
      <EmptyContent>
        <NewWalkButton />
      </EmptyContent>
    </Empty>
  );
}

function NewWalkButton() {
  return (
    <Link to="/walks/new">
      <Button>
        <Plus className="w-5 h-5" /> New Walk
      </Button>
    </Link>
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
          to="/walks/$collectionId"
          params={{ collectionId: collection.id?.toString() ?? '' }}
          className="group"
        >
          <div className="overflow-hidden rounded-lg">
            {collection.thumbnails?.length === 0 ? (
              <>
                <div className="h-120 w-100 bg-muted flex items-center justify-center rounded-lg">
                  <span className="text-muted-foreground">No Photos yet</span>
                </div>
                <div className="text-sm font-medium text-slate-900 mt-2">
                  {collection.title}
                </div>
              </>
            ) : (
              <>
                <img
                  src={collection.thumbnails?.[0]?.full_url}
                  alt={collection.title}
                  className="h-120 w-100 object-cover rounded-xl"
                />
                <div className="text-sm font-medium text-slate-900 mt-2">
                  {collection.title}
                </div>
              </>
            )}
          </div>
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
