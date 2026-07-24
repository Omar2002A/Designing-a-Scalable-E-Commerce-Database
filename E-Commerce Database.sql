IF DB_ID('DesigningAScalableECommerce') IS NULL
BEGIN
	CREATE DATABASE DesigningAScalableECommerce;
END;

USE DesigningAScalableECommerce;

CREATE TABLE Users
(
    UserID INT IDENTITY(1,1),

    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(150) NOT NULL,
    PasswordHash NVARCHAR(255) NOT NULL,
    Phone NVARCHAR(20) NULL,

    IsActive BIT NOT NULL
        CONSTRAINT DF_Users_IsActive DEFAULT 1,

    IsDeleted BIT NOT NULL
        CONSTRAINT DF_Users_IsDeleted DEFAULT 0,

    CreatedAt DATETIME2(0) NOT NULL
        CONSTRAINT DF_Users_CreatedAt DEFAULT GETDATE(),

    UpdatedAt DATETIME2(0) NULL,

    CONSTRAINT PK_Users
        PRIMARY KEY (UserID),

    CONSTRAINT UQ_Users_Email
        UNIQUE (Email)
);

CREATE TABLE Addresses
(
    AddressID INT IDENTITY(1,1),
    UserID INT NOT NULL,

    AddressType NVARCHAR(20) NOT NULL,
    Country NVARCHAR(50) NOT NULL,
    City NVARCHAR(50) NOT NULL,
    Street NVARCHAR(150) NOT NULL,
    PostalCode NVARCHAR(20) NULL,

    IsDefault BIT NOT NULL
        CONSTRAINT DF_Addresses_IsDefault DEFAULT 0,

    IsDeleted BIT NOT NULL
        CONSTRAINT DF_Addresses_IsDeleted DEFAULT 0,

    CreatedAt DATETIME2(0) NOT NULL
        CONSTRAINT DF_Addresses_CreatedAt DEFAULT GETDATE(),

    UpdatedAt DATETIME2(0) NULL,

    CONSTRAINT PK_Addresses
        PRIMARY KEY (AddressID),

    CONSTRAINT FK_Addresses_Users
        FOREIGN KEY (UserID)
        REFERENCES Users(UserID),

    CONSTRAINT UQ_Addresses_UserAddress
        UNIQUE (UserID, AddressID),

    CONSTRAINT CK_Addresses_AddressType
        CHECK (AddressType IN ('Home', 'Work', 'Other'))
);

CREATE TABLE Categories
(
    CategoryID INT IDENTITY(1,1),

    CategoryName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500) NULL,

    IsDeleted BIT NOT NULL
        CONSTRAINT DF_Categories_IsDeleted DEFAULT 0,

    CreatedAt DATETIME2(0) NOT NULL
        CONSTRAINT DF_Categories_CreatedAt DEFAULT GETDATE(),

    UpdatedAt DATETIME2(0) NULL,

    CONSTRAINT PK_Categories
        PRIMARY KEY (CategoryID),

    CONSTRAINT UQ_Categories_CategoryName
        UNIQUE (CategoryName)
);

CREATE TABLE Products
(
    ProductID INT IDENTITY(1,1),
    CategoryID INT NOT NULL,

    ProductName NVARCHAR(150) NOT NULL,
    SKU NVARCHAR(50) NOT NULL,
    Description NVARCHAR(1000) NULL,

    Price DECIMAL(10,2) NOT NULL,
    StockQuantity INT NOT NULL,

    IsAvailable BIT NOT NULL
        CONSTRAINT DF_Products_IsAvailable DEFAULT 1,

    IsDeleted BIT NOT NULL
        CONSTRAINT DF_Products_IsDeleted DEFAULT 0,

    CreatedAt DATETIME2(0) NOT NULL
        CONSTRAINT DF_Products_CreatedAt DEFAULT GETDATE(),

    UpdatedAt DATETIME2(0) NULL,

    CONSTRAINT PK_Products
        PRIMARY KEY (ProductID),

    CONSTRAINT FK_Products_Categories
        FOREIGN KEY (CategoryID)
        REFERENCES Categories(CategoryID),

    CONSTRAINT UQ_Products_SKU
        UNIQUE (SKU),

    CONSTRAINT CK_Products_Price
        CHECK (Price >= 0),

    CONSTRAINT CK_Products_StockQuantity
        CHECK (StockQuantity >= 0)
);

