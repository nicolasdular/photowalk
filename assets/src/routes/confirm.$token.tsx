import { useMutation } from '@tanstack/react-query';
import { createFileRoute, Link } from '@tanstack/react-router';
import { client } from '@/api/client';
import { Button } from '@/components/ui/button';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import { Spinner } from '@/components/ui/spinner';

function MagicLinkConfirmation({ token }: { token: string }) {
  const mutation = useMutation({
    mutationFn: async () => {
      const { data, error } = await client.POST('/api/auth/verify', {
        body: { token },
      });

      if (error) {
        throw new Error(error.error || 'Failed to verify magic link');
      }

      return data;
    },
    onSuccess: () => {
      window.location.replace('/');
    },
  });

  return (
    <main className="flex min-h-dvh flex-col p-2">
      <div className="flex grow items-center justify-center p-6">
        <Card className="w-full max-w-sm">
          <CardHeader>
            <CardTitle>Confirm your sign-in</CardTitle>
            <CardDescription>
              {mutation.isPending && !mutation.isError
                ? 'Verifying your magic link...'
                : 'Click the button below to finish signing in.'}
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {mutation.isError ? (
              <>
                <div className="rounded-md bg-red-50 p-4">
                  <p className="text-sm text-red-800 ">
                    {mutation.error?.message}
                  </p>
                </div>
                <Link to="/signin">
                  <Button>Back to sign-in</Button>
                </Link>
              </>
            ) : (
              <div className="flex flex-col gap-2">
                <Button
                  className="w-full"
                  disabled={mutation.isPending}
                  onClick={() => {
                    mutation.mutate();
                  }}
                >
                  {mutation.isPending ? <Spinner /> : 'Confirm sign-in'}
                </Button>
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </main>
  );
}

function ConfirmRoute() {
  const { token } = Route.useParams();
  return <MagicLinkConfirmation token={token} />;
}

export const Route = createFileRoute('/confirm/$token')({
  component: ConfirmRoute,
});
