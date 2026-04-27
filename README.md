# Help Kin Map - Карта взаємодопомоги для українців

Progressive Web App для української діаспори та родин/друзів, розділених міграцією через війну. Платформа для взаємодопомоги: користувачі бачать родичів та друзів на карті світу, діляться тим, яку допомогу можуть запропонувати, і створюють запити на допомогу.

## 🌟 Features / Функції

### MVP Core Features

1. **User Authentication / Автентифікація**
   - Email/password registration and login
   - Google OAuth integration
   - Telegram Bot integration
   - GDPR-compliant consent on signup

2. **User Profiles / Профілі користувачів**
   - Current location (country, city) - geolocation or manual input
   - Bio/description
   - Help offerings with categories:
     - 🏠 Temporary housing
     - 💼 Job search help
     - 🗣️ Language lessons
     - 🎓 Education advice
     - 📍 Local advice
     - 💡 Other (with custom details)
   - Privacy: profiles visible only to approved connections

3. **Interactive World Map / Інтерактивна карта**
   - OpenStreetMap integration with Leaflet.js
   - Pin/marker clustering for dense areas
   - Filter by help type
   - Click pins to see profile summaries
   - Country/city statistics

4. **Connection System / Система зв'язків**
   - Invite family/friends via email or shareable link
   - Approve/deny connection requests
   - "My Network" - family and friends groups
   - Privacy controls

5. **Help Requests / Запити на допомогу**
   - Create requests with title, description, type, location
   - Visibility controls (network-only or public)
   - Status tracking (Open, In Progress, Closed)
   - Comments and responses
   - Search and filter requests

6. **Real-time Chat / Чат**
   - 1:1 messaging between connected users
   - Group chat for families
   - Unread message indicators
   - Chat list with previews

7. **Dashboard / Панель керування**
   - Statistics: helpers, countries, active requests, network size
   - Recent requests from your network
   - Quick access to all features

8. **PWA Features / PWA функції**
   - Installable on mobile and desktop
   - Offline functionality
   - Push notifications for new messages/requests
   - Background sync
   - App shortcuts

9. **Multilingual / Багатомовність**
   - Ukrainian (default)
   - English
   - Easy to add more languages

10. **Privacy & Security / Приватність та безпека**
    - Location shared only with permission
    - GDPR-compliant data handling
    - Secure connections only
    - End-to-end encryption for messages (recommended for production)

## 🎨 Design Philosophy

**Visual Style:**
- Warm, supportive color palette with Ukrainian blue-yellow accents
- Clean, modern UI inspired by community and connection
- Mobile-first responsive design
- Accessible for non-technical users
- Comfortaa font for headings (friendly, approachable)
- Manrope font for body text (clean, readable)

