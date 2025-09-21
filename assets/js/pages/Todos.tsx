import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { listTodos, createTodo, updateTodo } from '../ash_rpc';
import { useState } from 'preact/hooks';

function TodoItem({ todo }: { todo: any }) {
  const [checked, setChecking] = useState(todo.completed);

  return (
    <li>
      <input
        checked={checked}
        className="mr-2"
        id={`todo-${todo.id}`}
        name={`todo-${todo.id}`}
        type="checkbox"
        onChange={async e => {
          setChecking(e.currentTarget.checked);

          await updateTodo({
            primaryKey: todo.id,
            input: { completed: e.currentTarget.checked },
            fields: ['id', 'completed'],
          });
        }}
      />
      <label htmlFor={`todo-${todo.id}`} style={{ cursor: 'pointer' }}>
        {todo.title}
      </label>
    </li>
  );
}

export function Todos() {
  const [name, setName] = useState('');
  const queryClient = useQueryClient();
  const query = useQuery({
    queryKey: ['todos'],
    queryFn: () =>
      listTodos({
        fields: ['id', 'title', 'completed'],
        sort: '+id',
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
        <header className="mt-10 flex justify-center font-mono text-2xl">
          the-stack
        </header>
        {query.data?.success ? (
          <div>
            <ul className="mt-10">
              {query.data.data.results.map((todo, index) => {
                return <TodoItem key={index} todo={todo} />;
              })}
            </ul>
          </div>
        ) : null}
        <form
          onSubmit={async e => {
            e.preventDefault();
            if (e.target && e.target['todo']) {
              mutation.mutate(e.target['todo'].value);
            }
          }}
        >
          <input
            autoFocus
            value={name}
            className="mt-2 w-full border border-gray-500/20"
            onChange={e => setName(e.currentTarget.value)}
            type="text"
            name="todo"
          />
        </form>
      </div>
    </div>
  );
}