CREATE TABLE Orders
(
    OrderID INT IDENTITY(1,1),

    OrderNumber NVARCHAR(30) NOT NULL,
    UserID INT NOT NULL,
    ShippingAddressID INT NOT NULL,

    OrderDate DATETIME2(0) NOT NULL
        CONSTRAINT DF_Orders_OrderDate DEFAULT GETDATE(),

    OrderStatus NVARCHAR(20) NOT NULL
        CONSTRAINT DF_Orders_OrderStatus DEFAULT 'Pending',

    Subtotal DECIMAL(12,2) NOT NULL,
    ShippingFee DECIMAL(12,2) NOT NULL
        CONSTRAINT DF_Orders_ShippingFee DEFAULT 0,

    TotalAmount DECIMAL(12,2) NOT NULL,

    IsDeleted BIT NOT NULL
        CONSTRAINT DF_Orders_IsDeleted DEFAULT 0,

    CreatedAt DATETIME2(0) NOT NULL
        CONSTRAINT DF_Orders_CreatedAt DEFAULT GETDATE(),

    UpdatedAt DATETIME2(0) NULL,

    CONSTRAINT PK_Orders
        PRIMARY KEY (OrderID),

    CONSTRAINT UQ_Orders_OrderNumber
        UNIQUE (OrderNumber),

    CONSTRAINT FK_Orders_Users
        FOREIGN KEY (UserID)
        REFERENCES Users(UserID),

    CONSTRAINT FK_Orders_UserAddress
        FOREIGN KEY (ShippingAddressID)
        REFERENCES Addresses(AddressID),

    CONSTRAINT CK_Orders_Status
        CHECK
        (
            OrderStatus IN
            (
                'Pending',
                'Paid',
                'Processing',
                'Shipped',
                'Delivered',
                'Cancelled'
            )
        ),

    CONSTRAINT CK_Orders_Subtotal
        CHECK (Subtotal >= 0),

    CONSTRAINT CK_Orders_ShippingFee
        CHECK (ShippingFee >= 0),

    CONSTRAINT CK_Orders_TotalAmount
        CHECK (TotalAmount = Subtotal + ShippingFee)
);

CREATE TABLE OrderItems
(
    OrderItemID INT IDENTITY(1,1),

    OrderID INT NOT NULL,
    ProductID INT NOT NULL,

    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,

    LineTotal AS (Quantity * UnitPrice) PERSISTED,

    IsDeleted BIT NOT NULL
        CONSTRAINT DF_OrderItems_IsDeleted DEFAULT 0,

    CreatedAt DATETIME2(0) NOT NULL
        CONSTRAINT DF_OrderItems_CreatedAt DEFAULT GETDATE(),

    UpdatedAt DATETIME2(0) NULL,

    CONSTRAINT PK_OrderItems
        PRIMARY KEY (OrderItemID),

    CONSTRAINT FK_OrderItems_Orders
        FOREIGN KEY (OrderID)
        REFERENCES Orders(OrderID),

    CONSTRAINT FK_OrderItems_Products
        FOREIGN KEY (ProductID)
        REFERENCES Products(ProductID),

    CONSTRAINT UQ_OrderItems_OrderProduct
        UNIQUE (OrderID, ProductID),

    CONSTRAINT CK_OrderItems_Quantity
        CHECK (Quantity > 0),

    CONSTRAINT CK_OrderItems_UnitPrice
        CHECK (UnitPrice >= 0)
);

