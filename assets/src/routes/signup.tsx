import { createFileRoute } from '@tanstack/react-router';
import { type FormEvent, useMemo, useState } from 'react';
import { useMutation } from '@tanstack/react-query';
import { client } from '../api/client';
import { Button } from '@/components/ui/button';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import type { paths } from '@/api/schema';

type MagicLinkRequest = NonNullable<
  paths['/api/auth/request-magic-link']['post']['requestBody']
>['content']['application/json'];

function SignUp() {
  const [email, setEmail] = useState('');
  const { error: searchError } = Route.useSearch();

  const searchErrorMessage = useMemo(() => {
    if (!searchError) {
      return null;
    }

    if (searchError === 'invalid_token') {
      return 'The magic link is invalid or has expired. Request a new one.';
    }

    return 'Something went wrong. Please try again.';
  }, [searchError]);

  const mutation = useMutation({
    mutationFn: async (formData: MagicLinkRequest) => {
      const response = await client.POST('/api/auth/request-magic-link', {
        body: formData,
      });

      if (response.error) {
        throw new Error(response.error.error || 'Failed to send magic link');
      }

      return response.data;
    },
  });

  const errorMessage = searchErrorMessage ?? mutation.error?.message;

  const handleSubmit = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    mutation.mutate({ email });
  };

  if (mutation.isSuccess) {
    return (
      <main className="flex min-h-dvh flex-col p-2">
        <div className="flex grow items-center justify-center p-6">
          <Card className="w-full max-w-sm">
            <CardHeader>
              <CardTitle>Check your email</CardTitle>
              <CardDescription>
                If an account with that email exists, a magic link has been
                sent. Please check your inbox.
              </CardDescription>
            </CardHeader>
          </Card>
        </div>
      </main>
    );
  }

  return (
    <main className="flex min-h-dvh flex-col p-2">
      <div className="flex grow items-center justify-center p-6 flex-col gap-4">
        <Card className="w-full max-w-sm">
          <CardHeader>
            <CardTitle className="text-center">
              <h1 className="text-2xl font-bold">Photowalk</h1>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-4">
              {errorMessage && (
                <div className="rounded-md bg-red-50 p-4 dark:bg-red-900/10">
                  <p className="text-sm text-red-800 dark:text-red-200">
                    {errorMessage}
                  </p>
                </div>
              )}

              <div className="space-y-2">
                <Label htmlFor="email">Email</Label>
                <Input
                  id="email"
                  type="email"
                  name="email"
                  required
                  value={email}
                  onChange={e => setEmail(e.target.value)}
                  aria-invalid={errorMessage ? true : undefined}
                  aria-describedby={errorMessage ? 'email-error' : undefined}
                />
              </div>
              <Button
                type="submit"
                className="w-full"
                disabled={mutation.isPending}
              >
                {mutation.isPending ? 'Sending...' : 'Send Magic Link'}
              </Button>
            </form>
          </CardContent>
        </Card>
      </div>
    </main>
  );
}

export const Route = createFileRoute('/signup')({
  validateSearch: search => ({
    error: typeof search.error === 'string' ? search.error : undefined,
  }),
  component: SignUp,
});
