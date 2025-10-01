import { createFileRoute } from '@tanstack/react-router';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { client } from '../../api/client';
import type { components } from '../../api/schema';
import { FormEvent, useCallback, useEffect, useMemo, useState } from 'react';
import { Input } from '@catalyst/input';
import { Checkbox, CheckboxField } from '@catalyst/checkbox';
import { Label } from '@catalyst/fieldset';

type Todo = components['schemas']['Todo'];

const FALLBACK_ERROR = 'Something went wrong. Please try again.';

function resolveErrorMessage(error: unknown): string {
  if (error instanceof Error && error.message) {
    return error.message;
  }

  return FALLBACK_ERROR;
}

function TodoItem({
  todo,
  onError,
  onClearError,
}: {
  todo: Todo;
  onError: (message: string) => void;
  onClearError: () => void;
}) {
  const queryClient = useQueryClient();
  const [checked, setChecked] = useState(todo.completed);

  const mutation = useMutation<Todo, unknown, boolean, undefined>({
    mutationFn: async (nextChecked: boolean) => {
      const { data, error } = await client.PATCH('/api/todos/{id}', {
        params: {
          path: { id: todo.id },
        },
        body: { completed: nextChecked },
      });

      if (error) {
        throw new Error('Failed to update todo');
      }

      setChecked(nextChecked);

      return data;
    },
    onError: error => {
      onError(resolveErrorMessage(error));
    },
    onSuccess: () => {
      // Refetch todos so UI reflects latest state
      queryClient.invalidateQueries({ queryKey: ['todos'] });
      onClearError();
    },
  });

  return (
    <CheckboxField>
      <Checkbox
        checked={checked}
        className="mr-3"
        disabled={mutation.isPending}
        id={`todo-${todo.id}`}
        name={`todo-${todo.id}`}
        onChange={nextChecked => mutation.mutate(nextChecked)}
      />
      <Label
        className="cursor-pointer font-medium text-slate-700 transition-colors duration-150 group-hover:text-slate-900 dark:text-slate-100 dark:group-hover:text-white"
        htmlFor={`todo-${todo.id}`}
      >
        {todo.title}
      </Label>
    </CheckboxField>
  );
}

function Todos() {
  const queryClient = useQueryClient();
  const [name, setName] = useState('');
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const handleError = useCallback((message: string) => {
    setErrorMessage(message || FALLBACK_ERROR);
  }, []);

  const clearError = useCallback(() => {
    setErrorMessage(null);
  }, []);

  const query = useQuery({
    queryKey: ['todos'],
    queryFn: async () => {
      const { data, error } = await client.GET('/api/todos');

      if (error) {
        throw new Error('Failed to load todos');
      }

      return data.data;
    },
  });

  const todos: Todo[] = useMemo(() => {
    return query.data || [];
  }, [query.data]);

  const createTodoMutation = useMutation<Todo, unknown, string>({
    mutationFn: async (title: string) => {
      const trimmed = title.trim();
      const { data, error } = await client.POST('/api/todos', {
        body: { title: trimmed },
      });

      if (error) {
        throw new Error('Failed to create todo');
      }

      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['todos'] });
      setName('');
      clearError();
    },
    onError: error => {
      handleError(resolveErrorMessage(error));
    },
  });

  const handleSubmit = useCallback(
    (event: FormEvent<HTMLFormElement>) => {
      event.preventDefault();
      const title = name.trim();
      if (!title) {
        handleError('Give your todo a title before saving.');
        return;
      }

      createTodoMutation.mutate(title);
    },
    [createTodoMutation, handleError, name]
  );

  const isLoading = query.isPending;
  const hasTodos = !isLoading && todos.length > 0;

  return (
    <div className="flex justify-center px-4 py-10">
      <div className="w-full max-w-xl">
        <form onSubmit={handleSubmit}>
          <Input
            autoFocus
            value={name}
            onChange={event => {
              setName(event.currentTarget.value);
              if (errorMessage) {
                clearError();
              }
            }}
            placeholder="Add a new todo..."
            type="text"
            name="todo"
            disabled={createTodoMutation.isPending}
            aria-describedby={errorMessage ? 'todo-error' : undefined}
          />
        </form>

        {errorMessage ? (
          <div
            id="todo-error"
            role="alert"
            aria-live="polite"
            className="mt-4 rounded-xl border border-red-200/70 bg-red-50 px-4 py-3 text-sm text-red-700 shadow-sm transition-all duration-200 dark:border-red-400/40 dark:bg-red-500/10 dark:text-red-300"
          >
            <div className="flex items-start gap-3">
              <span className="mt-0.5 inline-flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-red-100 text-red-600 shadow-inner dark:bg-red-400/20 dark:text-red-300">
                <svg
                  aria-hidden
                  className="h-3.5 w-3.5"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                >
                  <path d="M10 18a8 8 0 1 1 0-16 8 8 0 0 1 0 16Zm.75-5.25h-1.5v1.5h1.5v-1.5Zm0-6h-1.5v4.5h1.5v-4.5Z" />
                </svg>
              </span>
              <p className="flex-1 leading-6">{errorMessage}</p>
              <button
                type="button"
                onClick={clearError}
                className="-m-1 rounded-full p-1 text-red-600 transition hover:bg-red-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-500 dark:text-red-300 dark:hover:bg-red-400/20"
              >
                <span className="sr-only">Dismiss error</span>
                <svg
                  aria-hidden
                  className="h-4 w-4"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                >
                  <path d="M7.22 7.22a.75.75 0 0 1 1.06 0L10 8.94l1.72-1.72a.75.75 0 1 1 1.06 1.06L11.06 10l1.72 1.72a.75.75 0 1 1-1.06 1.06L10 11.06l-1.72 1.72a.75.75 0 1 1-1.06-1.06L8.94 10 7.22 8.28a.75.75 0 0 1 0-1.06Z" />
                </svg>
              </button>
            </div>
          </div>
        ) : null}

        {!isLoading && query.isError ? (
          <div className="mt-10 rounded-xl border border-amber-300/70 bg-amber-50 px-4 py-4 text-sm text-amber-800 shadow-sm dark:border-amber-400/50 dark:bg-amber-500/10 dark:text-amber-200">
            We ran into a problem loading your todos. Please refresh and try
            again.
          </div>
        ) : null}

        {hasTodos ? (
          <ul className="mt-10 space-y-3">
            {todos.map(todo => (
              <li key={todo.id}>
                <TodoItem
                  todo={todo}
                  onError={handleError}
                  onClearError={clearError}
                />
              </li>
            ))}
          </ul>
        ) : null}

        {!isLoading && todos.length === 0 && !query.isError ? (
          <div className="mt-10 rounded-xl border border-dashed border-slate-300/70 bg-white/60 px-6 py-10 text-center text-sm text-slate-500 shadow-inner dark:border-slate-600 dark:bg-slate-800/60 dark:text-slate-300">
            All caught up. Add your first todo above to get started.
          </div>
        ) : null}
      </div>
    </div>
  );
}

export const Route = createFileRoute('/_app/')({
  component: Todos,
});
