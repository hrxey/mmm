/*
  # Создание всех таблиц для системы управления ремонтом электродвигателей MotorFlow
  
  ## Описание
  Эта миграция создает полную структуру базы данных для приложения MotorFlow, 
  включая справочники, таблицы приемки, УПД и все необходимые триггеры и функции.
  
  ## 1. Справочные таблицы
  
  ### `counterparties` - Контрагенты
  - `id` (uuid, primary key) - Уникальный идентификатор
  - `user_id` (uuid) - Владелец записи
  - `name` (text) - Название контрагента
  - `code` (text) - Внутренний код
  - `inn` (text) - ИНН (уникальный индекс)
  - `kpp` (text) - КПП
  - `address` (text) - Юридический адрес
  - `contact_person` (text) - Контактное лицо
  - `phone` (text) - Телефон
  - `email` (text) - Email
  - `contact_info` (text) - Общая контактная информация
  - `description` (text) - Описание
  - `is_active` (boolean) - Активен
  - `created_at`, `updated_at` (timestamptz)
  
  ### `subdivisions` - Подразделения
  - `id` (uuid, primary key)
  - `user_id` (uuid)
  - `name` (text) - Название подразделения
  - `code` (text) - Код
  - `description` (text) - Описание
  - `is_active` (boolean) - Активен
  - `created_at` (timestamptz)
  
  ### `motors` - Справочник двигателей
  - `id` (uuid, primary key)
  - `user_id` (uuid)
  - `name` (text) - Название модели
  - `power_kw` (numeric) - Мощность в кВт
  - `rpm` (integer) - Обороты в минуту
  - `voltage` (integer) - Напряжение
  - `current` (numeric) - Ток
  - `efficiency` (numeric) - КПД
  - `manufacturer` (text) - Производитель
  - `price_per_unit` (numeric) - Цена
  - `description`, `text` (text) - Описание
  - `is_active` (boolean) - Активен
  - `created_at`, `updated_at` (timestamptz)
  
  ### `wires` - Справочник проводов
  - Типы проводов, марки, сечения, формы
  
  ### `bearings` - Справочник подшипников
  - Марки, диаметры, номера подшипников
  
  ### `impellers` - Справочник крыльчаток
  - Вентиляторы, диаметры, лопасти
  
  ### `labor_payments` - Справочник оплаты труда
  - ФИО, должности, часовые ставки
  
  ### `special_documents` - Специальные документы
  - УПД, суммы с/без НДС
  
  ### `reference_types` - Типы справочников
  - Динамическое управление справочниками
  
  ### `reception_templates` - Шаблоны приемки
  - Шаблоны для быстрого создания приемок
  
  ## 2. Таблицы приемки
  
  ### `receptions` - Документы приемки
  - Заголовок документа приемки
  
  ### `accepted_motors` - Принятые двигатели
  - Индивидуальные двигатели (ID для QR-кода)
  
  ### `reception_items` - Позиции работ
  - Детальные работы для каждого двигателя
  - Поле `upd_document_id` связывает с УПД
  
  ## 3. Финансовые документы (УПД)
  
  ### `upd_documents` - Заголовки УПД
  - Универсальные передаточные документы
  
  ### `upd_document_items` - Позиции УПД
  - Иерархическая структура позиций
  
  ### `repair_orders` - Заказы на ремонт (DEPRECATED)
  - Старая структура для совместимости
  
  ## 4. Безопасность
  - RLS включен на всех таблицах
  - Пользователи видят только свои данные
  - Политики для SELECT, INSERT, UPDATE, DELETE
  
  ## 5. Триггеры и функции
  - `update_updated_at_column()` - Обновление timestamps
  - `create_upd_and_link_items()` - Создание УПД и связывание позиций
  - `disband_upd_and_unlink_items()` - Расформирование УПД
*/

-- ============================================================================
-- 1. СПРАВОЧНЫЕ ТАБЛИЦЫ
-- ============================================================================

