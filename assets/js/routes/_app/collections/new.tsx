import { useState } from 'react';
import type { FormEvent } from 'react';
import { useMutation } from '@tanstack/react-query';
import { createFileRoute, useNavigate } from '@tanstack/react-router';
import client from '../../../api/client';
import { Button } from '../../../catalyst/button';
import { Heading } from '../../../catalyst/heading';
import { Text } from '../../../catalyst/text';
import { Input } from '../../../catalyst/input';
import { Textarea } from '../../../catalyst/textarea';
import { Field, Label } from '../../../catalyst/fieldset';

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
          to: '/collections/$collectionId',
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
    <div className="min-h-[calc(100vh-4rem)] bg-gradient-to-br from-slate-50 via-white to-sky-50 pb-24 pt-16 text-slate-900">
      <div className="mx-auto w-full max-w-2xl space-y-10 px-6 sm:px-10">
        <header className="space-y-4">
          <span className="inline-flex items-center gap-2 rounded-full bg-sky-100 px-4 py-1 text-xs font-semibold uppercase tracking-[0.28em] text-sky-700 shadow-sm shadow-sky-200">
            New Collection
          </span>
          <div className="space-y-3">
            <Heading
              level={1}
              className="text-4xl font-semibold tracking-tight text-slate-900 sm:text-5xl"
            >
              Create a new collection
            </Heading>
            <Text className="max-w-2xl text-base leading-relaxed text-slate-600">
              Give your collection a name and description to help organize your
              photos.
            </Text>
          </div>
        </header>

        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="rounded-3xl border border-slate-200 bg-white/90 p-8 shadow-xl shadow-slate-200/70 backdrop-blur-sm transition hover:shadow-2xl">
            <Field>
              <Label>Title</Label>
              <Input
                name="title"
                value={title}
                onChange={e => setTitle(e.target.value)}
                placeholder="e.g., Summer Vacation 2024"
                invalid={!!errors.title}
              />
              {errors.title && (
                <Text className="mt-1 text-sm text-rose-500">
                  {errors.title[0]}
                </Text>
              )}
            </Field>

            <Field>
              <Label>Description (optional)</Label>
              <Textarea
                name="description"
                value={description}
                onChange={e => setDescription(e.target.value)}
                placeholder="Add a description to remember the context..."
                rows={4}
              />
              {errors.description && (
                <Text className="mt-1 text-sm text-rose-500">
                  {errors.description[0]}
                </Text>
              )}
            </Field>
          </div>

          <div className="flex items-center gap-4">
            <Button
              type="submit"
              color="sky"
              disabled={createMutation.isPending || !title.trim()}
            >
              {createMutation.isPending ? 'Creating...' : 'Create Collection'}
            </Button>
            <Button
              type="button"
              plain
              className="text-slate-500 hover:text-slate-700"
              onClick={() => navigate({ to: '/' })}
            >
              Cancel
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}

export const Route = createFileRoute('/_app/collections/new')({
  component: NewCollectionPage,
});
