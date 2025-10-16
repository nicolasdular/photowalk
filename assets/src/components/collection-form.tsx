import type { FormEvent } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { Spinner } from '@/components/ui/spinner';

interface CollectionFormProps {
  title: string;
  description: string;
  onTitleChange: (value: string) => void;
  onDescriptionChange: (value: string) => void;
  onSubmit: (e: FormEvent) => void;
  onCancel: () => void;
  errors: Record<string, string[]>;
  isPending: boolean;
  submitLabel: string;
  submitPendingLabel: string;
}

export function CollectionForm({
  title,
  description,
  onTitleChange,
  onDescriptionChange,
  onSubmit,
  onCancel,
  errors,
  isPending,
  submitLabel,
  submitPendingLabel,
}: CollectionFormProps) {
  return (
    <form onSubmit={onSubmit} className="space-y-6">
      <div className="space-y-2">
        <Label htmlFor="title">Title</Label>
        <Input
          id="title"
          name="title"
          value={title}
          onChange={e => onTitleChange(e.target.value)}
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
          onChange={e => onDescriptionChange(e.target.value)}
          placeholder="Add a description to remember the context..."
          rows={8}
        />
        {errors.description && (
          <p className="text-sm text-destructive">{errors.description[0]}</p>
        )}
      </div>

      <div className="flex items-center gap-4 pt-4">
        <Button type="submit" disabled={isPending || !title.trim()}>
          {isPending && <Spinner className="mr-2" />}
          {isPending ? submitPendingLabel : submitLabel}
        </Button>
        <Button type="button" variant="ghost" onClick={onCancel}>
          Cancel
        </Button>
      </div>
    </form>
  );
}
