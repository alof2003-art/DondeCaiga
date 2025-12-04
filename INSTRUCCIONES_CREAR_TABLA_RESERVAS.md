# 🔧 CREAR TABLA DE RESERVAS EN SUPABASE

## ⚠️ ERROR ACTUAL
```
null value in column "numero_personas" violates not-null constraint
```

**Causa:** La tabla `reservas` NO existe o tiene una estructura incorrecta.

---

## 📝 PASOS PARA SOLUCIONAR

### 1. Ir a Supabase
1. Abre tu navegador
2. Ve a: https://supabase.com/dashboard
3. Selecciona tu proyecto: **donde_caigav2**

### 2. Abrir SQL Editor
1. En el menú lateral izquierdo, click en **"SQL Editor"**
2. Click en **"New query"**

### 3. Copiar y Pegar el SQL
1. Abre el archivo: `EJECUTAR_ESTO_EN_SUPABASE.sql`
2. Copia TODO el contenido
3. Pégalo en el SQL Editor de Supabase

### 4. Ejecutar
1. Click en el botón **"Run"** (o presiona Ctrl+Enter)
2. Espera a que termine (debería tomar 1-2 segundos)
3. Deberías ver: ✅ **"Success. No rows returned"**

### 5. Verificar
1. En el menú lateral, click en **"Table Editor"**
2. Busca la tabla **"reservas"**
3. Deberías ver las columnas:
   - id
   - propiedad_id
   - viajero_id
   - fecha_inicio
   - fecha_fin
   - estado
   - created_at
   - updated_at

---

## ✅ DESPUÉS DE EJECUTAR EL SQL

Vuelve a la app y prueba crear una reserva. Debería funcionar correctamente.

---

## 🔍 SI SIGUE DANDO ERROR

Si después de ejecutar el SQL sigue dando error, puede ser:

1. **No se ejecutó correctamente el SQL**
   - Verifica que diga "Success" en Supabase
   - Revisa que la tabla "reservas" aparezca en Table Editor

2. **Problema de permisos RLS**
   - Las políticas RLS están incluidas en el SQL
   - Si da error de permisos, avísame

3. **Caché de la app**
   - Cierra la app completamente
   - Vuelve a ejecutar: `flutter run -d windows`

---

## 📊 ESTRUCTURA DE LA TABLA

```sql
reservas
├── id (UUID) - Primary Key
├── propiedad_id (UUID) - FK a propiedades
├── viajero_id (UUID) - FK a users_profiles
├── fecha_inicio (DATE)
├── fecha_fin (DATE)
├── estado (TEXT) - pendiente, confirmada, rechazada, etc.
├── created_at (TIMESTAMP)
└── updated_at (TIMESTAMP)
```

**NOTA:** NO tiene columna `numero_personas` porque no es necesaria. 
La capacidad ya está en la tabla `propiedades`.
