-- Создаем базу данных
CREATE DATABASE MessengerAppDB;
GO

USE MessengerAppDB;
GO

-- =============================================
-- 1. Таблица Пользователей (Users)
-- Покрывает экраны: Вход, Регистрация, Настройки, Профиль
-- =============================================
CREATE TABLE Users (
    UserID INT PRIMARY KEY IDENTITY(1,1),
    
    -- Данные для входа (экран 1 и 2)
    Email NVARCHAR(100) NOT NULL UNIQUE,
    Password NVARCHAR(100) NOT NULL, -- Храним в открытом виде по вашему запросу
    
    -- Публичный профиль (экран 6 и 7)
    DisplayName NVARCHAR(100) NOT NULL, -- "Отображаемое имя"
    Username NVARCHAR(50) UNIQUE,       -- @username (из настроек)
    PhoneNumber NVARCHAR(20),           -- Телефон
    Bio NVARCHAR(500),                  -- Описание ("gjhrogriprgr")
    AvatarUrl NVARCHAR(MAX),            -- Ссылка на фото профиля
    
    -- Настройки приложения (экран 6)
    IsDarkMode BIT DEFAULT 0,           -- Dark Mode переключатель
    
    -- Статусы
    IsOnline BIT DEFAULT 0,             -- Для зеленой точки в списке чатов
    LastActive DATETIME2 DEFAULT GETDATE(),
    
    CreatedAt DATETIME2 DEFAULT GETDATE()
);

-- =============================================
-- 2. Таблица Контактов (Contacts/People)
-- Покрывает экран: People
-- =============================================
CREATE TABLE Contacts (
    ContactID INT PRIMARY KEY IDENTITY(1,1),
    OwnerUserID INT NOT NULL,  -- Чей это список контактов
    AddedUserID INT NOT NULL,  -- Кого добавили
    CustomName NVARCHAR(100),  -- Если пользователь переименовал друга у себя
    AddedAt DATETIME2 DEFAULT GETDATE(),
    
    FOREIGN KEY (OwnerUserID) REFERENCES Users(UserID),
    FOREIGN KEY (AddedUserID) REFERENCES Users(UserID),
    UNIQUE(OwnerUserID, AddedUserID) -- Чтобы не добавить одного человека дважды
);

-- =============================================
-- 3. Таблица Чатов (Chats)
-- Покрывает экраны: Список чатов, Создание группы
-- =============================================
CREATE TABLE Chats (
    ChatID INT PRIMARY KEY IDENTITY(1,1),
    
    -- Если это группа (экран "Создание группы")
    IsGroup BIT DEFAULT 0 NOT NULL,
    GroupName NVARCHAR(100) NULL, -- Название группы (только если IsGroup = 1)
    GroupAvatarUrl NVARCHAR(MAX) NULL,
    
    CreatedAt DATETIME2 DEFAULT GETDATE()
);

-- =============================================
-- 4. Участники чата (ChatParticipants)
-- Связывает юзеров и чаты. Нужна для экрана "Список чатов" и "Свайп"
-- =============================================
CREATE TABLE ChatParticipants (
    ChatID INT NOT NULL,
    UserID INT NOT NULL,
    
    -- Роли (например, для админа группы)
    Role NVARCHAR(20) DEFAULT 'Member', 
    
    -- Настройки чата для конкретного юзера (экран свайпа)
    IsMuted BIT DEFAULT 0,   -- Колокольчик (выключить уведомления)
    IsArchived BIT DEFAULT 0,-- Если чат скрыт
    
    -- Для счетчика непрочитанных сообщений (Blue dot)
    LastReadMessageID BIGINT DEFAULT 0, 
    
    JoinedAt DATETIME2 DEFAULT GETDATE(),
    
    PRIMARY KEY (ChatID, UserID),
    FOREIGN KEY (ChatID) REFERENCES Chats(ChatID) ON DELETE CASCADE,
    FOREIGN KEY (UserID) REFERENCES Users(UserID)
);

-- =============================================
-- 5. Сообщения (Messages)
-- Покрывает экраны переписки. Поддерживает текст, фото, аудио.
-- =============================================
CREATE TABLE Messages (
    MessageID BIGINT PRIMARY KEY IDENTITY(1,1),
    ChatID INT NOT NULL,
    SenderUserID INT NOT NULL,
    
    -- Тип сообщения (определяем, что рисовать: текст, картинку или плеер)
    MessageType NVARCHAR(20) NOT NULL CHECK (MessageType IN ('Text', 'Image', 'Audio', 'Sticker')),
    
    -- Контент сообщения
    ContentText NVARCHAR(MAX),  -- Текст сообщения (без шифрования)
    MediaUrl NVARCHAR(MAX),     -- Ссылка на файл (для Image/Audio)
    
    -- Метаданные
    SentAt DATETIME2 DEFAULT GETDATE(),
    IsDeleted BIT DEFAULT 0,    -- Если удалили ("мягкое" удаление)
    
    FOREIGN KEY (ChatID) REFERENCES Chats(ChatID) ON DELETE CASCADE,
    FOREIGN KEY (SenderUserID) REFERENCES Users(UserID)
);

-- Индексы для ускорения работы списка чатов и истории
CREATE INDEX IX_Messages_ChatID ON Messages(ChatID) INCLUDE (SentAt, MessageType);
CREATE INDEX IX_Participants_User ON ChatParticipants(UserID);