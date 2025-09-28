import { createFileRoute } from '@tanstack/react-router';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { listTodos, createTodo, updateTodo } from '../../ash_rpc';
import { useState } from 'react';
import { Input } from '@catalyst/input';
import { Checkbox, CheckboxField } from '@catalyst/checkbox';
import { Label } from '@catalyst/fieldset';

function TodoItem({ todo }: { todo: any }) {
  const [checked, setChecking] = useState(todo.completed);

  return (
    <CheckboxField>
      <Checkbox
        checked={checked}
        className="mr-2"
        id={`todo-${todo.id}`}
        name={`todo-${todo.id}`}
        onChange={async checked => {
          setChecking(checked);

          await updateTodo({
            primaryKey: todo.id,
            input: { completed: checked },
            fields: ['id', 'completed'],
          });
        }}
      />
      <Label htmlFor={`todo-${todo.id}`} style={{ cursor: 'pointer' }}>
        {todo.title}
      </Label>
    </CheckboxField>
  );
}

function Todos() {
  const [name, setName] = useState('');
  const queryClient = useQueryClient();
  const query = useQuery({
    queryKey: ['todos'],
    queryFn: () =>
      listTodos({
        fields: ['id', 'title', 'completed'],
        sort: '-id',
        page: { limit: 100 },
      }),
  });

  const mutation = useMutation({
    mutationFn: (title: string) =>
      createTodo({
        input: { title },
        fields: ['id', 'title', 'completed'],
      }),
    onSuccess: () => {
      // Invalidate and refetch
      queryClient.invalidateQueries({ queryKey: ['todos'] });
      setName('');
    },
  });

  return (
    <div className="flex justify-center">
      <div className="w-128">
        <form
          onSubmit={async e => {
            e.preventDefault();
            if (e.target && (e.target as any)['todo']) {
              mutation.mutate((e.target as any)['todo'].value);
            }
          }}
        >
          <Input
            autoFocus
            value={name}
            className="mt-2 w-full border border-gray-500/20"
            onChange={e => setName(e.currentTarget.value)}
            type="text"
            name="todo"
          />
        </form>
        {query.data?.success ? (
          <div>
            <ul className="mt-10">
              {query.data.data.results.map((todo, index) => {
                return (
                  <li key={index}>
                    <TodoItem todo={todo} />
                  </li>
                );
              })}
            </ul>
          </div>
        ) : null}
      </div>
    </div>
  );
}

export const Route = createFileRoute('/_app/')({
  component: Todos,
});
