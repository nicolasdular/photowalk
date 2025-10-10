import { useCallback, useRef, useState } from 'react';
import type { ChangeEvent, DragEvent, RefObject } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { getCsrfToken } from '../api/client';
import type { components } from '../api/schema';

type Photo = components['schemas']['Photo'];
type PhotoListResponse = components['schemas']['PhotoListResponse'];
type UploadResponse = PhotoListResponse;

interface PhotoUploadProps {
  collectionId?: number;
  queryKey?: unknown[];
}

export function PhotoUpload({
  collectionId,
  queryKey = ['photos'],
}: PhotoUploadProps) {
  const queryClient = useQueryClient();
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const [isDropping, setIsDropping] = useState(false);
  const [localError, setLocalError] = useState<string | null>(null);

  const uploadMutation = useMutation({
    mutationFn: async (file: File) => {
      if (!file) return [] as Photo[];

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
          details?.errors?.collection_id?.[0] ||
          'We could not upload your photo. Please ensure the image is smaller than 30MB.';
        throw new Error(message);
      }

      const payload = (await response.json()) as UploadResponse;
      if (payload.data && Array.isArray(payload.data)) {
        return payload.data;
      }

      return [] as Photo[];
    },
    onSuccess: () => {
      setLocalError(null);
      queryClient.invalidateQueries({ queryKey });
    },
  });

  const { mutateAsync } = uploadMutation;

  const handleFiles = useCallback(
    (fileList: FileList | null) => {
      setLocalError(null);
      if (!fileList || !fileList.length) return;

      const images = Array.from(fileList).filter(file =>
        file.type.startsWith('image/')
      );

      if (!images.length) {
        setLocalError('Only image files can be uploaded.');
        return;
      }

      void (async () => {
        for (const image of images) {
          try {
            await mutateAsync(image);
          } catch (error) {
            if (error instanceof Error) {
              setLocalError(error.message);
            }
            break;
          }
        }
      })();
    },
    [mutateAsync]
  );

  const onDrop = useCallback(
    (event: DragEvent<HTMLDivElement>) => {
      event.preventDefault();
      setIsDropping(false);
      handleFiles(event.dataTransfer.files);
    },
    [handleFiles]
  );

  const onDragOver = useCallback((event: DragEvent<HTMLDivElement>) => {
    event.preventDefault();
    setIsDropping(true);
  }, []);

  const onDragLeave = useCallback(() => {
    setIsDropping(false);
  }, []);

  const mutationError =
    uploadMutation.error instanceof Error ? uploadMutation.error.message : '';

  return (
    <div>
      <div
        onClick={() => fileInputRef.current?.click()}
        onDrop={onDrop}
        onDragOver={onDragOver}
        onDragLeave={onDragLeave}
        className={[
          'relative flex cursor-pointer flex-col items-center justify-center gap-6 rounded-3xl border-2 border-dashed p-10 transition-all duration-200 ease-out',
          isDropping
            ? 'border-sky-300 bg-sky-50 shadow-[0_35px_90px_-40px_rgba(56,189,248,0.6)]'
            : 'border-slate-200 bg-white/95 shadow-xl shadow-slate-200/70 hover:border-slate-300 hover:bg-white',
        ].join(' ')}
      >
        <div className="flex h-16 w-16 items-center justify-center rounded-full bg-sky-100 text-sky-600 shadow-inner shadow-sky-200/80">
          <span className="text-2xl">⟳</span>
        </div>
        <div className="text-center">
          <p className="text-lg font-semibold text-slate-900">
            {uploadMutation.isPending
              ? 'Uploading your photos…'
              : 'Drop photos or click to browse'}
          </p>
          <p className="mt-2 text-sm text-slate-600">
            We instantly craft a gallery-ready set with large and thumbnail
            variants optimized for blazing-fast previews.
          </p>
        </div>
        <div className="flex flex-wrap items-center justify-center gap-2 text-xs font-medium text-slate-600">
          <span className="rounded-full bg-slate-100 px-3 py-1">
            Guided sequential uploads
          </span>
          <span className="rounded-full bg-slate-100 px-3 py-1">
            Intelligent resizing
          </span>
          <span className="rounded-full bg-slate-100 px-3 py-1">
            Lossless color handling
          </span>
        </div>
        <input
          ref={fileInputRef}
          type="file"
          accept="image/*"
          multiple
          className="hidden"
          onChange={event => handleFiles(event.target.files)}
        />
        <div className="pointer-events-none absolute inset-0 rounded-3xl border border-slate-100">
          <div className="absolute inset-0 rounded-3xl bg-gradient-to-tr from-sky-100/40 via-transparent to-transparent" />
        </div>
      </div>
      {localError || (uploadMutation.isError && mutationError) ? (
        <p className="mt-3 text-sm text-rose-500">
          {localError || mutationError}
        </p>
      ) : null}
    </div>
  );
}
