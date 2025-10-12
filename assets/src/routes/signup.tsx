import { createFileRoute } from '@tanstack/react-router';
import { useMemo, useState } from 'react';
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

function SignUp() {
  const [form, setForm] = useState({ email: '' });
  const [generalError, setGeneralError] = useState<string | null>(null);
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

  const errorMessage = generalError ?? searchErrorMessage;

  const mutation = useMutation({
    mutationFn: async (email: string) => {
      const response = await client.POST('/api/auth/request-magic-link', {
        body: { email },
      });

      if (response.error) {
        throw new Error(response.error.error || 'Failed to send magic link');
      }

      return response.data;
    },
    onError: (error: Error) => {
      setGeneralError(error.message);
    },
    onSuccess: () => {
      setGeneralError(null);
    },
  });

  const handleChange = e => {
    const target = e.target as HTMLInputElement;
    setForm({ email: target.value });
    setGeneralError(null);
  };

  const handleSubmit = e => {
    e.preventDefault();
    mutation.mutate(form.email);
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
      <div className="flex grow items-center justify-center p-6">
        <Card className="w-full max-w-sm">
          <CardHeader>
            <CardTitle>Sign in via Email</CardTitle>
          </CardHeader>
          <CardContent>
            <form action="#" method="POST" className="space-y-4">
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
                  value={form.email}
                  onChange={handleChange}
                  aria-invalid={errorMessage ? true : undefined}
                />
              </div>
              <Button
                type="submit"
                className="w-full"
                disabled={mutation.isPending}
                onClick={handleSubmit}
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
