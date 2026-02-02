-- Archivo de inicialización de la base de datos
-- Este script se ejecuta automáticamente cuando PostgreSQL inicia por primera vez

-- Crear la tabla de tareas si no existe
CREATE TABLE IF NOT EXISTS todos (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insertar datos de ejemplo (opcional)
INSERT INTO todos (title, completed) VALUES
    ('Aprender Kubernetes', false),
    ('Crear Deployments', false),
    ('Configurar Services', false),
    ('Implementar Ingress', false),
    ('Configurar HPA', false);