CREATE TABLE Payments
(
    PaymentID INT IDENTITY(1,1),
    OrderID INT NOT NULL,

    PaymentDate DATETIME2(0) NOT NULL
        CONSTRAINT DF_Payments_PaymentDate DEFAULT GETDATE(),

    Amount DECIMAL(12,2) NOT NULL,
    PaymentMethod NVARCHAR(20) NOT NULL,
    PaymentStatus NVARCHAR(20) NOT NULL,

    TransactionReference NVARCHAR(100) NOT NULL,

    IsDeleted BIT NOT NULL
        CONSTRAINT DF_Payments_IsDeleted DEFAULT 0,

    CreatedAt DATETIME2(0) NOT NULL
        CONSTRAINT DF_Payments_CreatedAt DEFAULT GETDATE(),

    UpdatedAt DATETIME2(0) NULL,

    CONSTRAINT PK_Payments
        PRIMARY KEY (PaymentID),

    CONSTRAINT FK_Payments_Orders
        FOREIGN KEY (OrderID)
        REFERENCES Orders(OrderID),

    CONSTRAINT UQ_Payments_OrderID
        UNIQUE (OrderID),

    CONSTRAINT UQ_Payments_TransactionReference
        UNIQUE (TransactionReference),

    CONSTRAINT CK_Payments_Amount
        CHECK (Amount > 0),

    CONSTRAINT CK_Payments_Method
        CHECK
        (
            PaymentMethod IN
            (
                'Cash',
                'Card',
                'PayPal',
                'Wallet'
            )
        ),

    CONSTRAINT CK_Payments_Status
        CHECK
        (
            PaymentStatus IN
            (
                'Pending',
                'Completed',
                'Failed',
                'Refunded'
            )
        )
);

CREATE TABLE Reviews
(
    ReviewID INT IDENTITY(1,1),

    UserID INT NOT NULL,
    ProductID INT NOT NULL,

    Rating TINYINT NOT NULL,
    ReviewComment NVARCHAR(1000) NULL,

    IsDeleted BIT NOT NULL
        CONSTRAINT DF_Reviews_IsDeleted DEFAULT 0,

    CreatedAt DATETIME2(0) NOT NULL
        CONSTRAINT DF_Reviews_CreatedAt DEFAULT GETDATE(),

    UpdatedAt DATETIME2(0) NULL,

    CONSTRAINT PK_Reviews
        PRIMARY KEY (ReviewID),

    CONSTRAINT FK_Reviews_Users
        FOREIGN KEY (UserID)
        REFERENCES Users(UserID),

    CONSTRAINT FK_Reviews_Products
        FOREIGN KEY (ProductID)
        REFERENCES Products(ProductID),

    CONSTRAINT UQ_Reviews_UserProduct
        UNIQUE (UserID, ProductID),

    CONSTRAINT CK_Reviews_Rating
        CHECK (Rating BETWEEN 1 AND 5)
);

CREATE TABLE Wishlists
(
    WishlistID INT IDENTITY(1,1),

    UserID INT NOT NULL,

    WishlistName NVARCHAR(100) NOT NULL
        CONSTRAINT DF_Wishlists_Name DEFAULT 'My Wishlist',

    IsDeleted BIT NOT NULL
        CONSTRAINT DF_Wishlists_IsDeleted DEFAULT 0,

    CreatedAt DATETIME2(0) NOT NULL
        CONSTRAINT DF_Wishlists_CreatedAt DEFAULT GETDATE(),

    UpdatedAt DATETIME2(0) NULL,

    CONSTRAINT PK_Wishlists
        PRIMARY KEY (WishlistID),

    CONSTRAINT FK_Wishlists_Users
        FOREIGN KEY (UserID)
        REFERENCES Users(UserID),

    CONSTRAINT UQ_Wishlists_UserID
        UNIQUE (UserID)
);

CREATE TABLE WishlistItems
(
    WishlistItemID INT IDENTITY(1,1),

    WishlistID INT NOT NULL,
    ProductID INT NOT NULL,

    IsDeleted BIT NOT NULL
        CONSTRAINT DF_WishlistItems_IsDeleted DEFAULT 0,

    CreatedAt DATETIME2(0) NOT NULL
        CONSTRAINT DF_WishlistItems_CreatedAt DEFAULT GETDATE(),

    UpdatedAt DATETIME2(0) NULL,

    CONSTRAINT PK_WishlistItems
        PRIMARY KEY (WishlistItemID),

    CONSTRAINT FK_WishlistItems_Wishlists
        FOREIGN KEY (WishlistID)
        REFERENCES Wishlists(WishlistID),

    CONSTRAINT FK_WishlistItems_Products
        FOREIGN KEY (ProductID)
        REFERENCES Products(ProductID),

    CONSTRAINT UQ_WishlistItems_WishlistProduct
        UNIQUE (WishlistID, ProductID)
);

