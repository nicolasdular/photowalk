import { createFileRoute, Link } from '@tanstack/react-router';
import { type FormEvent, useMemo, useState } from 'react';
import { useMutation } from '@tanstack/react-query';
import { client } from '../api/client';
import { Button } from '@/components/ui/button';
import {
  Card,
  CardAction,
  CardContent,
  CardDescription,
  CardFooter,
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
            <CardTitle>Photowalk Sign in</CardTitle>
            <CardDescription>
              Enter your email below to login to your account
            </CardDescription>
            <CardAction>
              <Link to="/signup">
                <Button variant="link">Sign Up</Button>
              </Link>
            </CardAction>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-4">
              {errorMessage && (
                <div className="rounded-md bg-red-50 p-4">
                  <p className="text-sm text-red-800 ">{errorMessage}</p>
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
                {mutation.isPending ? 'Sending...' : 'Sign in via Email'}
              </Button>
            </form>
          </CardContent>
        </Card>
      </div>
    </main>
  );
}

export function CardDemo() {
  return (
    <Card className="w-full max-w-sm">
      <CardHeader>
        <CardTitle>Login to your account</CardTitle>
        <CardDescription>
          Enter your email below to login to your account
        </CardDescription>
        <CardAction>
          <Button variant="link">Sign Up</Button>
        </CardAction>
      </CardHeader>
      <CardContent>
        <form>
          <div className="flex flex-col gap-6">
            <div className="grid gap-2">
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                placeholder="m@example.com"
                required
              />
            </div>
            <div className="grid gap-2">
              <div className="flex items-center">
                <Label htmlFor="password">Password</Label>
                <a
                  href="#"
                  className="ml-auto inline-block text-sm underline-offset-4 hover:underline"
                >
                  Forgot your password?
                </a>
              </div>
              <Input id="password" type="password" required />
            </div>
          </div>
        </form>
      </CardContent>
      <CardFooter className="flex-col gap-2">
        <Button type="submit" className="w-full">
          Login
        </Button>
        <Button variant="outline" className="w-full">
          Login with Google
        </Button>
      </CardFooter>
    </Card>
  );
}

export const Route = createFileRoute('/signin')({
  validateSearch: search =>
    ({
      error: typeof search.error === 'string' ? search.error : undefined,
    }) as { error?: string },
  component: SignUp,
});
