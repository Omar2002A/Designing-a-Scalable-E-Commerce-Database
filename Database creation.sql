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
