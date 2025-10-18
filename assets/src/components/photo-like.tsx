import { useMutation, useQueryClient } from '@tanstack/react-query';
import { components } from '@/api/schema';
import client from '@/api/client';
import { Button } from '@/components/ui/button';
import { Heart } from 'lucide-react';
import { cn } from '@/lib/utils';

type PhotoLike = components['schemas']['PhotoLike'];

interface PhotoLikeButtonProps {
  likes: PhotoLike;
  photoId: string;
  onOptimisticUpdate?: (liked: boolean, count: number) => void;
}

export function PhotoLikeButton({ likes, photoId, onOptimisticUpdate }: PhotoLikeButtonProps) {
  const queryClient = useQueryClient();

  const likeMutation = useMutation({
    mutationFn: async () => {
      const { error } = await client.POST('/api/photos/{id}/like', {
        params: { path: { id: photoId } },
      });

      if (error) {
        throw error;
      }
    },
    onMutate: () => {
      if (onOptimisticUpdate) {
        onOptimisticUpdate(true, likes.count + 1);
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ['collection'],
      });
      queryClient.invalidateQueries({
        queryKey: ['photos'],
      });
    },
    onError: () => {
      // Revert optimistic update on error
      if (onOptimisticUpdate) {
        onOptimisticUpdate(false, likes.count);
      }
    },
  });

  const unlikeMutation = useMutation({
    mutationFn: async () => {
      const { error } = await client.POST('/api/photos/{id}/unlike', {
        params: { path: { id: photoId } },
      });

      if (error) {
        throw error;
      }
    },
    onMutate: () => {
      if (onOptimisticUpdate) {
        onOptimisticUpdate(false, likes.count - 1);
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ['collection'],
      });
      queryClient.invalidateQueries({
        queryKey: ['photos'],
      });
    },
    onError: () => {
      // Revert optimistic update on error
      if (onOptimisticUpdate) {
        onOptimisticUpdate(true, likes.count);
      }
    },
  });

  const handleToggleLike = e => {
    e.preventDefault();
    if (likes.current_user_liked) {
      unlikeMutation.mutate();
    } else {
      likeMutation.mutate();
    }
  };

  const isLoading = likeMutation.isPending || unlikeMutation.isPending;

  return (
    <div className="flex items-center gap-2">
      <Button
        variant="link"
        size="icon-sm"
        onClick={handleToggleLike}
        disabled={isLoading}
        className={cn('transition-colors', likes.current_user_liked && 'text-red-500 hover:text-red-600')}
      >
        {likes.current_user_liked ? (
          <Heart className="size-5 fill-current" />
        ) : (
          <Heart className="size-5 stroke-white" />
        )}
      </Button>
      <span className="text-sm text-white min-w-[1ch] text-center">{likes.count}</span>
    </div>
  );
}
