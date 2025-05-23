/*
  # Initial Schema for TRUE IPHONES System

  1. New Tables
    - `users` - System users (staff and admin)
      - `id` (uuid, primary key)
      - `email` (text, unique)
      - `full_name` (text)
      - `role` (text)
      - `created_at` (timestamp)
    
    - `customers` - Customer information
      - `id` (uuid, primary key)
      - `full_name` (text)
      - `email` (text)
      - `phone` (text)
      - `created_at` (timestamp)
      - `created_by` (uuid, references users)
    
    - `products` - Product catalog
      - `id` (uuid, primary key)
      - `name` (text)
      - `description` (text)
      - `code` (text)
      - `default_price` (numeric)
      - `created_at` (timestamp)
      - `created_by` (uuid, references users)
    
    - `receipts` - Sales receipts
      - `id` (uuid, primary key)
      - `customer_id` (uuid, references customers)
      - `total_amount` (numeric)
      - `payment_method` (text)
      - `installments` (integer)
      - `installment_value` (numeric)
      - `created_at` (timestamp)
      - `created_by` (uuid, references users)
    
    - `receipt_items` - Items in each receipt
      - `id` (uuid, primary key)
      - `receipt_id` (uuid, references receipts)
      - `product_id` (uuid, references products)
      - `quantity` (integer)
      - `price` (numeric)
    
    - `warranties` - Warranty information
      - `id` (uuid, primary key)
      - `receipt_id` (uuid, references receipts)
      - `duration_months` (integer)
      - `expires_at` (timestamp)
      - `created_at` (timestamp)
      - `created_by` (uuid, references users)

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users based on role
*/

-- Users table
CREATE TABLE users (
  id uuid PRIMARY KEY DEFAULT auth.uid(),
  email text UNIQUE NOT NULL,
  full_name text NOT NULL,
  role text NOT NULL CHECK (role IN ('admin', 'staff')),
  created_at timestamptz DEFAULT now()
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own data"
  ON users
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Customers table
CREATE TABLE customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name text NOT NULL,
  email text,
  phone text,
  created_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES users(id) NOT NULL
);

ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can read customers"
  ON customers
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Staff can insert customers"
  ON customers
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Products table
CREATE TABLE products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  code text,
  default_price numeric NOT NULL CHECK (default_price >= 0),
  created_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES users(id) NOT NULL
);

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can read products"
  ON products
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admin can manage products"
  ON products
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Receipts table
CREATE TABLE receipts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id uuid REFERENCES customers(id) NOT NULL,
  total_amount numeric NOT NULL CHECK (total_amount >= 0),
  payment_method text NOT NULL,
  installments integer NOT NULL DEFAULT 1,
  installment_value numeric,
  created_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES users(id) NOT NULL
);

ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can read receipts"
  ON receipts
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Staff can create receipts"
  ON receipts
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Receipt items table
CREATE TABLE receipt_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  receipt_id uuid REFERENCES receipts(id) NOT NULL,
  product_id uuid REFERENCES products(id) NOT NULL,
  quantity integer NOT NULL CHECK (quantity > 0),
  price numeric NOT NULL CHECK (price >= 0)
);

ALTER TABLE receipt_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can read receipt items"
  ON receipt_items
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Staff can create receipt items"
  ON receipt_items
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Warranties table
CREATE TABLE warranties (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  receipt_id uuid REFERENCES receipts(id) NOT NULL,
  duration_months integer NOT NULL CHECK (duration_months > 0),
  expires_at timestamptz NOT NULL,
  created_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES users(id) NOT NULL
);

ALTER TABLE warranties ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can read warranties"
  ON warranties
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Staff can create warranties"
  ON warranties
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Create indexes for better performance
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_customers_phone ON customers(phone);
CREATE INDEX idx_products_code ON products(code);
CREATE INDEX idx_warranties_expires_at ON warranties(expires_at);