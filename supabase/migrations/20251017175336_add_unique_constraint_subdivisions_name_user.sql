/*
  # Add unique constraint to subdivisions

  1. Changes
    - Add unique constraint on (name, user_id) to prevent duplicate subdivision names per user
    - This prevents the "JSON object requested, multiple rows returned" error when searching by name
  
  2. Security
    - No changes to RLS policies
*/

-- Add unique constraint to prevent duplicate subdivision names per user
CREATE UNIQUE INDEX IF NOT EXISTS subdivisions_name_user_id_unique 
ON subdivisions(name, user_id);
