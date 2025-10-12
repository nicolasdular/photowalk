import * as React from 'react';

export function PageTitle({
  children,
  actions,
  backLink,
  title,
  subTitle,
}: {
  children?: React.ReactNode;
  actions?: React.ReactNode;
  backLink?: React.ReactNode;
  title?: React.ReactNode;
  subTitle?: React.ReactNode;
}) {
  return (
    <>
      {backLink}
      <div className="mt-4 mb-8 flex items-center justify-between">
        <div>
          <h1 className="scroll-m-20 text-4xl font-medium tracking-tight text-balance">
            {title}
          </h1>
          {subTitle}
        </div>

        {actions ? actions : null}
      </div>
    </>
  );
}
