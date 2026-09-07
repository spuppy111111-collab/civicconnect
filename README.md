# 🏙️ CivicConnect - Premium Citizen Dashboard

A **production-ready civic complaint management platform** featuring a premium, modern citizen dashboard for reporting and tracking civic issues with real-time updates and community impact metrics.

![CivicConnect Dashboard](./preview.png)

## 🌟 Features

### 🎨 Frontend Dashboard
- **Premium SaaS-quality UI** with glassmorphism effects
- **Real-time complaint tracking** with animated timeline
- **Beautiful hero background** with animated smart city landscape
- **Interactive statistics cards** with gradient designs
- **Quick action cards** for common tasks
- **Community impact metrics** and user level progression
- **Notification center** with real-time updates
- **Responsive design** (Desktop, Tablet, Mobile)
- **Smooth animations** with Framer Motion
- **Dark theme** optimized for modern interfaces

### 🔧 Technical Stack

**Frontend:**
- Next.js 14 (App Router)
- React 18
- TypeScript
- Tailwind CSS
- Framer Motion (Animations)
- Recharts (Analytics)
- Lucide React (Icons)

**Backend:**
- FastAPI (Python)
- PostgreSQL (Database)
- Redis (Caching & Real-time)
- JWT Authentication
- SQLAlchemy ORM

### ✨ Core Functionality

#### For Citizens:
✅ Submit civic complaints with photos/videos/audio
✅ Track complaint status in real-time
✅ View nearby complaints on interactive map
✅ Receive push notifications on updates
✅ View personal community impact
✅ Earn civic badges and level up
✅ Confirm problem resolution

#### For Admins:
✅ Review and verify complaints
✅ Assign to departments
✅ Update complaint status
✅ Manage user permissions
✅ View analytics dashboard
✅ Send notifications

---

## 🚀 Quick Start

### Prerequisites
- Node.js 18+ (Frontend)
- Python 3.9+ (Backend)
- PostgreSQL 14+
- Git

### Frontend Setup

```bash
# Navigate to project root
cd d:\full stack

# Install dependencies
npm install

# Create environment file
cp .env.local.example .env.local

# Start development server
npm run dev
```

Frontend will be available at: `http://localhost:3000`

### Backend Setup

```bash
# Create Python virtual environment
python -m venv venv

# Activate virtual environment
# On Windows:
venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Create .env file
cp .env.example .env

# Configure database in .env
# DATABASE_URL=postgresql://user:password@localhost:5432/civicconnect

# Run migrations (when using actual database)
# alembic upgrade head

# Start backend server
python -m uvicorn backend_api:app --reload
```

Backend API will be available at: `http://localhost:8000`
API Documentation: `http://localhost:8000/docs`

---

## 📁 Project Structure

```
d:\full stack/
├── src/
│   ├── app/
│   │   ├── layout.tsx          # Root layout
│   │   └── page.tsx             # Main dashboard page
│   ├── components/
│   │   ├── Sidebar.tsx          # Left navigation sidebar
│   │   ├── HeroBackground.tsx   # Animated city background
│   │   ├── StatisticsCards.tsx  # Complaint stats
│   │   ├── QuickActions.tsx     # Action buttons
│   │   ├── RecentComplaints.tsx # Complaints list
│   │   ├── TrackComplaint.tsx   # Progress timeline
│   │   ├── ActivityWidget.tsx   # Weekly activity chart
│   │   ├── CommunityImpact.tsx  # Impact metrics
│   │   ├── Notifications.tsx    # Notification center
│   │   ├── MobileNotificationPromo.tsx
│   │   └── TrustSection.tsx     # Why trust section
│   ├── services/
│   │   └── complaintService.ts  # API integration
│   └── styles/
│       └── globals.css          # Global styles
├── public/                       # Static assets
├── backend_api.py               # FastAPI application
├── package.json                 # Frontend dependencies
├── requirements.txt             # Backend dependencies
├── tailwind.config.js           # Tailwind CSS config
├── next.config.js               # Next.js config
├── tsconfig.json                # TypeScript config
├── .env.local.example           # Environment variables
├── BACKEND_README.md            # Backend documentation
└── README.md                    # This file
```

---

## 🔌 API Endpoints

### Complaints
```
GET    /api/complaints                 # Get user's complaints
POST   /api/complaints                 # Submit new complaint
GET    /api/complaints/{id}            # Get complaint details
GET    /api/complaints/{id}/track      # Track progress
GET    /api/complaints/nearby          # Get nearby issues
GET    /api/complaints/statistics      # Get statistics
PATCH  /api/complaints/{id}/status     # Update status (Admin)
```

### Users
```
GET    /api/users/me                   # Get profile
GET    /api/users/{id}/impact          # Get impact metrics
```

### Notifications
```
GET    /api/notifications              # Get notifications
PATCH  /api/notifications/{id}/read    # Mark as read
```

### Health
```
GET    /health                         # Health check
```

---

## 🎨 Design Highlights

### Color Palette
- **Primary Navy:** `#0F1A3C`
- **Dark Navy:** `#0A0E27`
- **Accent Blue:** `#3B82F6`
- **Accent Purple:** `#8B5CF6`
- **Accent Orange:** `#F97316`
- **Accent Green:** `#10B981`
- **Accent Yellow:** `#FBBF24`

