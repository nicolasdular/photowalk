import { useState } from 'react';
import type { FormEvent } from 'react';
import { useMutation } from '@tanstack/react-query';
import { createFileRoute, useNavigate } from '@tanstack/react-router';
import client from '../../../api/client';
import { PageTitle } from '@/components/ui/page-title';
import { CollectionForm } from '@/components/collection-form';

function NewCollectionPage() {
  const navigate = useNavigate();
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [errors, setErrors] = useState<Record<string, string[]>>({});

  const createMutation = useMutation({
    mutationFn: async () => {
      const { data, error } = await client.POST('/api/collections', {
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
    onSuccess: data => {
      if (data?.data?.id) {
        navigate({
          to: '/walks/$collectionId',
          params: { collectionId: data.data.id.toString() },
        });
      }
    },
  });

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    setErrors({});
    createMutation.mutate();
  };

  return (
    <div className="container mx-auto max-w-2xl py-8 px-4">
      <header className="space-y-6 mb-12">
        <div className="space-y-2">
          <PageTitle title="New Walk" />
          <p className="text-muted-foreground">
            Give your walk a name and description.
          </p>
        </div>
      </header>

      <CollectionForm
        title={title}
        description={description}
        onTitleChange={setTitle}
        onDescriptionChange={setDescription}
        onSubmit={handleSubmit}
        onCancel={() => navigate({ to: '/' })}
        errors={errors}
        isPending={createMutation.isPending}
        submitLabel="Create Collection"
        submitPendingLabel="Creating..."
      />
    </div>
  );
}

export const Route = createFileRoute('/_app/walks/new')({
  component: NewCollectionPage,
});