INSERT INTO Users
(
    FirstName,
    LastName,
    Email,
    PasswordHash,
    Phone
)
VALUES
('Omar',  'Meshref',  'omar@example.com',  'HASHED_PASSWORD_1', '0791111111'),
('Sara',  'Ahmad',    'sara@example.com',  'HASHED_PASSWORD_2', '0792222222'),
('Ahmad', 'Ali',      'ahmad@example.com', 'HASHED_PASSWORD_3', '0793333333'),
('Lina',  'Khaled',   'lina@example.com',  'HASHED_PASSWORD_4', '0794444444'),
('Yousef','Mohammad', 'yousef@example.com','HASHED_PASSWORD_5', '0795555555');

INSERT INTO Addresses
(
    UserID,
    AddressType,
    Country,
    City,
    Street,
    PostalCode,
    IsDefault
)
VALUES
(1, 'Home', 'Jordan', 'Amman',  'University Street', '11181', 1),
(2, 'Home', 'Jordan', 'Irbid',  'Wasfi Al-Tal Street', '21110', 1),
(3, 'Work', 'Jordan', 'Amman',  'Mecca Street', '11185', 1),
(4, 'Home', 'Jordan', 'Zarqa',  'King Hussein Street', '13110', 1),
(5, 'Home', 'Jordan', 'Tafila', 'Downtown Tafila', '66110', 1);

INSERT INTO Categories
(
    CategoryName,
    Description
)
VALUES
('Electronics', 'Electronic devices and computer accessories'),
('Sports',      'Sports and fitness products'),
('Home',        'Home and kitchen products'),
('Books',       'Educational and general books'),
('Fashion',     'Clothing, bags and fashion accessories');

INSERT INTO Products
(
    CategoryID,
    ProductName,
    SKU,
    Description,
    Price,
    StockQuantity
)
VALUES
(1, 'Wireless Mouse',      'ELEC-001', 'Wireless optical computer mouse', 18.50, 40),
(1, 'Mechanical Keyboard', 'ELEC-002', 'Mechanical keyboard with RGB lighting', 55.00, 20),
(1, 'Laptop Stand',        'ELEC-003', 'Adjustable aluminum laptop stand', 32.75, 0),
(1, 'USB-C Hub',           'ELEC-004', 'Multi-port USB-C hub', 45.90, 15),
(2, 'Running Shoes',       'SPRT-001', 'Lightweight running shoes', 70.00, 12),
(3, 'Coffee Maker',        'HOME-001', 'Automatic coffee maker', 89.99, 8),
(4, 'SQL Fundamentals',    'BOOK-001', 'Introduction to SQL and databases', 24.50, 30),
(1, 'Smart Watch',         'ELEC-005', 'Smart fitness watch', 120.00, 10),
(5, 'Travel Backpack',     'FASH-001', 'Water-resistant travel backpack', 39.99, 25),
(2, 'Yoga Mat',            'SPRT-002', 'Non-slip yoga mat', 22.00, 18);

INSERT INTO Orders
(
    OrderNumber,
    UserID,
    ShippingAddressID,
    OrderDate,
    OrderStatus,
    Subtotal,
    ShippingFee,
    TotalAmount
)
VALUES
(
    'ORD-2026-001',
    1,
    1,
    DATEADD(DAY, -20, GETDATE()),
    'Delivered',
    61.50,
    12.50,
    74.00
),
(
    'ORD-2026-002',
    2,
    2,
    DATEADD(DAY, -15, GETDATE()),
    'Delivered',
    89.99,
    7.50,
    97.49
),
(
    'ORD-2026-003',
    1,
    1,
    DATEADD(DAY, -10, GETDATE()),
    'Shipped',
    100.90,
    0.00,
    100.90
),
(
    'ORD-2026-004',
    3,
    3,
    DATEADD(DAY, -7, GETDATE()),
    'Paid',
    92.00,
    5.00,
    97.00
),
(
    'ORD-2026-005',
    4,
    4,
    DATEADD(DAY, -3, GETDATE()),
    'Pending',
    64.49,
    6.00,
    70.49
),
(
    'ORD-2026-006',
    5,
    5,
    DATEADD(DAY, -1, GETDATE()),
    'Processing',
    51.25,
    6.50,
    57.75
);