### Typography
- **Headings:** Bold, Large (4-5xl)
- **Body:** Regular, Medium (sm-base)
- **Micro:** Small (xs)
- **Font:** System default (-apple-system, Roboto, etc.)

### Components
- **Glassmorphism:** Semi-transparent cards with backdrop blur
- **Animations:** Smooth transitions, hover effects
- **Shadows:** Glowing effects on interactive elements
- **Responsiveness:** Mobile-first design approach

---

## 🔐 Security Features

- **JWT Authentication** - Secure token-based auth
- **Password Hashing** - bcrypt with salt rounds
- **CORS Protection** - Configured for allowed origins
- **Input Validation** - Pydantic schemas
- **SQL Injection Prevention** - SQLAlchemy ORM
- **Rate Limiting** - Coming soon
- **HTTPS Only** - In production

---

## 📱 Responsive Design

### Desktop (1920px+)
- Three-column layout: Sidebar | Main | Widgets
- Full header navigation
- All features visible

### Tablet (768px - 1024px)
- Collapsible sidebar
- Two-column main layout
- Widgets below main content

### Mobile (< 768px)
- Hidden sidebar (hamburger menu)
- Single column layout
- Bottom navigation bar
- Optimized touch interactions

---

## 🎬 Animation System

Implemented with **Framer Motion**:
- Page load: Staggered fade-in and slide-up
- Cards: Hover scale and elevation
- Statistics: Number count-up animation
- Timeline: Sequential step animations
- Background: Subtle cloud and particle movement
- Buttons: Glow and scale on hover

---

## 🧪 Testing

### Frontend Tests (To be implemented)
```bash
npm run test
```

### Backend Tests
```bash
pytest
```

### E2E Tests (To be implemented)
```bash
npm run test:e2e
```

---

## 🚢 Deployment

### Frontend (Vercel/Netlify)
```bash
npm run build
vercel deploy
```

### Backend (Docker)
```bash
docker build -t civicconnect-api .
docker run -p 8000:8000 civicconnect-api
```

### Database (PostgreSQL)
- Host on AWS RDS, Google Cloud SQL, or self-hosted
- Run migrations on deployment
- Set up automated backups

---

## 📊 Database Schema

### Complaints
```sql
CREATE TABLE complaints (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  category VARCHAR(100),
  status VARCHAR(50),
  location VARCHAR(255),
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  images JSONB,
  videos JSONB,
  voice_note VARCHAR(500),
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### Users
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  location VARCHAR(255),
  civic_level INTEGER DEFAULT 1,
  points INTEGER DEFAULT 0,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

### Notifications
```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  complaint_id UUID NOT NULL,
  type VARCHAR(50),
  message TEXT,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (complaint_id) REFERENCES complaints(id)
);
```

---

## 🔄 Real-time Updates

Using **WebSocket** (via Redis):
- Live complaint status updates
- Real-time notifications
- Live notification count
- Activity feed streaming

```javascript
// Example WebSocket connection
const socket = new WebSocket('ws://localhost:8000/ws');

socket.onmessage = (event) => {
  const update = JSON.parse(event.data);
  // Handle real-time update
};
```

---

## 📧 Email Notifications

Using **SendGrid** or **SMTP**:
- Complaint confirmation
- Status updates
- Badge unlocked
- Community impact milestone
- Weekly summary

---

## 🎯 Development Roadmap

- [ ] Admin Dashboard
- [ ] Advanced filtering & search
- [ ] WebSocket real-time updates
- [ ] Email notifications
- [ ] SMS alerts
- [ ] Mobile app (React Native)
- [ ] AI-powered auto-categorization
- [ ] Predictive analytics
- [ ] Department assignment system
- [ ] Public complaint map
- [ ] Community voting system
- [ ] Gamification enhancements

---

## 🐛 Troubleshooting

### Frontend won't start
```bash
# Clear cache and reinstall
rm -rf node_modules package-lock.json
npm install
npm run dev
```

### Backend API errors
```bash
# Check virtual environment is activated
# Check DATABASE_URL is correct
# Check port 8000 is available
lsof -i :8000  # Check what's using port
```

### Database connection fails
```bash
# Verify PostgreSQL is running
# Check connection string in .env
# Test connection:
psql postgresql://user:password@localhost:5432/civicconnect
```

---

## 📚 Additional Resources

- [Next.js Documentation](https://nextjs.org/docs)
- [FastAPI Documentation](https://fastapi.tiangolo.com)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
- [Framer Motion Documentation](https://www.framer.com/motion/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

---

## 👥 Team

- **UI/UX Designer:** Premium dashboard design
- **Frontend Developer:** React, Next.js, TypeScript
- **Backend Developer:** FastAPI, Database design
- **DevOps:** Docker, Kubernetes deployment

---

## 📄 License

MIT License - Feel free to use this project for educational and commercial purposes.

---

## 💬 Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Contact: support@civicconnect.com
- Discord: [CivicConnect Community]

---

## 🙏 Acknowledgments

- FastAPI community
- Next.js team
- Design inspiration from modern SaaS platforms
- Open source contributors

---

**Made with ❤️ for building better cities**

⭐ If you find this project useful, please star the repository!
