import { useState, type FormEvent } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import client from '../api/client';
import type { components } from '../api/schema';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Spinner } from '@/components/ui/spinner';
import { Avatar, AvatarImage } from '@/components/ui/avatar';
import { UserPlus } from 'lucide-react';

type User = components['schemas']['User'];

interface CollectionUsersProps {
  collectionId: string;
}

export function CollectionUsers({ collectionId }: CollectionUsersProps) {
  const queryClient = useQueryClient();
  const [email, setEmail] = useState('');
  const [error, setError] = useState<string | null>(null);

  const usersQuery = useQuery({
    queryKey: ['collection-users', collectionId],
    queryFn: async () => {
      const { data, error } = await client.GET(
        '/api/collections/{id}/users' as any,
        {
          params: { path: { id: collectionId } } as any,
        }
      );

      if (error) {
        throw error;
      }

      return data?.data ?? [];
    },
  });

  const addUserMutation = useMutation({
    mutationFn: async (userEmail: string) => {
      const { data, error } = await client.POST(
        '/api/collections/{id}/users' as any,
        {
          params: { path: { id: collectionId } } as any,
          body: { email: userEmail },
        }
      );

      if (error) {
        if ('errors' in error && error.errors) {
          const errors = error.errors as Record<string, string[]>;
          const firstError = Object.values(errors)[0]?.[0];
          throw new Error(firstError || 'Failed to add user');
        }
        throw new Error('Failed to add user');
      }

      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ['collection-users', collectionId],
      });
      setEmail('');
      setError(null);
    },
    onError: (err: Error) => {
      setError(err.message);
    },
  });

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    setError(null);
    if (email.trim()) {
      addUserMutation.mutate(email.trim());
    }
  };

  const users = usersQuery.data ?? [];

  return (
    <div className="space-y-6">
      <div>
        <h3 className="text-lg font-semibold mb-1">Members</h3>
        <p className="text-sm text-muted-foreground">
          Add people to collaborate on this walk.
        </p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="space-y-2">
          <Label htmlFor="user-email">Add member by email</Label>
          <div className="flex gap-2">
            <Input
              id="user-email"
              type="email"
              value={email}
              onChange={e => setEmail(e.target.value)}
              placeholder="email@example.com"
              className="flex-1"
              aria-invalid={!!error}
            />
            <Button
              type="submit"
              disabled={addUserMutation.isPending || !email.trim()}
              size="icon"
            >
              {addUserMutation.isPending ? (
                <Spinner className="h-4 w-4" />
              ) : (
                <UserPlus className="h-4 w-4" />
              )}
            </Button>
          </div>
          {error && <p className="text-sm text-destructive">{error}</p>}
        </div>
      </form>

      <div className="space-y-3">
        {usersQuery.isLoading ? (
          <div className="flex items-center justify-center py-8">
            <Spinner className="h-6 w-6" />
          </div>
        ) : users.length === 0 ? (
          <p className="text-sm text-muted-foreground py-4">
            No members yet. Add someone to start collaborating.
          </p>
        ) : (
          <div className="space-y-2">
            {users.map(user => (
              <div
                key={user.id}
                className="flex items-center justify-between p-3 rounded-lg border bg-card"
              >
                <div className="flex items-center gap-3">
                  <Avatar>
                    <AvatarImage src={user.avatar_url} alt={user.name} />
                  </Avatar>
                  <div>
                    <p className="text-sm font-medium">{user.name}</p>
                    <p className="text-xs text-muted-foreground">
                      {user.email}
                    </p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
