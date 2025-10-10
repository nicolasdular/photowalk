import { useCallback, useMemo, useRef, useState } from 'react';
import type { ChangeEvent, DragEvent, RefObject } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { createFileRoute } from '@tanstack/react-router';
import client, { getCsrfToken } from '../../api/client';
import type { components } from '../../api/schema';

const queryKey = ['photos'];

type Photo = components['schemas']['Photo'];

type PhotoListResponse = components['schemas']['PhotoListResponse'];

type UploadResponse = PhotoListResponse;

function PhotosDashboard() {
  const queryClient = useQueryClient();
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const [isDropping, setIsDropping] = useState(false);
  const [localError, setLocalError] = useState<string | null>(null);

  const photosQuery = useQuery({
    queryKey,
    queryFn: async () => {
      const { data, error } = await client.GET('/api/photos');
      if (error) {
        throw error;
      }
      return data?.data ?? [];
    },
  });

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

  const photos = photosQuery.data ?? [];
  const isEmpty = !photos.length && !photosQuery.isLoading;
  const mutationError =
    uploadMutation.error instanceof Error ? uploadMutation.error.message : '';

  return (
    <div className="min-h-[calc(100vh-4rem)] bg-gradient-to-br from-slate-50 via-white to-sky-50 pb-24 pt-16 text-slate-900">
      <div className="mx-auto flex w-full max-w-6xl flex-col gap-12 px-6 sm:px-10 xl:flex-row">
        <section className="flex-1 space-y-10">
          <header className="space-y-4">
            <span className="inline-flex items-center gap-2 rounded-full bg-sky-100 px-4 py-1 text-xs font-semibold uppercase tracking-[0.28em] text-sky-700 shadow-sm shadow-sky-200">
              Your library
            </span>
            <div className="space-y-3">
              <h1 className="text-4xl font-semibold tracking-tight text-slate-900 sm:text-5xl">
                Curate every walk with luminous galleries
              </h1>
              <p className="max-w-2xl text-base leading-relaxed text-slate-600">
                Import the hero shot from your latest roam and we’ll polish it
                into a thumb-forward gallery-ready pair the moment you press
                upload. Drag, drop, or tap to add a handful—we’ll perfect them
                one by one.
              </p>
            </div>
          </header>

          <UploadPanel
            inputRef={fileInputRef}
            isDropping={isDropping}
            isUploading={uploadMutation.isPending}
            error={localError || (uploadMutation.isError ? mutationError : '')}
            onBrowse={() => fileInputRef.current?.click()}
            onInputChange={event => handleFiles(event.target.files)}
            onDrop={onDrop}
            onDragOver={onDragOver}
            onDragLeave={onDragLeave}
          />

          <Gallery
            photos={photos}
            loading={photosQuery.isLoading || uploadMutation.isPending}
            empty={isEmpty}
          />
        </section>

        <InsightsPanel
          totalPhotos={photos.length}
          updating={photosQuery.isFetching || uploadMutation.isPending}
        />
      </div>
    </div>
  );
}

type UploadPanelProps = {
  inputRef: RefObject<HTMLInputElement>;
  isDropping: boolean;
  isUploading: boolean;
  error: string;
  onBrowse: () => void;
  onInputChange: (event: ChangeEvent<HTMLInputElement>) => void;
  onDrop: (event: DragEvent<HTMLDivElement>) => void;
  onDragOver: (event: DragEvent<HTMLDivElement>) => void;
  onDragLeave: () => void;
};

