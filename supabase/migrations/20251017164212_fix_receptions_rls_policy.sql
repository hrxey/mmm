/*
  # Fix RLS policy for receptions table
  
  1. Changes
    - Drop duplicate policy "Allow authenticated users to insert receptions" that has WITH CHECK (true)
    - This policy conflicts with the proper policy that checks user_id ownership
  
  2. Security
    - Ensures only the proper policy with user_id check remains active
    - Prevents users from creating receptions with other users' IDs
*/

DROP POLICY IF EXISTS "Allow authenticated users to insert receptions" ON receptions;