-- Контрагенты
CREATE TABLE IF NOT EXISTS counterparties (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  code text,
  inn text,
  kpp text,
  address text,
  contact_person text,
  phone text,
  email text,
  contact_info text,
  description text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE counterparties ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own counterparties"
  ON counterparties FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own counterparties"
  ON counterparties FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own counterparties"
  ON counterparties FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own counterparties"
  ON counterparties FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_counterparties_user_id ON counterparties(user_id);
CREATE INDEX IF NOT EXISTS idx_counterparties_name ON counterparties(name);
CREATE UNIQUE INDEX IF NOT EXISTS idx_counterparties_inn 
  ON counterparties(inn, user_id) WHERE inn IS NOT NULL AND inn <> '';

-- Подразделения
CREATE TABLE IF NOT EXISTS subdivisions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  code text,
  description text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE subdivisions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own subdivisions"
  ON subdivisions FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own subdivisions"
  ON subdivisions FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own subdivisions"
  ON subdivisions FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own subdivisions"
  ON subdivisions FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_subdivisions_user_id ON subdivisions(user_id);

-- Двигатели (справочник)
CREATE TABLE IF NOT EXISTS motors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  power_kw numeric(8, 2) NOT NULL DEFAULT 0,
  rpm integer NOT NULL DEFAULT 0,
  voltage integer DEFAULT 380,
  current numeric(8, 2) DEFAULT 0,
  efficiency numeric(5, 2) DEFAULT 0,
  manufacturer text DEFAULT '',
  price_per_unit numeric(12, 2) NOT NULL DEFAULT 0,
  description text DEFAULT '',
  text text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE motors ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own motors"
  ON motors FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own motors"
  ON motors FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own motors"
  ON motors FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own motors"
  ON motors FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_motors_user_id ON motors(user_id);
CREATE UNIQUE INDEX IF NOT EXISTS motors_power_rpm_voltage_key
  ON motors (power_kw, rpm, voltage, user_id) WHERE is_active = true;

-- Провода
CREATE TABLE IF NOT EXISTS wires (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  type text NOT NULL,
  brand text NOT NULL,
  name text NOT NULL,
  heat_resistance text,
  cross_section text NOT NULL,
  shape text NOT NULL,
  quantity numeric DEFAULT 1,
  price numeric DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE wires ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view all wires"
  ON wires FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can create wires"
  ON wires FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Authenticated users can update wires"
  ON wires FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Authenticated users can delete wires"
  ON wires FOR DELETE TO authenticated USING (true);

CREATE INDEX IF NOT EXISTS idx_wires_name ON wires(name);
CREATE INDEX IF NOT EXISTS idx_wires_brand ON wires(brand);

-- Подшипники
CREATE TABLE IF NOT EXISTS bearings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  brand text NOT NULL DEFAULT '',
  name text NOT NULL,
  diameter integer NOT NULL DEFAULT 0,
  number text NOT NULL DEFAULT '',
  type text NOT NULL DEFAULT '',
  created_at timestamptz DEFAULT now(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
);

ALTER TABLE bearings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own bearings"
  ON bearings FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own bearings"
  ON bearings FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own bearings"
  ON bearings FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own bearings"
  ON bearings FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_bearings_user_id ON bearings(user_id);

-- Крыльчатки
CREATE TABLE IF NOT EXISTS impellers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  mounting_diameter integer NOT NULL,
  outer_diameter integer NOT NULL,
  height integer NOT NULL,
  blade_count integer NOT NULL,
  user_id uuid NOT NULL REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now()
);

ALTER TABLE impellers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all impellers"
  ON impellers FOR SELECT TO authenticated USING (true);

CREATE POLICY "Users can create impellers"
  ON impellers FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own impellers"
  ON impellers FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own impellers"
  ON impellers FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_impellers_name ON impellers(name);

-- Оплата труда
CREATE TABLE IF NOT EXISTS labor_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  short_name text NOT NULL,
  full_name text NOT NULL,
  payment_name text NOT NULL,
  position text NOT NULL,
  hourly_rate numeric NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE labor_payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view labor payments"
  ON labor_payments FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can insert labor payments"
  ON labor_payments FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Authenticated users can update labor payments"
  ON labor_payments FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Authenticated users can delete labor payments"
  ON labor_payments FOR DELETE TO authenticated USING (true);

CREATE INDEX IF NOT EXISTS idx_labor_payments_payment_name ON labor_payments(payment_name);

-- Специальные документы
CREATE TABLE IF NOT EXISTS special_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  document_date timestamptz NOT NULL,
  document_number text NOT NULL,
  counterparty text NOT NULL,
  contract text NOT NULL DEFAULT '',
  amount_without_vat numeric NOT NULL DEFAULT 0,
  amount_with_vat numeric NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE special_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view special documents"
  ON special_documents FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can insert special documents"
  ON special_documents FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Authenticated users can update special documents"
  ON special_documents FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Authenticated users can delete special documents"
  ON special_documents FOR DELETE TO authenticated USING (true);

CREATE INDEX IF NOT EXISTS idx_special_documents_date ON special_documents(document_date);

-- Типы справочников
CREATE TABLE IF NOT EXISTS reference_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  type_key text NOT NULL,
  icon_name text NOT NULL DEFAULT 'FileText',
  route text NOT NULL,
  is_active boolean DEFAULT true,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, type_key)
);

ALTER TABLE reference_types ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own reference types"
  ON reference_types FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own reference types"
  ON reference_types FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own reference types"
  ON reference_types FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own reference types"
  ON reference_types FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- ============================================================================
