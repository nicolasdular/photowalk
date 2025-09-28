import { useState } from 'react';
import { useMutation } from '@tanstack/react-query';
import { requestMagicLink } from '../ash_rpc';
import { ErrorSummary, FieldErrors } from '../components/FormErrors';
import { hasFieldError } from '../utils/rpcErrors';
import { AuthLayout } from '@catalyst/auth-layout';
import { Heading } from '@catalyst/heading';
import { Label } from '@catalyst/fieldset';
import { Field } from '@catalyst/fieldset';
import { Input } from '@catalyst/input';
import { Button } from '@catalyst/button';

export function SignUp() {
  const [form, setForm] = useState({ email: '' });

  const mutation = useMutation({
    mutationFn: async (email: string) => {
      return await requestMagicLink({ input: { email } });
    },
  });

  const handleChange = e => {
    const target = e.target as HTMLInputElement;
    setForm({ email: target.value });
  };

  const handleSubmit = e => {
    e.preventDefault();
    mutation.mutate(form.email);
  };

  if (mutation.isSuccess && mutation.data?.success) {
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
        <ErrorSummary
          errors={
            mutation.data?.success === false
              ? (mutation.data as any).errors
              : undefined
          }
        />

        <Field>
          <Label>Email</Label>
          <Input
            type="email"
            name="email"
            onChange={handleChange}
            aria-invalid={
              mutation.data?.success === false &&
              hasFieldError((mutation.data as any)?.errors, 'email')
                ? true
                : undefined
            }
          />
          <FieldErrors
            name="email"
            errors={
              mutation.data?.success === false
                ? (mutation.data as any).errors
                : undefined
            }
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
