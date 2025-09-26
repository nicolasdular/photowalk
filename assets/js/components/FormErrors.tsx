import { transformRpcErrors, getFieldMessages } from "../utils/rpcErrors";

type ErrorLike = Record<string, any>;

export function ErrorSummary({
  errors,
  className = "space-y-1",
}: {
  errors: Array<ErrorLike> | undefined | null;
  className?: string;
}) {
  const t = transformRpcErrors(errors);
  if (t.general.length === 0) return null;
  return (
    <div className={className}>
      {t.general.map((msg, idx) => (
        <p key={`gen-${idx}`} className="text-sm text-red-600">
          {msg}
        </p>
      ))}
    </div>
  );
}

export function FieldErrors({
  name,
  errors,
  className = "mt-1 space-y-1",
}: {
  name: string;
  errors: Array<ErrorLike> | undefined | null;
  className?: string;
}) {
  const messages = getFieldMessages(errors, name);
  if (messages.length === 0) return null;
  return (
    <div className={className}>
      {messages.map((m, i) => (
        <p key={`${name}-${i}`} className="text-sm text-red-600">
          {m}
        </p>
      ))}
    </div>
  );
}

