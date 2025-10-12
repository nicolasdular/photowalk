import { useQuery, useQueryClient } from '@tanstack/react-query';
import client from '@/api/client';
import type { components } from '@/api/schema';

type Collection = components['schemas']['CollectionShowResponse']['data'];

export function useCollectionQuery(collectionId: string | number) {
  const id =
    typeof collectionId === 'string' ? Number(collectionId) : collectionId;

  return useQuery({
    queryKey: ['collection', id],
    queryFn: async () => {
      const { data, error } = await client.GET('/api/collections/{id}', {
        params: { path: { id } },
      });

      if (error) {
        throw error;
      }

      return data?.data as Collection | undefined;
    },
  });
}

export function usePrefetchCollection(collectionId: string | number) {
  const queryClient = useQueryClient();

  return () =>
    queryClient.prefetchQuery({
      queryKey: ['collection', collectionId],
      queryFn: async () => {
        const { data, error } = await client.GET('/api/collections/{id}', {
          params: {
            path: {
              id:
                typeof collectionId === 'string'
                  ? Number(collectionId)
                  : collectionId,
            },
          },
        });

        if (error) {
          throw error;
        }

        return data?.data as Collection | undefined;
      },
    });
}
