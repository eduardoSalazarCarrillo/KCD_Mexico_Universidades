const express = require("express");
const cors = require("cors");
const { Pool } = require("pg");

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// TODO: Configurar la conexión a PostgreSQL usando variables de entorno
// Las variables disponibles serán:
// - DB_HOST: hostname del servicio de PostgreSQL
// - DB_PORT: puerto (5432)
// - DB_NAME: nombre de la base de datos
// - DB_USER: usuario
// - DB_PASSWORD: contraseña
const pool = new Pool({
  host: process.env.DB_HOST || "localhost",
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || "tododb",
  user: process.env.DB_USER || "todouser",
  password: process.env.DB_PASSWORD || "supersecret",
});

// Inicializar la base de datos
async function initDB() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS todos (
        id SERIAL PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        completed BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log("Base de datos inicializada");
  } catch (error) {
    console.error("Error inicializando la base de datos:", error);
  }
}

// TODO: Implementar endpoint de health check
// GET /health - Debe retornar { status: 'ok', timestamp: ... }
app.get("/health", (req, res) => {
  // Implementar aquí
});

// TODO: Implementar GET /todos
// Debe retornar todas las tareas ordenadas por fecha de creación
app.get("/todos", async (req, res) => {
  // Hint: Usar pool.query('SELECT * FROM todos ORDER BY created_at DESC')
});

// TODO: Implementar POST /todos
// Debe crear una nueva tarea con el título del body
// Body esperado: { title: string }
app.post("/todos", async (req, res) => {
  // Hint: Validar que title existe
  // Usar pool.query('INSERT INTO todos (title) VALUES ($1) RETURNING *', [title])
});

// TODO: Implementar PUT /todos/:id
// Debe actualizar el estado completed de una tarea
// Body esperado: { completed: boolean }
app.put("/todos/:id", async (req, res) => {
  // Hint: Usar pool.query('UPDATE todos SET completed = $1 WHERE id = $2 RETURNING *', [completed, id])
});

// TODO: Implementar DELETE /todos/:id
// Debe eliminar una tarea por su ID
app.delete("/todos/:id", async (req, res) => {
  // Hint: Usar pool.query('DELETE FROM todos WHERE id = $1', [id])
});

// Puerto del servidor
const PORT = process.env.PORT || 3000;

// Iniciar servidor
initDB().then(() => {
  app.listen(PORT, () => {
    console.log(`Servidor corriendo en puerto ${PORT}`);
  });
});
