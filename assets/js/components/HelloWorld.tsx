import { listTodos, createTodo } from "../ash_rpc";
import { useEffect, useState } from "preact/hooks";

function TodoItem({ todo, todoUpdate }: { todo: any }) {
  const [checked, setChecking] = useState(todo.completed);

  return (
    <li>
      <input
        checked={checked}
        className="mr-2"
        id={`todo-${todo.id}`}
        name={`todo-${todo.id}`}
        type="checkbox"
      />
      <label htmlFor={`todo-${todo.id}`} style={{ cursor: "pointer" }}>
        {todo.title}
      </label>
    </li>
  );
}

export function HelloWorld() {
  const [todos, setTodos] = useState([]);
  const [name, setName] = useState("");

  useEffect(() => {
    async function fetchTodos() {
      const result = await listTodos({ fields: ["id", "title", "completed"] });
      if (result.success) {
        setTodos(result.data);
      }
    }
    fetchTodos();
  }, []);

  return (
    <div className="flex justify-center">
      <div className="w-128">
        <header className="mt-10 flex justify-center font-mono text-2xl">
          the-stack
        </header>
        <ul className="mt-10">
          {todos.map((todo, index) => (
            <TodoItem key={index} todo={todo} />
          ))}
        </ul>
        <form
          onSubmit={async (e) => {
            e.preventDefault();
            await createTodo({
              input: { title: e.target[0].value },
              fields: ["id", "title", "completed"],
            });
            // Re-use fetchTodos by calling it after creating a todo
          }}
        >
          <input
            autoFocus
            className="mt-2 w-full border border-gray-500/20"
            onChange={(e) => setName(e.target.value)}
            type="text"
          />
        </form>
      </div>
    </div>
  );
}