**Color Palette:**
- Ukraine Blue: #0057B7
- Ukraine Yellow: #FFD700
- Warm Blue: #4A90E2
- Soft Yellow: #FFC845
- Background: Light gradients (#F8F9FC to #E8EDF5)
- Accent colors for different help types

## 📊 Data Models

### User
```javascript
{
  id: String (UUID),
  name: String,
  email: String (unique),
  passwordHash: String,
  bio: String,
  location: {
    country: String,
    city: String,
    coordinates: {
      lat: Number,
      lng: Number
    }
  },
  helpOffers: Array<String>, // ['housing', 'job', 'language', 'education', 'other']
  offerDetails: String,
  privacy: {
    profileVisibility: String, // 'network-only' or 'public'
    locationSharing: Boolean
  },
  connections: Array<String>, // Array of user IDs
  pendingConnections: Array<{
    userId: String,
    status: String, // 'pending', 'approved', 'denied'
    requestedAt: Date
  }>,
  createdAt: Date,
  updatedAt: Date,
  lastLoginAt: Date,
  preferences: {
    language: String, // 'uk' or 'en'
    notifications: {
      email: Boolean,
      push: Boolean
    }
  }
}
```

### HelpOffer
```javascript
{
  id: String (UUID),
  userId: String, // Reference to User
  type: String, // 'housing', 'job', 'language', 'education', 'other'
  title: String,
  description: String,
  location: {
    country: String,
    city: String,
    coordinates: {
      lat: Number,
      lng: Number
    }
  },
  availability: {
    startDate: Date,
    endDate: Date,
    ongoing: Boolean
  },
  capacity: Number, // How many people can be helped
  conditions: String, // Special conditions or requirements
  contactPreference: String, // 'chat', 'email', 'phone'
  isActive: Boolean,
  createdAt: Date,
  updatedAt: Date,
  views: Number,
  connections: Number // How many people contacted
}
```

### HelpRequest
```javascript
{
  id: String (UUID),
  authorId: String, // Reference to User
  title: String,
  description: String,
  type: String, // 'housing', 'job', 'language', 'education', 'other'
  location: {
    country: String,
    city: String
  },
  urgency: String, // 'low', 'medium', 'high', 'critical'
  status: String, // 'open', 'in-progress', 'closed', 'fulfilled'
  visibility: String, // 'network-only', 'public'
  neededBy: Date,
  responses: Array<{
    userId: String,
    message: String,
    respondedAt: Date
  }>,
  assignedTo: String, // User ID of helper (optional)
  createdAt: Date,
  updatedAt: Date,
  closedAt: Date,
  tags: Array<String>,
  views: Number
}
```

### Connection
```javascript
{
  id: String (UUID),
  userId1: String, // First user
  userId2: String, // Second user
  relationship: String, // 'family', 'friend', 'colleague', 'other'
  status: String, // 'pending', 'accepted', 'blocked'
  initiatedBy: String, // User ID who sent the request
  requestedAt: Date,
  acceptedAt: Date,
  notes: String, // Optional notes about the relationship
  lastInteraction: Date
}
```

### Message
```javascript
{
  id: String (UUID),
  conversationId: String,
  senderId: String,
  recipientId: String, // For 1:1 chats
  content: String,
  type: String, // 'text', 'image', 'file', 'system'
  sentAt: Date,
  deliveredAt: Date,
  readAt: Date,
  isEdited: Boolean,
  editedAt: Date,
  attachments: Array<{
    type: String,
    url: String,
    name: String,
    size: Number
  }>
}
```

### Conversation
```javascript
{
  id: String (UUID),
  type: String, // '1-on-1', 'group'
  participants: Array<String>, // User IDs
  name: String, // For group chats
  createdBy: String,
  createdAt: Date,
  lastMessageAt: Date,
  lastMessage: {
    content: String,
    senderId: String,
    sentAt: Date
  },
  unreadCount: Object, // { userId: count }
  isArchived: Boolean
}
```

## 🚀 Sample Data

The application includes realistic sample data for demonstration:

**Sample Users (8 profiles):**
- Олена Коваленко (Berlin, Germany) - Language teacher, housing + language help
- Андрій Мельник (Warsaw, Poland) - IT specialist, job + language help
- Марія Шевченко (Toronto, Canada) - Medical worker, housing + education help
- Іван Бондаренко (New York, USA) - Entrepreneur, job + business help
- Наталія Петренко (London, UK) - Teacher, education + language help
- Дмитро Коваль (Paris, France) - Architect, housing + language help
- Катерина Литвин (Barcelona, Spain) - Artist, language + cultural help
- Віктор Савченко (Amsterdam, Netherlands) - Engineer, job + housing help

**Sample Help Requests (3 active):**
- Temporary housing in Warsaw for family of 3
- Frontend developer job search in Germany/Netherlands
- English tutoring for children in Berlin

**Sample Chat Conversations (3 active):**
- Recent messages with connected network members

## 🛠️ Technology Stack

### Frontend
- **HTML5** - Semantic markup
- **CSS3** - Modern styling with CSS Grid, Flexbox, Custom Properties
- **Vanilla JavaScript** - No heavy frameworks for fast loading
- **Leaflet.js** - Interactive maps with clustering
- **Service Workers** - PWA functionality and offline support

### Maps & Geolocation
- **OpenStreetMap** - Free, open-source maps
- **Leaflet.js** - Lightweight mapping library
- **Leaflet.markercluster** - Pin clustering for better UX

### PWA Features
- **Web App Manifest** - Installation metadata
- **Service Worker** - Offline caching, background sync
- **Push API** - Notifications
- **Cache API** - Offline data storage

### Recommended Backend (for production)
- **Node.js + Express** or **Firebase** or **Supabase**
- **PostgreSQL** or **MongoDB** - User data, requests, messages
- **Redis** - Real-time chat, session management
- **Socket.io** - Real-time messaging
- **SendGrid** or **Mailgun** - Email invitations
- **Cloudflare** or **AWS S3** - File storage
- **JWT** - Authentication tokens
- **bcrypt** - Password hashing

## 📱 Installation & Setup

### Local Development

1. **Install dependencies**
   ```bash
   npm install
   ```

2. **Set up environment variables**
   
   Create a `.env` file in the root directory:
   ```env
   PORT=3000
   NODE_ENV=development
   DATABASE_URL=postgresql://username:password@localhost:5432/helpkin
   JWT_SECRET=your-super-secret-jwt-key-here
   EMAIL_SERVICE=your-email-service
   EMAIL_USER=your-email@example.com
   EMAIL_PASS=your-email-password
   ```

3. **Set up database**
   
   Run the SQL schema:
   ```bash
   psql -U username -d helpkin < database-schema.sql
   ```

4. **Start the server**
   ```bash
   npm start
   ```

5. **Open in browser**
   ```
   http://localhost:3000
   ```

### Production Deployment

#### Environment Variables Required

```env
PORT=3000
NODE_ENV=production
DATABASE_URL=your-production-database-url
JWT_SECRET=your-production-jwt-secret
EMAIL_SERVICE=your-email-service
EMAIL_USER=your-email@example.com
EMAIL_PASS=your-email-password
```

#### Option 1: Heroku Deployment

1. **Install Heroku CLI and login**
   ```bash
   # Install Heroku CLI
   npm install -g heroku

   # Login
   heroku login
   ```

2. **Create Heroku app**
   ```bash
   heroku create your-app-name
   ```

3. **Add PostgreSQL database**
   ```bash
   heroku addons:create heroku-postgresql:hobby-dev
   ```

4. **Set environment variables**
   ```bash
   heroku config:set NODE_ENV=production
   heroku config:set JWT_SECRET=your-production-jwt-secret
   heroku config:set EMAIL_SERVICE=your-email-service
   heroku config:set EMAIL_USER=your-email@example.com
   heroku config:set EMAIL_PASS=your-email-password
   ```

5. **Deploy**
   ```bash
   git push heroku main
   ```

#### Option 2: DigitalOcean App Platform

1. **Connect your GitHub repository**
2. **Configure the app:**
   - Runtime: Node.js
   - Build Command: `npm install`
   - Run Command: `npm start`
   - Environment Variables: Set the required env vars above
3. **Add PostgreSQL database**
4. **Deploy**

#### Option 3: AWS EC2 + RDS

1. **Launch EC2 instance**
   ```bash
   # Install Node.js
   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
   sudo apt-get install -y nodejs

   # Clone your repository
   git clone https://github.com/yourusername/help-kin-map.git
   cd help-kin-map

   # Install dependencies
   npm install

   # Set up PM2 for process management
   sudo npm install -g pm2
   pm2 start server.js --name "help-kin"
   pm2 startup
   pm2 save
   ```

2. **Set up RDS PostgreSQL database**
3. **Configure security groups and environment variables**
4. **Set up Nginx reverse proxy**
   ```nginx
   server {
       listen 80;
       server_name your-domain.com;

       location / {
           proxy_pass http://localhost:3000;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection 'upgrade';
           proxy_set_header Host $host;
           proxy_cache_bypass $http_upgrade;
       }
   }
   ```

#### Option 4: Vercel + Supabase

1. **Deploy frontend to Vercel**
   ```bash
   npm install -g vercel
   vercel --prod
   ```

2. **Set up Supabase for backend**
   - Create Supabase project
   - Run the database schema
   - Update environment variables with Supabase credentials

## 🔐 Security Recommendations

For production deployment:

1. **Authentication**
   - Implement proper JWT token validation
   - Use secure password hashing (bcrypt with salt rounds ≥ 10)
   - Add rate limiting on login attempts
   - Implement CSRF protection

2. **Data Privacy**
   - Encrypt sensitive data at rest
   - Use HTTPS everywhere (enforce with HSTS headers)
   - Implement proper CORS policies
   - Add input validation and sanitization

3. **User Safety**
   - Report/block functionality for harassment
   - Moderation system for public requests
   - Age verification for safety
   - Terms of service and privacy policy

4. **API Security**
   - Rate limiting (express-rate-limit)
   - Input validation (joi, express-validator)
   - SQL injection prevention (parameterized queries)
   - XSS prevention (sanitize user input)

## 🌍 Internationalization

Adding a new language:

1. Add translations to the `translations` object in the HTML file:
```javascript
const translations = {
  uk: { /* existing */ },
  en: { /* existing */ },
  pl: {
    appName: "Mapa Pomocy Rodzinie",
    login: "Zaloguj się",
    // ... add all keys
  }
};
```

2. Add language option to select:
```html
<option value="pl">🇵🇱 Polski</option>
```

## 📊 Analytics & Monitoring

Recommended tools:
- **Google Analytics** - User behavior tracking
- **Sentry** - Error tracking
- **Hotjar** - User session recording
- **PostHog** - Open-source product analytics

## 🧪 Testing

Recommended testing approach:

```bash
# Install testing tools
npm install --save-dev jest @testing-library/dom

# Run tests
npm test
```

**Example test:**
```javascript
describe('User Authentication', () => {
  test('should login with valid credentials', async () => {
    // Test implementation
  });
  
  test('should show error with invalid credentials', async () => {
    // Test implementation
  });
});
```

## 📈 Scalability Considerations

For handling growth:

1. **Database**
   - Index frequently queried fields (location, userId, type)
   - Implement pagination for lists
   - Use database connection pooling
   - Consider read replicas for high traffic

2. **Caching**
   - Redis for session management
   - Cache map markers and user lists
   - CDN for static assets

3. **Real-time Features**
   - Use WebSocket pools
   - Implement message queuing (RabbitMQ, Kafka)
   - Horizontal scaling with load balancers

4. **File Storage**
   - Use cloud storage (S3, Google Cloud Storage)
   - Implement image compression
   - CDN for media delivery

## 🤝 Contributing

To contribute to this project:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is created for humanitarian purposes to help Ukrainian families stay connected during difficult times. Feel free to use, modify, and distribute.

## 💙💛 Support Ukraine

This application is dedicated to helping Ukrainian families stay connected and support each other during the ongoing war. All development effort is donated to this cause.

Ways to help:
- Share this app with Ukrainian communities
- Contribute code improvements
- Report bugs and suggest features
- Translate to more languages
- Support Ukrainian refugees in your area

## 📞 Contact & Support

For questions, suggestions, or support:
- Email: support@helpkinmap.org (example)
- GitHub Issues: [github.com/helpkinmap/issues]
- Community Discord: [discord.gg/helpkinmap]

## 🎯 Roadmap

**Phase 2 Features:**
- [ ] Video chat integration
- [ ] Document sharing (resumes, certificates)
- [ ] Verified helpers badge system
- [ ] Calendar for scheduling help
- [ ] Integration with job boards
- [ ] Housing availability calendar
- [ ] Success stories section
- [ ] Mobile native apps (React Native)

**Phase 3 Features:**
- [ ] AI-powered matching (helpers ↔ requests)
- [ ] Translation service integration
- [ ] Community events calendar
- [ ] Resource library (guides, documents)
- [ ] Volunteer organization partnerships
- [ ] Legal aid connections

---

Built with 💙💛 for the Ukrainian community worldwide.

Слава Україні! 🇺🇦
