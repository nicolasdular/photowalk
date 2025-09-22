import { useState } from 'preact/hooks';
import { useMutation } from '@tanstack/react-query';
import { requestMagicLink } from '../ash_rpc';

export function SignUp() {
  const [form, setForm] = useState({ email: '' });

  const mutation = useMutation({
    mutationFn: async (email: string) => {
      return await requestMagicLink({ input: { email } });
    },
  });

  const handleChange = (e: Event) => {
    const target = e.target as HTMLInputElement;
    setForm({ email: target.value });
  };

  const handleSubmit = (e: Event) => {
    e.preventDefault();
    mutation.mutate(form.email);
  };

  return (
    <div class="flex min-h-screen items-center justify-center bg-gray-50">
      <form
        onSubmit={handleSubmit}
        class="bg-white shadow-lg rounded-xl p-8 w-full max-w-md space-y-6"
        id="magic-link-form"
      >
        <h2 class="text-2xl font-bold text-gray-900 mb-2">
          Sign up with Magic Link
        </h2>
        <div>
          <label
            htmlFor="email"
            class="block text-sm font-medium text-gray-700 mb-1"
          >
            Email address
          </label>
          <input
            id="email"
            type="email"
            required
            value={form.email}
            onInput={handleChange}
            class="block w-full px-4 py-2 rounded-lg border border-gray-300 focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
            placeholder="you@example.com"
          />
        </div>
        <button
          type="submit"
          disabled={mutation.isLoading}
          class={[
            'w-full py-2 px-4 rounded-lg font-semibold transition',
            mutation.isLoading
              ? 'bg-blue-300 cursor-not-allowed'
              : 'bg-blue-600 hover:bg-blue-700 text-white',
          ].join(' ')}
        >
          {mutation.isLoading ? 'Sending...' : 'Send Magic Link'}
        </button>
        {mutation.data?.success === false ? (
          <div class="text-red-600 text-sm mt-2">
            {mutation.data.errors.map(message => {
              return <div>{message.message}</div>;
            }) || 'Something went wrong.'}
          </div>
        ) : null}

        {mutation.data?.success && (
          <div class="text-green-600 text-sm mt-2">
            Magic link sent! Check your inbox.
          </div>
        )}
      </form>
    </div>
  );
}
