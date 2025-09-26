// Utilities to transform RPC errors into UI-friendly shapes
import type { AshRpcError } from "../ash_rpc";

export type TransformedErrors = {
  general: string[];
  fields: Record<string, string[]>;
  firstField?: string;
};

function pushField(
  acc: Record<string, string[]>,
  field: string,
  message: string
) {
  if (!field) return;
  if (!acc[field]) acc[field] = [];
  if (!acc[field].includes(message)) acc[field].push(message);
}

function cleanMessage(message?: string): string | null {
  if (!message) return null;
  const trimmed = message.trim();
  if (!trimmed) return null;

  // If message contains bullet lines like "* argument email is required",
  // prefer those bullets, otherwise return the first non-empty line.
  const lines = trimmed.split("\n");
  const bulletLines = lines
    .map((l) => l.trim())
    .filter((l) => l.startsWith("* "))
    .map((l) => l.replace(/^\*\s+/, "").trim());

  if (bulletLines.length > 0) {
    return bulletLines.join("\n");
  }

  // Fallback to the first meaningful line
  const first = lines.map((l) => l.trim()).find((l) => l.length > 0) || "";
  return first;
}

function extractFieldFromPath(path: unknown): string | null {
  if (typeof path === "string" && path) return path;
  if (Array.isArray(path) && path.length > 0) {
    const s = path.filter((p) => typeof p === "string").join(".");
    return s || null;
  }
  return null;
}

export function transformRpcErrors(
  errors: Array<AshRpcError | Record<string, any>> | undefined | null
): TransformedErrors {
  const out: TransformedErrors = { general: [], fields: {} };
  if (!errors || errors.length === 0) return out;

  for (const err of errors) {
    const type = (err as any)?.type;
    const message = cleanMessage((err as any)?.message);
    const field = (err as any)?.field || (err as any)?.fieldPath || null;
    const details = (err as any)?.details;

    // Prefer structured inner errors if present
    const innerErrors = details?.errors;
    if (Array.isArray(innerErrors) && innerErrors.length > 0) {
      for (const ie of innerErrors) {
        const innerField =
          ie?.field || extractFieldFromPath(ie?.path) || extractFieldFromPath(ie?.fields);
        const innerMsg = cleanMessage(ie?.message) || message || type || "Unknown error";
        if (innerField) {
          pushField(out.fields, innerField, innerMsg);
          if (!out.firstField) out.firstField = innerField;
        } else {
          if (!out.general.includes(innerMsg)) out.general.push(innerMsg);
        }
      }
      continue;
    }

    // If we have a field directly on the error
    if (field) {
      pushField(out.fields, String(field), message || type || "Unknown error");
      if (!out.firstField) out.firstField = String(field);
      continue;
    }

    // Try extracting field from details.path if available
    const detailsPath = extractFieldFromPath(details?.path);
    if (detailsPath) {
      pushField(out.fields, detailsPath, message || type || "Unknown error");
      if (!out.firstField) out.firstField = detailsPath;
      continue;
    }

    // Otherwise, treat as general error
    if (message && !out.general.includes(message)) out.general.push(message);
    else if (type && !out.general.includes(type)) out.general.push(type);
    else if (!out.general.includes("Unknown error")) out.general.push("Unknown error");
  }

  return out;
}

export function getFieldMessages(
  errors: Array<AshRpcError | Record<string, any>> | undefined | null,
  field: string
): string[] {
  if (!field) return [];
  const t = transformRpcErrors(errors);
  return t.fields[field] || [];
}

export function hasFieldError(
  errors: Array<AshRpcError | Record<string, any>> | undefined | null,
  field: string
): boolean {
  return getFieldMessages(errors, field).length > 0;
}
