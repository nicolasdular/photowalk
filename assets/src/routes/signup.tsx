import { createFileRoute } from '@tanstack/react-router';
import { useMemo, useState } from 'react';
import { useMutation } from '@tanstack/react-query';
import { client } from '../api/client';
import { AuthLayout } from '@catalyst/auth-layout';
import { Heading } from '@catalyst/heading';
import { Label } from '@catalyst/fieldset';
import { Field } from '@catalyst/fieldset';
import { Input } from '@catalyst/input';
import { Button } from '@catalyst/button';

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
      <AuthLayout>
        <div className="grid w-full max-w-sm grid-cols-1 gap-8">
          <Heading>Check your email</Heading>
          <p className="text-sm text-gray-600 dark:text-gray-400">
            If an account with that email exists, a magic link has been sent.
            Please check your inbox.
          </p>
        </div>
      </AuthLayout>
    );
  }

  return (
    <AuthLayout>
      <form
        action="#"
        method="POST"
        className="grid w-full max-w-sm grid-cols-1 gap-8"
      >
        <Heading>Sign in via Email</Heading>

        {errorMessage && (
          <div className="rounded-md bg-red-50 p-4 dark:bg-red-900/10">
            <p className="text-sm text-red-800 dark:text-red-200">
              {errorMessage}
            </p>
          </div>
        )}

        <Field>
          <Label>Email</Label>
          <Input
            type="email"
            name="email"
            value={form.email}
            onChange={handleChange}
            aria-invalid={errorMessage ? true : undefined}
          />
        </Field>
        <Button
          type="submit"
          className="w-full"
          disabled={mutation.isPending}
          onClick={handleSubmit}
        >
          {mutation.isPending ? 'Sending...' : 'Send Magic Link'}
        </Button>
      </form>
    </AuthLayout>
  );
}

export const Route = createFileRoute('/signup')({
  validateSearch: search => ({
    error: typeof search.error === 'string' ? search.error : undefined,
  }),
  component: SignUp,
});
