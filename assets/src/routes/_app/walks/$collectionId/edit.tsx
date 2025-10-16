import { useState, useEffect } from 'react';
import type { FormEvent } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { createFileRoute, useNavigate, Link } from '@tanstack/react-router';
import client from '../../../../api/client';
import { PageTitle } from '@/components/ui/page-title';
import { CollectionForm } from '@/components/collection-form';
import { CollectionUsers } from '@/components/collection-users';
import { useCollectionQuery } from '@/lib/hooks/useCollectionQuery';
import { PageLoading } from '@/components/ui/page-loading';
import { ArrowLeft } from 'lucide-react';

function EditCollectionPage() {
  const { collectionId } = Route.useParams();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [errors, setErrors] = useState<Record<string, string[]>>({});

  const collectionQuery = useCollectionQuery(collectionId);
  const collection = collectionQuery.data;

  useEffect(() => {
    if (collection) {
      setTitle(collection.title || '');
      setDescription(collection.description || '');
    }
  }, [collection]);

  const updateMutation = useMutation({
    mutationFn: async () => {
      const { data, error } = await client.PATCH('/api/collections/{id}', {
        params: { path: { id: collectionId } },
        body: {
          title,
          description: description || undefined,
        },
      });

      if (error) {
        if ('errors' in error && error.errors) {
          setErrors(error.errors as Record<string, string[]>);
        }
        throw error;
      }

      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ['collection', collectionId],
      });
      navigate({
        to: '/walks/$collectionId',
        params: { collectionId },
      });
    },
  });

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    setErrors({});
    updateMutation.mutate();
  };

  if (collectionQuery.isLoading) {
    return <PageLoading title={<span>Loading walk...</span>} />;
  }

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

  return (
    <div className="container mx-auto max-w-2xl py-8 px-4">
      <header className="space-y-6 mb-12">
        <div className="space-y-2">
          <PageTitle
            title={`Edit ${collection.title}`}
            backLink={
              <Link
                to="/walks/$collectionId"
                params={{ collectionId }}
                className="inline-flex items-center gap-2"
              >
                <ArrowLeft className="h-4 w-4" />
                Back to walk
              </Link>
            }
          />
          <p className="text-muted-foreground">
            Update your walk's name and description.
          </p>
        </div>
      </header>

      <CollectionForm
        title={title}
        description={description}
        onTitleChange={setTitle}
        onDescriptionChange={setDescription}
        onSubmit={handleSubmit}
        onCancel={() =>
          navigate({
            to: '/walks/$collectionId',
            params: { collectionId },
          })
        }
        errors={errors}
        isPending={updateMutation.isPending}
        submitLabel="Update Collection"
        submitPendingLabel="Updating..."
      />

      <div className="mt-12 pt-12 border-t">
        <CollectionUsers collectionId={collectionId} />
      </div>
    </div>
  );
}

export const Route = createFileRoute('/_app/walks/$collectionId/edit')({
  component: EditCollectionPage,
});
