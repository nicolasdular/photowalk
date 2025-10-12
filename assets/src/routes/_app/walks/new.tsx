import { useState } from 'react';
import type { FormEvent } from 'react';
import { useMutation } from '@tanstack/react-query';
import { createFileRoute, useNavigate } from '@tanstack/react-router';
import client from '../../../api/client';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { Spinner } from '@/components/ui/spinner';
import { PageTitle } from '@/components/ui/page-title';

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

      <form onSubmit={handleSubmit} className="space-y-6">
        <div className="space-y-2">
          <Label htmlFor="title">Title</Label>
          <Input
            id="title"
            name="title"
            value={title}
            onChange={e => setTitle(e.target.value)}
            placeholder="e.g., Autumn Prater Walk"
            aria-invalid={!!errors.title}
          />
          {errors.title && (
            <p className="text-sm text-destructive">{errors.title[0]}</p>
          )}
        </div>

        <div className="space-y-2">
          <Label htmlFor="description">Description (optional)</Label>
          <Textarea
            id="description"
            name="description"
            value={description}
            onChange={e => setDescription(e.target.value)}
            placeholder="Add a description to remember the context..."
            rows={8}
          />
          {errors.description && (
            <p className="text-sm text-destructive">{errors.description[0]}</p>
          )}
        </div>

        <div className="flex items-center gap-4 pt-4">
          <Button
            type="submit"
            disabled={createMutation.isPending || !title.trim()}
          >
            {createMutation.isPending && <Spinner className="mr-2" />}
            {createMutation.isPending ? 'Creating...' : 'Create Collection'}
          </Button>
          <Button
            type="button"
            variant="ghost"
            onClick={() => navigate({ to: '/' })}
          >
            Cancel
          </Button>
        </div>
      </form>
    </div>
  );
}

export const Route = createFileRoute('/_app/walks/new')({
  component: NewCollectionPage,
});