INSERT INTO OrderItems
(
    OrderID,
    ProductID,
    Quantity,
    UnitPrice
)
VALUES
(1, 1, 2, 18.50),
(1, 7, 1, 24.50),

(2, 6, 1, 89.99),

(3, 2, 1, 55.00),
(3, 4, 1, 45.90),

(4, 5, 1, 70.00),
(4, 10, 1, 22.00),

(5, 9, 1, 39.99),
(5, 7, 1, 24.50),

(6, 1, 1, 18.50),
(6, 3, 1, 32.75);

INSERT INTO Payments
(
    OrderID,
    PaymentDate,
    Amount,
    PaymentMethod,
    PaymentStatus,
    TransactionReference
)
VALUES
(
    1,
    DATEADD(DAY, -20, GETDATE()),
    74.00,
    'Card',
    'Completed',
    'TXN-100001'
),
(
    2,
    DATEADD(DAY, -15, GETDATE()),
    97.49,
    'Cash',
    'Completed',
    'TXN-100002'
),
(
    3,
    DATEADD(DAY, -10, GETDATE()),
    100.90,
    'Card',
    'Completed',
    'TXN-100003'
),
(
    4,
    DATEADD(DAY, -7, GETDATE()),
    97.00,
    'Wallet',
    'Completed',
    'TXN-100004'
),
(
    6,
    DATEADD(DAY, -1, GETDATE()),
    57.75,
    'Card',
    'Completed',
    'TXN-100006'
);

INSERT INTO Reviews
(
    UserID,
    ProductID,
    Rating,
    ReviewComment
)
VALUES
(1, 1, 5, 'Excellent mouse and very comfortable.'),
(1, 7, 4, 'A useful book for SQL beginners.'),
(2, 6, 4, 'Good coffee maker and easy to use.'),
(3, 5, 5, 'Very comfortable running shoes.'),
(4, 7, 5, 'Clear explanations and useful examples.'),
(5, 1, 4, 'Good quality for the price.'),
(2, 2, 5, 'The keyboard feels great when typing.');

INSERT INTO Wishlists
(
    UserID,
    WishlistName
)
VALUES
(1, 'Omar Wishlist'),
(2, 'Sara Wishlist'),
(3, 'Ahmad Wishlist'),
(4, 'Lina Wishlist'),
(5, 'Yousef Wishlist');

INSERT INTO WishlistItems
(
    WishlistID,
    ProductID
)
VALUES
(1, 5),
(1, 6),
(1, 8),
(2, 2),
(2, 9),
(3, 1),
(3, 7),
(4, 4),
(4, 10),
(5, 2),
(5, 6);

-- Update 

UPDATE Products
SET
    Price = 59.99,
    UpdatedAt = GETDATE()
WHERE ProductID = 2;

-- Soft Delete

UPDATE Products
SET
    IsDeleted = 1,
    IsAvailable = 0,
    UpdatedAt = GETDATE()
WHERE ProductID = 8;

-- Orders Overview

SELECT O.OrderID,O.OrderNumber, CONCAT(U.FirstName, ' ',U.LastName) AS CustomerName,
       U.Email, U.Phone, O.OrderDate, O.OrderStatus, O.Subtotal, O.ShippingFee, O.TotalAmount,
       COALESCE(p.PaymentMethod, 'No Payment') AS PaymentMethod, COALESCE(P.PaymentStatus, 'Not Paid') AS PaymentStatus

FROM Orders AS O

INNER JOIN Users AS U
    ON O.OrderID = U.UserID

LEFT JOIN Payments AS P
    ON O.OrderID = P.OrderID
    AND P.IsDeleted = 0

WHERE 
    O.IsDeleted = 0
    AND U.IsDeleted = 0

ORDER BY O.OrderDate DESC;


