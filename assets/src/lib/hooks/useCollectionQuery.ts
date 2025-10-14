import { useQuery, useQueryClient } from '@tanstack/react-query';
import client from '@/api/client';
import type { components } from '@/api/schema';

type Collection = components['schemas']['CollectionShowResponse']['data'];

export function useCollectionQuery(collectionId: string) {
  return useQuery({
    queryKey: ['collection', collectionId],
    queryFn: async () => {
      const { data, error } = await client.GET('/api/collections/{id}', {
        params: { path: { id: collectionId } },
      });

      if (error) {
        throw error;
      }

      return data?.data as Collection | undefined;
    },
  });
}

export function usePrefetchCollection(collectionId: string) {
  const queryClient = useQueryClient();

  return () => {
    return queryClient.prefetchQuery({
      queryKey: ['collection', collectionId],
      queryFn: async () => {
        const { data, error } = await client.GET('/api/collections/{id}', {
          params: {
            path: { id: collectionId },
          },
        });

        if (error) {
          throw error;
        }

        return data?.data as Collection | undefined;
      },
    });
  };
}