function UploadPanel({
  inputRef,
  isDropping,
  isUploading,
  error,
  onBrowse,
  onInputChange,
  onDrop,
  onDragOver,
  onDragLeave,
}: UploadPanelProps) {
  return (
    <div>
      <div
        onClick={onBrowse}
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
            {isUploading
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
          ref={inputRef}
          type="file"
          accept="image/*"
          multiple
          className="hidden"
          onChange={onInputChange}
        />
        <div className="pointer-events-none absolute inset-0 rounded-3xl border border-slate-100">
          <div className="absolute inset-0 rounded-3xl bg-gradient-to-tr from-sky-100/40 via-transparent to-transparent" />
        </div>
      </div>
      {error ? <p className="mt-3 text-sm text-rose-500">{error}</p> : null}
    </div>
  );
}

type GalleryProps = {
  photos: Photo[];
  loading: boolean;
  empty: boolean;
};

function Gallery({ photos, loading, empty }: GalleryProps) {
  if (loading) {
    return (
      <div className="grid gap-6 sm:grid-cols-2 xl:grid-cols-3">
        {Array.from({ length: 6 }).map((_, index) => (
          <div
            key={`skeleton-${index}`}
            className="h-64 animate-pulse rounded-3xl border border-slate-200 bg-white/70 shadow-inner shadow-slate-200/40"
          />
        ))}
      </div>
    );
  }

  if (empty) {
    return (
      <div className="flex flex-col items-center justify-center gap-4 rounded-3xl border border-slate-200 bg-white/95 p-12 text-center shadow-xl shadow-slate-200/70">
        <div className="flex h-14 w-14 items-center justify-center rounded-full bg-sky-100 text-sky-600 shadow-inner shadow-sky-200/80">
          <span className="text-2xl">📷</span>
        </div>
        <div className="space-y-2">
          <h2 className="text-xl font-semibold text-slate-900">
            You haven’t uploaded any walks yet
          </h2>
          <p className="text-sm text-slate-600">
            Start by dropping a favorite shot or selecting it from your library
            to see it bloom into a curated gallery.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="grid gap-6 sm:grid-cols-2 xl:grid-cols-3">
      {photos.map(photo => (
        <figure
          key={photo.id}
          className="group relative overflow-hidden rounded-3xl border border-slate-200 bg-white/95 shadow-xl shadow-slate-200/70 transition duration-200 hover:-translate-y-1 hover:shadow-2xl"
        >
          <img
            src={photo.thumbnail_url}
            alt={'Photowalk upload'}
            className="h-64 w-full object-cover transition duration-300 group-hover:scale-[1.03]"
            loading="lazy"
          />
          <figcaption className="flex flex-col gap-3 border-t border-slate-100 bg-gradient-to-b from-white via-white to-slate-50 p-5 text-sm text-slate-600">
            <div className="flex items-center justify-between text-xs uppercase tracking-[0.2em] text-slate-500">
              <span>{formatDate(photo.inserted_at)}</span>
              <span className="rounded-full bg-sky-100 px-2 py-0.5 text-sky-700">
                Full &amp; thumbnail
              </span>
            </div>
            <div>
              <p className="text-base font-semibold text-slate-900">
                {photo.title || 'Untitled capture'}
              </p>
              <p className="mt-1 text-xs text-slate-500">
                Ready to share — optimized in two resolutions for hero moments
                and speed.
              </p>
            </div>
            <div className="flex items-center justify-between text-xs">
              <a
                href={photo.full_url}
                className="inline-flex items-center gap-1 rounded-full bg-sky-100 px-3 py-1 font-medium text-sky-700 transition hover:bg-sky-200"
                target="_blank"
                rel="noreferrer"
              >
                View full size ↗
              </a>
            </div>
          </figcaption>
        </figure>
      ))}
    </div>
  );
}

type InsightsPanelProps = {
  totalPhotos: number;
  updating: boolean;
};

function InsightsPanel({ totalPhotos, updating }: InsightsPanelProps) {
  const status = useMemo(() => {
    if (updating) return 'Refreshing your gallery…';
    if (!totalPhotos) return 'Awaiting your first upload';
    if (totalPhotos < 10) return 'Building momentum';
    return 'Your library is thriving';
  }, [totalPhotos, updating]);

  return (
    <aside className="w-full max-w-sm space-y-6 rounded-3xl border border-slate-200 bg-white/95 p-8 shadow-xl shadow-slate-200/70">
      <div className="space-y-2">
        <p className="text-sm uppercase tracking-[0.3em] text-slate-500">
          Momentum
        </p>
        <h2 className="text-2xl font-semibold text-slate-900">{status}</h2>
      </div>
      <div className="rounded-2xl border border-slate-100 bg-gradient-to-br from-white via-white to-slate-50 p-6 shadow-inner shadow-slate-200/60">
        <p className="text-sm text-slate-600">Photos processed to date</p>
        <p className="mt-4 text-5xl font-semibold text-slate-900">{totalPhotos}</p>
        <p className="mt-6 text-xs text-slate-500">
          Each upload receives a 2048px hero version plus a 512px square
          thumbnail for silky-fast grids and previews.
        </p>
      </div>
      <div className="space-y-3 text-xs text-slate-600">
        <p>Need local testing?</p>
        <ul className="space-y-2">
          <li>
            • Files are stored under <code>priv/waffle/test</code> locally.
          </li>
          <li>
            • In production files stay on the app server and surface via
            /uploads.
          </li>
        </ul>
      </div>
    </aside>
  );
}

function formatDate(value?: string | null) {
  if (!value) return 'Just now';
  const date = new Date(value);
  return new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(date);
}

function humanReadableMime(maybeMime?: string | null) {
  if (!maybeMime) return 'image/jpeg';
  return maybeMime.replace('image/', '');
}

export const Route = createFileRoute('/_app/photos-backup')({
  component: PhotosDashboard,
});
