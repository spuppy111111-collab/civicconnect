# CivicConnect Backend API

This is the backend API for CivicConnect - a civic complaint management platform.

## Project Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── models/
│   │   ├── complaint.py
│   │   ├── user.py
│   │   └── notification.py
│   ├── routes/
│   │   ├── complaints.py
│   │   ├── users.py
│   │   ├── auth.py
│   │   └── admin.py
│   ├── schemas/
│   │   ├── complaint.py
│   │   ├── user.py
│   │   └── notification.py
│   ├── database/
│   │   ├── __init__.py
│   │   ├── session.py
│   │   └── config.py
│   ├── services/
│   │   ├── complaint_service.py
│   │   ├── user_service.py
│   │   ├── notification_service.py
│   │   └── email_service.py
│   ├── middleware/
│   │   ├── auth.py
│   │   └── error_handler.py
│   └── config.py
├── requirements.txt
├── .env.example
├── docker-compose.yml
└── README.md
```

## Setup Instructions

### Prerequisites
- Python 3.9+
- PostgreSQL
- Redis (for caching and real-time updates)

### Installation

1. Clone the repository
```bash
cd backend
```

2. Create virtual environment
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies
```bash
pip install -r requirements.txt
```

4. Create .env file
```bash
cp .env.example .env
```

5. Configure database
```bash
# Update .env with your database credentials
DATABASE_URL=postgresql://user:password@localhost:5432/civicconnect
```

6. Run migrations
```bash
alembic upgrade head
```

7. Start the server
```bash
uvicorn app.main:app --reload
```

The API will be available at `http://localhost:8000`

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new citizen
- `POST /api/auth/login` - Login
- `POST /api/auth/logout` - Logout
- `POST /api/auth/refresh` - Refresh token

### Complaints
- `GET /api/complaints` - Get user's complaints
- `POST /api/complaints` - Submit new complaint
- `GET /api/complaints/{id}` - Get complaint details
- `PATCH /api/complaints/{id}/status` - Update complaint status (Admin only)
- `GET /api/complaints/{id}/track` - Track complaint progress
- `GET /api/complaints/nearby` - Get nearby complaints
- `GET /api/complaints/statistics` - Get complaint statistics

### Users
- `GET /api/users/me` - Get current user profile
- `PATCH /api/users/me` - Update profile
- `GET /api/users/{id}/impact` - Get user's community impact

### Notifications
- `GET /api/notifications` - Get user notifications
- `PATCH /api/notifications/{id}/read` - Mark notification as read
- `DELETE /api/notifications/{id}` - Delete notification

## Database Schema

### Complaints Table
```sql
CREATE TABLE complaints (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  category VARCHAR(100) NOT NULL,
  status VARCHAR(50) NOT NULL,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  location_name VARCHAR(255),
  images JSONB,
  videos JSONB,
  voice_note VARCHAR(500),
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  resolved_at TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### Users Table
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  avatar_url VARCHAR(500),
  location VARCHAR(255),
  civic_level INTEGER DEFAULT 1,
  points INTEGER DEFAULT 0,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

### Notifications Table
```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  complaint_id UUID NOT NULL,
  type VARCHAR(50) NOT NULL,
  message TEXT NOT NULL,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (complaint_id) REFERENCES complaints(id)
);
```

## Environment Variables

```
DATABASE_URL=postgresql://user:password@localhost:5432/civicconnect
REDIS_URL=redis://localhost:6379
JWT_SECRET=your-secret-key
JWT_EXPIRATION=7d
MAIL_FROM=noreply@civicconnect.com
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
```

## Development

### Run tests
```bash
pytest
```

### Format code
```bash
black app/
```

### Lint code
```bash
pylint app/
```

## Deployment

The application is containerized with Docker. To run:

```bash
docker-compose up -d
```

This will start:
- PostgreSQL database
- Redis cache
- FastAPI application

## Documentation

Full API documentation available at `/docs` (Swagger UI)
ReDoc documentation at `/redoc`

## Contributing

1. Create feature branch
2. Make changes
3. Write tests
4. Submit pull request

## License

MIT