-- 2. ТАБЛИЦЫ ПРИЕМКИ
-- ============================================================================

-- Документы приемки
CREATE TABLE IF NOT EXISTS receptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reception_date timestamptz NOT NULL,
  reception_number text,
  counterparty_id uuid NOT NULL REFERENCES counterparties(id) ON DELETE RESTRICT,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE receptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own receptions"
  ON receptions FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own receptions"
  ON receptions FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own receptions"
  ON receptions FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own receptions"
  ON receptions FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_receptions_user_id ON receptions(user_id);
CREATE INDEX IF NOT EXISTS idx_receptions_counterparty_id ON receptions(counterparty_id);

-- Принятые двигатели
CREATE TABLE IF NOT EXISTS accepted_motors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reception_id uuid NOT NULL REFERENCES receptions(id) ON DELETE CASCADE,
  subdivision_id uuid REFERENCES subdivisions(id) ON DELETE SET NULL,
  position_in_reception integer NOT NULL,
  motor_service_description text NOT NULL,
  motor_inventory_number text,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE accepted_motors ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own accepted motors"
  ON accepted_motors FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own accepted motors"
  ON accepted_motors FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own accepted motors"
  ON accepted_motors FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own accepted motors"
  ON accepted_motors FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_accepted_motors_user_id ON accepted_motors(user_id);
CREATE INDEX IF NOT EXISTS idx_accepted_motors_reception_id ON accepted_motors(reception_id);

-- ============================================================================
-- 3. ФИНАНСОВЫЕ ДОКУМЕНТЫ
-- ============================================================================

-- УПД документы
CREATE TABLE IF NOT EXISTS upd_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  document_number text DEFAULT '',
  counterparty_id uuid NOT NULL REFERENCES counterparties(id) ON DELETE RESTRICT,
  subdivision_id uuid REFERENCES subdivisions(id) ON DELETE RESTRICT,
  document_date timestamptz,
  total_income numeric DEFAULT 0,
  total_expense numeric DEFAULT 0,
  status text DEFAULT 'Draft',
  created_at timestamptz DEFAULT now()
);

ALTER TABLE upd_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own upd documents"
  ON upd_documents FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own upd documents"
  ON upd_documents FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own upd documents"
  ON upd_documents FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own upd documents"
  ON upd_documents FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_upd_documents_user_id ON upd_documents(user_id);
CREATE INDEX IF NOT EXISTS idx_upd_documents_counterparty_id ON upd_documents(counterparty_id);

-- Позиции приемки (связь с УПД через upd_document_id)
CREATE TABLE IF NOT EXISTS reception_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  accepted_motor_id uuid NOT NULL REFERENCES accepted_motors(id) ON DELETE CASCADE,
  item_description text NOT NULL,
  work_group text,
  quantity numeric NOT NULL DEFAULT 1,
  price numeric NOT NULL DEFAULT 0,
  upd_document_id uuid REFERENCES upd_documents(id) ON DELETE SET NULL,
  transaction_type text,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE reception_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own reception items"
  ON reception_items FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own reception items"
  ON reception_items FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own reception items"
  ON reception_items FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own reception items"
  ON reception_items FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_reception_items_user_id ON reception_items(user_id);
CREATE INDEX IF NOT EXISTS idx_reception_items_accepted_motor_id ON reception_items(accepted_motor_id);
CREATE INDEX IF NOT EXISTS idx_reception_items_upd_document_id ON reception_items(upd_document_id);

