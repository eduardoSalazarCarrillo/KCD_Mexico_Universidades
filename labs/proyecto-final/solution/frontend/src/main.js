// Configuración del API
// En producción, el backend estará en /api
const API_URL = "/api";

// Elementos del DOM
const todoForm = document.getElementById("todo-form");
const todoInput = document.getElementById("todo-input");
const todoList = document.getElementById("todo-list");
const loadingEl = document.getElementById("loading");
const errorEl = document.getElementById("error");

// Obtener todas las tareas
async function fetchTodos() {
  showLoading(true);
  showError("");

  try {
    const response = await fetch(`${API_URL}/todos`);
    if (!response.ok) {
      throw new Error("Error al cargar las tareas");
    }
    const todos = await response.json();
    renderTodos(todos);
  } catch (error) {
    showError(error.message);
    console.error("Error fetching todos:", error);
  } finally {
    showLoading(false);
  }
}

// Crear una nueva tarea
async function createTodo(title) {
  try {
    const response = await fetch(`${API_URL}/todos`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ title }),
    });

    if (!response.ok) {
      throw new Error("Error al crear la tarea");
    }

    return await response.json();
  } catch (error) {
    showError(error.message);
    console.error("Error creating todo:", error);
    throw error;
  }
}

// Actualizar una tarea
async function updateTodo(id, completed) {
  try {
    const response = await fetch(`${API_URL}/todos/${id}`, {
      method: "PUT",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ completed }),
    });

    if (!response.ok) {
      throw new Error("Error al actualizar la tarea");
    }

    return await response.json();
  } catch (error) {
    showError(error.message);
    console.error("Error updating todo:", error);
    throw error;
  }
}

// Eliminar una tarea
async function deleteTodo(id) {
  try {
    const response = await fetch(`${API_URL}/todos/${id}`, {
      method: "DELETE",
    });

    if (!response.ok) {
      throw new Error("Error al eliminar la tarea");
    }
  } catch (error) {
    showError(error.message);
    console.error("Error deleting todo:", error);
    throw error;
  }
}

// Renderizar la lista de tareas
function renderTodos(todos) {
  todoList.innerHTML = "";

  if (todos.length === 0) {
    todoList.innerHTML =
      '<li class="todo-item"><span>No hay tareas. ¡Agrega una!</span></li>';
    return;
  }

  todos.forEach((todo) => {
    const li = document.createElement("li");
    li.className = `todo-item ${todo.completed ? "completed" : ""}`;
    li.innerHTML = `
      <input type="checkbox" ${todo.completed ? "checked" : ""}
             onchange="handleToggle(${todo.id}, this.checked)">
      <span>${escapeHtml(todo.title)}</span>
      <button class="delete-btn" onclick="handleDelete(${todo.id})">Eliminar</button>
    `;
    todoList.appendChild(li);
  });
}

// Escapar HTML para prevenir XSS
function escapeHtml(text) {
  const div = document.createElement("div");
  div.textContent = text;
  return div.innerHTML;
}

// Mostrar/ocultar loading
function showLoading(show) {
  loadingEl.classList.toggle("hidden", !show);
}

// Mostrar error
function showError(message) {
  errorEl.textContent = message;
  errorEl.classList.toggle("hidden", !message);
}

// Manejador del formulario
todoForm.addEventListener("submit", async (e) => {
  e.preventDefault();
  const title = todoInput.value.trim();

  if (!title) return;

  try {
    await createTodo(title);
    todoInput.value = "";
    await fetchTodos();
  } catch (error) {
    // Error ya manejado en createTodo
  }
});

// Manejador de toggle
async function handleToggle(id, completed) {
  try {
    await updateTodo(id, completed);
    await fetchTodos();
  } catch (error) {
    // Error ya manejado en updateTodo
  }
}

// Manejador de eliminar
async function handleDelete(id) {
  if (!confirm("¿Estás seguro de eliminar esta tarea?")) return;

  try {
    await deleteTodo(id);
    await fetchTodos();
  } catch (error) {
    // Error ya manejado en deleteTodo
  }
}

// Exponer funciones al scope global para los event handlers inline
window.handleToggle = handleToggle;
window.handleDelete = handleDelete;

// Cargar tareas al iniciar
fetchTodos();