-- Product Listing

SELECT P.ProductID, P.ProductName, P.SKU, C.CategoryName, P.Price, P.StockQuantity
FROM Products AS P

INNER JOIN Categories AS C
    ON P.CategoryID = C.CategoryID

WHERE 
    P.IsDeleted = 0
    AND IsAvailable = 1
    AND P.StockQuantity > 0
    AND C.IsDeleted = 0

ORDER BY P.Price ASC

OFFSET 0 ROWS
FETCH NEXT 5 ROWS ONLY;

SELECT P.ProductID, P.ProductName, P.SKU, C.CategoryName, P.Price, P.StockQuantity
FROM Products AS P

INNER JOIN Categories AS C
    ON P.CategoryID = C.CategoryID

WHERE 
    P.IsDeleted = 0
    AND IsAvailable = 1
    AND P.StockQuantity > 0
    AND C.IsDeleted = 0

ORDER BY P.Price ASC

OFFSET 5 ROWS
FETCH NEXT 5 ROWS ONLY;

-- Product Ratings

SELECT P.ProductID, P.ProductName,
       CAST(COALESCE(AVG(CAST(R.Rating AS DECIMAL(10,2))),0)AS DECIMAL(10,2)) AS AverageRating,
       COUNT(R.ReviewID) AS TotalReviews

FROM Products AS P

LEFT JOIN Reviews AS R 
    ON P.ProductID = R.ProductID
    AND R.IsDeleted = 0

WHERE P.IsDeleted = 0

GROUP BY 
    P.ProductID,
    P.ProductName

ORDER BY 
    AverageRating DESC,
    TotalReviews DESC;


-- Wishlist

SELECT U.UserID, CONCAT(U.FirstName, ' ', U.LastName) AS CustomerName,
       W.WishlistName, P.ProductID, P.ProductName,
       C.CategoryName, P.Price, WI.CreatedAt AS AddedToWishlistAt
       

FROM Users AS U

INNER JOIN Wishlists AS W 
    ON U.UserID = W.UserID

INNER JOIN WishlistItems AS WI
    ON W.WishlistID = WI.WishlistID

INNER JOIN Products AS P
    ON WI.ProductID = P.ProductID

INNER JOIN Categories AS C
    ON P.CategoryID = C.CategoryID

WHERE 
    U.UserID = 1
    AND U.IsDeleted = 0
    AND W.IsDeleted = 0
    AND WI.IsDeleted = 0
    AND P.IsDeleted = 0
    AND C.IsDeleted = 0

ORDER BY WI.CreatedAt DESC;

-- Sales Analysis

SELECT U.UserID,CONCAT(U.FirstName, ' ', U.LastName) AS CustomerName,
       COUNT(P.PaymentID) AS PaidOrders, COALESCE(SUM(P.Amount),0) AS TotalSales

FROM Users AS U

LEFT JOIN Orders AS O
    ON U.UserID = O.UserID
    AND O.IsDeleted = 0

LEFT JOIN Payments AS P
    ON O.OrderID = P.OrderID
    AND P.PaymentStatus = 'Completed'
    AND P.IsDeleted = 0

WHERE U.IsDeleted = 0

GROUP BY
    U.UserID,
    U.FirstName,
    U.LastName

ORDER BY TotalSales DESC;

-- Filtering

SELECT P.ProductID, P.ProductName, C.CategoryName, P.Price, P.StockQuantity

FROM Products AS P

INNER JOIN Categories AS C
    ON P.CategoryID = C.CategoryID

WHERE
    P.IsDeleted = 0
    AND P.IsAvailable = 1
    AND P.Price BETWEEN 20.00 AND 60.00

ORDER BY P.Price ASC;

-- Recent Orders

SELECT TOP 5 O.OrderID, O.OrderNumber, CONCAT(U.FirstName, ' ', U.LastName) AS CustomerName,
           O.OrderDate, O.OrderStatus, O.TotalAmount

FROM Orders AS O

INNER JOIN Users AS U
    ON O.UserID = U.UserID

WHERE
    O.IsDeleted = 0
    AND U.IsDeleted = 0

ORDER BY O.OrderDate DESC;