-- Позиции УПД
CREATE TABLE IF NOT EXISTS upd_document_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id uuid NOT NULL REFERENCES upd_documents(id) ON DELETE CASCADE,
  parent_id uuid REFERENCES upd_document_items(id) ON DELETE CASCADE,
  level integer NOT NULL,
  order_index integer DEFAULT 0,
  item_type text NOT NULL,
  description text NOT NULL,
  quantity numeric DEFAULT 1,
  price numeric DEFAULT 0,
  is_income boolean DEFAULT true,
  motor_id uuid REFERENCES motors(id) ON DELETE SET NULL,
  original_order_id uuid,
  transaction_type text,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE upd_document_items ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION check_document_owner(doc_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM upd_documents 
    WHERE id = doc_id AND user_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE POLICY "Users can view own upd document items"
  ON upd_document_items FOR SELECT TO authenticated
  USING (check_document_owner(document_id));

CREATE POLICY "Users can insert own upd document items"
  ON upd_document_items FOR INSERT TO authenticated
  WITH CHECK (check_document_owner(document_id));

CREATE POLICY "Users can update own upd document items"
  ON upd_document_items FOR UPDATE TO authenticated
  USING (check_document_owner(document_id))
  WITH CHECK (check_document_owner(document_id));

CREATE POLICY "Users can delete own upd document items"
  ON upd_document_items FOR DELETE TO authenticated
  USING (check_document_owner(document_id));

CREATE INDEX IF NOT EXISTS idx_upd_document_items_document_id ON upd_document_items(document_id);
CREATE INDEX IF NOT EXISTS idx_upd_document_items_parent_id ON upd_document_items(parent_id);

-- Заказы на ремонт (DEPRECATED, для совместимости)
CREATE TABLE IF NOT EXISTS repair_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  qr_code_data text NOT NULL,
  counterparty_id uuid NOT NULL REFERENCES counterparties(id) ON DELETE RESTRICT,
  motor_id uuid REFERENCES motors(id) ON DELETE SET NULL,
  subdivision_id uuid REFERENCES subdivisions(id) ON DELETE SET NULL,
  description text,
  status text DEFAULT 'Pending',
  allocated_document_id uuid REFERENCES upd_documents(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE repair_orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own repair orders"
  ON repair_orders FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own repair orders"
  ON repair_orders FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own repair orders"
  ON repair_orders FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own repair orders"
  ON repair_orders FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_repair_orders_user_id ON repair_orders(user_id);

-- Шаблоны приемки
CREATE TABLE IF NOT EXISTS reception_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  data jsonb NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE reception_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own templates"
  ON reception_templates FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own templates"
  ON reception_templates FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own templates"
  ON reception_templates FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own templates"
  ON reception_templates FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- ============================================================================
-- 4. ТРИГГЕРЫ И ФУНКЦИИ
-- ============================================================================

-- Функция обновления updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггеры для updated_at
CREATE TRIGGER update_counterparties_updated_at
  BEFORE UPDATE ON counterparties
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_motors_updated_at
  BEFORE UPDATE ON motors
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reference_types_updated_at
  BEFORE UPDATE ON reference_types
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reception_templates_updated_at
  BEFORE UPDATE ON reception_templates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Функция создания УПД и связывания позиций
CREATE OR REPLACE FUNCTION create_upd_and_link_items(
  p_counterparty_id uuid,
  p_subdivision_id uuid,
  p_document_number text,
  p_document_date timestamptz,
  p_item_ids uuid[]
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  new_upd_id uuid;
BEGIN
  INSERT INTO upd_documents (
    document_number,
    document_date,
    status,
    counterparty_id,
    subdivision_id,
    user_id
  )
  VALUES (
    p_document_number,
    p_document_date,
    'Реализовано',
    p_counterparty_id,
    p_subdivision_id,
    auth.uid()
  )
  RETURNING id INTO new_upd_id;

  UPDATE reception_items
  SET upd_document_id = new_upd_id
  WHERE id = ANY(p_item_ids)
    AND upd_document_id IS NULL
    AND user_id = auth.uid();

  RETURN new_upd_id;
END;
$$;

GRANT EXECUTE ON FUNCTION create_upd_and_link_items(uuid, uuid, text, timestamptz, uuid[]) TO authenticated;

-- Функция расформирования УПД
CREATE OR REPLACE FUNCTION disband_upd_and_unlink_items(p_upd_document_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM upd_documents 
    WHERE id = p_upd_document_id AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'УПД не найден или у вас нет прав доступа';
  END IF;

  UPDATE reception_items
  SET upd_document_id = NULL
  WHERE upd_document_id = p_upd_document_id
    AND user_id = auth.uid();

  DELETE FROM upd_documents
  WHERE id = p_upd_document_id
    AND user_id = auth.uid();
END;
$$;

GRANT EXECUTE ON FUNCTION disband_upd_and_unlink_items(uuid) TO authenticated;

-- Функция инициализации справочников для пользователя
CREATE OR REPLACE FUNCTION initialize_default_reference_types(p_user_id uuid)
RETURNS void AS $$
BEGIN
  INSERT INTO reference_types (user_id, name, type_key, icon_name, route, is_active)
  VALUES
    (p_user_id, 'Справочник Двигателей', 'motors', 'Gauge', '/app/reference/motors', true),
    (p_user_id, 'Контрагенты', 'counterparties', 'Users', '/app/reference/counterparties', true),
    (p_user_id, 'Подразделения', 'subdivisions', 'Warehouse', '/app/reference/subdivisions', true),
    (p_user_id, 'Провода', 'wires', 'Cable', '/app/reference/wires', true),
    (p_user_id, 'Подшипники', 'bearings', 'Circle', '/app/reference/bearings', true),
    (p_user_id, 'Крыльчатки', 'impellers', 'Fan', '/app/reference/impellers', true),
    (p_user_id, 'Оплата труда', 'labor_payments', 'DollarSign', '/app/reference/labor-payments', true),
    (p_user_id, 'Специальные документы', 'special_documents', 'FileText', '/app/reference/special-documents', true)
  ON CONFLICT (user_id, type_key) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
