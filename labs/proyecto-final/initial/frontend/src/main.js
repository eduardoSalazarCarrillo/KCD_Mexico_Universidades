// TODO: Configurar la URL del API
// En producción, el backend estará en /api
const API_URL = "/api";

// Elementos del DOM
const todoForm = document.getElementById("todo-form");
const todoInput = document.getElementById("todo-input");
const todoList = document.getElementById("todo-list");
const loadingEl = document.getElementById("loading");
const errorEl = document.getElementById("error");

// TODO: Implementar la función para obtener todas las tareas
async function fetchTodos() {
  // Hint: Usar fetch() para llamar a GET ${API_URL}/todos
  // Mostrar loading mientras carga
  // Manejar errores mostrando mensaje en errorEl
}

// TODO: Implementar la función para crear una tarea
async function createTodo(title) {
  // Hint: Usar fetch() para llamar a POST ${API_URL}/todos
  // Body: { title }
  // Headers: { 'Content-Type': 'application/json' }
}

// TODO: Implementar la función para actualizar una tarea
async function updateTodo(id, completed) {
  // Hint: Usar fetch() para llamar a PUT ${API_URL}/todos/${id}
  // Body: { completed }
}

// TODO: Implementar la función para eliminar una tarea
async function deleteTodo(id) {
  // Hint: Usar fetch() para llamar a DELETE ${API_URL}/todos/${id}
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
      <span>${todo.title}</span>
      <button class="delete-btn" onclick="handleDelete(${todo.id})">Eliminar</button>
    `;
    todoList.appendChild(li);
  });
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

// TODO: Implementar el manejador del formulario
todoForm.addEventListener("submit", async (e) => {
  e.preventDefault();
  // Hint: Obtener el valor del input
  // Llamar a createTodo()
  // Limpiar el input
  // Recargar la lista
});

// TODO: Implementar el manejador de toggle
async function handleToggle(id, completed) {
  // Hint: Llamar a updateTodo() y recargar la lista
}

// TODO: Implementar el manejador de eliminar
async function handleDelete(id) {
  // Hint: Llamar a deleteTodo() y recargar la lista
}

// Exponer funciones al scope global para los event handlers inline
window.handleToggle = handleToggle;
window.handleDelete = handleDelete;

// Cargar tareas al iniciar
fetchTodos();
