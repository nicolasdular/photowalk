import { useRef, useState } from 'react';
import type { ChangeEvent } from 'react';
import { useMutation } from '@tanstack/react-query';
import { Button } from '@/components/ui/button';
import { Spinner } from '@/components/ui/spinner';
import { Plus } from 'lucide-react';
import { getCsrfToken } from '../api/client';
import type { components, paths } from '../api/schema';

type Photo = components['schemas']['Photo'];

// Extract response type from OpenAPI schema
type PhotoUploadResponse =
  paths['/api/photos']['post']['responses']['201']['content']['application/json'];

// Extract request body type from OpenAPI schema
type PhotoUploadRequest =
  paths['/api/photos']['post']['requestBody']['content']['multipart/form-data'];

interface UploadPhotosButtonProps {
  collectionId?: string;
  onSuccess?: (photos: Photo[]) => void;
  variant?: 'default' | 'outline' | 'ghost' | 'secondary';
  size?: 'default' | 'sm' | 'lg' | 'icon';
  className?: string;
}

export function UploadPhotosButton({
  collectionId,
  onSuccess,
  variant = 'default',
  size = 'default',
  className,
}: UploadPhotosButtonProps) {
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const [error, setError] = useState<string | null>(null);

  const uploadMutation = useMutation({
    mutationFn: async (file: File) => {
      // Note: We use raw fetch instead of the OpenAPI client because
      // openapi-fetch doesn't handle multipart/form-data well.
      // We still use the OpenAPI types for type safety.

      const csrf = getCsrfToken();
      const headers = new Headers();
      if (csrf) {
        headers.set('x-csrf-token', csrf);
      }
      headers.set('accept', 'application/json');

      const formData = new FormData();
      formData.append('photo', file);
      if (collectionId) {
        formData.append('collection_id', collectionId.toString());
      }

      const response = await fetch('/api/photos', {
        method: 'POST',
        body: formData,
        headers,
        credentials: 'same-origin',
      });

      if (!response.ok) {
        const details = await response.json().catch(() => ({}));
        const message =
          details?.errors?.photo?.[0] ||
          'We could not upload your photo. Please ensure the image is smaller than 30MB.';
        throw new Error(message);
      }

      const payload = (await response.json()) as PhotoUploadResponse;
      if (payload.data && Array.isArray(payload.data)) {
        return payload.data;
      }

      return [] as Photo[];
    },
    onSuccess: photos => {
      setError(null);
      if (onSuccess && photos.length > 0) {
        onSuccess(photos);
      }
    },
    onError: (err: Error) => {
      setError(err.message);
    },
  });

  const handleFileChange = async (event: ChangeEvent<HTMLInputElement>) => {
    setError(null);
    const fileList = event.target.files;
    if (!fileList || !fileList.length) return;

    const allFiles: File[] = Array.from(fileList);
    const images = allFiles.filter(file => file.type.startsWith('image/'));

    if (!images.length) {
      setError('Only image files can be uploaded.');
      return;
    }

    // Upload files sequentially
    for (const image of images) {
      try {
        await uploadMutation.mutateAsync(image);
      } catch (err) {
        // Error is already handled in onError
        break;
      }
    }

    // Reset input so the same file can be selected again
    event.target.value = '';
  };

  const handleClick = () => {
    fileInputRef.current?.click();
  };

  return (
    <>
      <Button
        type="button"
        variant={variant}
        size={size}
        className={className}
        onClick={handleClick}
        disabled={uploadMutation.isPending}
      >
        {uploadMutation.isPending ? (
          <>
            <Spinner className="mr-2" />
            Uploading...
          </>
        ) : (
          <>
            <Plus className="mr-2 h-4 w-4" />
            Upload Photos
          </>
        )}
      </Button>

      <input
        ref={fileInputRef}
        type="file"
        accept="image/*"
        multiple
        className="hidden"
        onChange={handleFileChange}
      />

      {error && <p className="text-sm text-destructive mt-2">{error}</p>}
    </>
  );
}
