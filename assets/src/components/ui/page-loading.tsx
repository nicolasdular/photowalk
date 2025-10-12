import * as React from 'react';
import { Spinner } from './spinner';

export function PageLoading({ title }: { title?: React.ReactNode }) {
  return (
    <div className="flex min-h-[300px] w-full justify-center items-center">
      <div className="animate-pulse rounded-md bg-muted py-4 px-12 flex flex-row w-72 justify-center items-center space-x-4">
        <Spinner />
        {title}
      </div>
    </div>
  );
}
