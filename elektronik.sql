CREATE DATABASE elektronik;

USE elektronik;

-- buat tabel customers 
CREATE TABLE customers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nama VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(20)
);


CREATE INDEX idx_customers_nama ON customers(nama);
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_customers_phone ON customers(phone);

-- buat tabel products
CREATE TABLE products (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nama VARCHAR(100),
    price DECIMAL(10, 2),
    stock INT
);

CREATE INDEX idx_products_nama ON products(nama);

-- buat tabel orders
CREATE TABLE orders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT,
    order_date DATE,
    FOREIGN KEY (customer_id) REFERENCES customers(id)
);

CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_order_date ON orders(order_date);


-- buat tabel orders-items
CREATE TABLE order_items (
    id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    product_id INT,
    quantity INT,
    FOREIGN KEY (order_id) REFERENCES orders(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);

CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);

-- lakukan insert data ke database -------------------------------------------------------------------------------------------------------
-- customers
INSERT INTO customers (nama, email, phone) VALUES
('Alice Johnson', 'alice.johnson@example.com', '555-1234'),
('Bob Smith', 'bob.smith@example.com', '555-5678'),
('Charlie Brown', 'charlie.brown@example.com', '555-8765'),
('Diana Prince', 'diana.prince@example.com', '555-4321'),
('Edward Norton', 'edward.norton@example.com', '555-0000');

-- products
INSERT INTO products (nama, price, stock) VALUES
('Laptop', 1500.00, 20),
('Smartphone', 700.00, 50),
('Tablet', 300.00, 30),
('Monitor', 200.00, 15),
('Keyboard', 50.00, 100),
('Mouse', 25.00, 200),
('Printer', 150.00, 10),
('Scanner', 120.00, 5),
('External Hard Drive', 80.00, 40),
('Webcam', 45.00, 25);

-- orders
INSERT INTO orders (customer_id, order_date) VALUES
(1, '2024-01-15'),
(2, '2024-01-20'),
(3, '2024-02-10'),
(4, '2024-03-05'),
(5, '2024-03-15'),
(1, '2024-06-23'),
(2, '2024-06-24'),
(1, '2024-06-25'),
(3, '2024-06-26'),
(2, '2024-06-27');

-- order_items
INSERT INTO order_items (order_id, product_id, quantity) VALUES
(1, 1, 2),
(1, 2, 1),
(1, 3, 3),
(1, 4, 1),
(1, 5, 2),
(1, 6, 1),

(2, 2, 1),
(2, 3, 2),
(2, 4, 1),
(2, 5, 1),

(3, 1, 1),
(3, 3, 1),
(3, 4, 1),

(4, 2, 2),
(4, 3, 1),
(4, 4, 1),
(4, 5, 1),

(5, 1, 2),
(5, 2, 1),
(5, 6, 1);

-- membuat trigger -------------------------------------------------------------------------------------------------------
-- ketika melakukan insert ke order_items, maka kurangi stok sesuai kuantitas yang diambil
DELIMITER $$
CREATE
    /*[DEFINER = { user | CURRENT_USER }]*/
    TRIGGER `elektronik`.`trg_order_items_insert` BEFORE INSERT
    ON `elektronik`.`order_items`
    FOR EACH ROW BEGIN
    UPDATE products
    SET stock = stock - NEW.quantity
    WHERE id = NEW.product_id;
    END$$

DELIMITER ;

-- ketika melakukan update ke order_items, maka kurangi stok sesuai selisih kuantitas
DELIMITER$$
CREATE TRIGGER trg_order_items_update
AFTER UPDATE ON order_items
FOR EACH ROW
BEGIN
    DECLARE qty_diff INT;
    SET qty_diff = NEW.quantity - OLD.quantity;
    UPDATE products
    SET stock = stock - qty_diff
    WHERE id = NEW.product_id;
END$$
DELIMITER

-- ketika melakukan delete ke order_items, maka kembalikan stok sesuai kuantitas yang diambil
DELIMITER$$
CREATE TRIGGER trg_order_items_delete
AFTER DELETE ON order_items
FOR EACH ROW
BEGIN
    UPDATE products
    SET stock = stock + OLD.quantity
    WHERE id = OLD.product_id;
END$$
DELIMITER

-- buat view ---------------------------------------------------------------------------------------------------------
-- view akan menampilkan total transaksi yang dilakukan pelanggan berdasarkan orders
CREATE VIEW order_transactions AS
SELECT 
    o.id AS order_id,
    o.customer_id,
    c.nama AS customer_name,
    o.order_date,
    SUM(oi.quantity * p.price) AS total_transaction_amount
FROM 
    orders o
LEFT JOIN 
    customers c ON o.customer_id = c.id
LEFT JOIN 
    order_items oi ON o.id = oi.order_id
LEFT JOIN 
    products p ON oi.product_id = p.id
GROUP BY 
    o.id, o.customer_id, c.nama, o.order_date;

-- view untuk menampikan transaksi yang data transaksi yang dilakukan customers ketika dalam sebuah orders memiliki 5 order_items
CREATE VIEW customer_orders_with_items AS
SELECT 
    c.id AS customer_id,
    c.nama AS customer_name,
    o.id AS order_id,
    o.order_date
FROM 
    customers c
INNER JOIN 
    orders o ON c.id = o.customer_id
WHERE 
    o.id IN (
	SELECT order_id FROM order_items GROUP BY order_id HAVING COUNT(*) >= 5
    );

-- mencari data ------------------------------------------------------------------------------
-- mencari semua data order ketika order berdasarkan nama pelanggan
SELECT 
    o.id AS order_id,
    o.customer_id,
    c.nama AS customer_name,
    o.order_date
FROM 
    orders o
JOIN 
    customers c ON o.customer_id = c.id
WHERE 
    c.nama LIKE '%nama%';