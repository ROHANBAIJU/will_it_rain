# 🌦️ Will It Rain

## 📋 Solution Overview

**Will It Rain** is designed to provide quick and accurate weather information, with a specific focus on precipitation forecasts. Whether you're planning a trip, a picnic, or just deciding whether to grab an umbrella, this tool gives you the essential details about the probability of rain in your location.



## 🛠️ Tech Stack
### Backend Stack
- **FastAPI** - Modern, high-performance Python web framework ![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=flat-square&logo=fastapi&logoColor=white)
- **Python 3.12** - Programming language ![Python](https://img.shields.io/badge/Python-3776AB?style=flat-square&logo=python&logoColor=white)
- **Pandas & NumPy** - Data processing and analysis ![Pandas](https://img.shields.io/badge/pandas-%23150458.svg?style=flat-square&logo=pandas&logoColor=white)
                                                   ![NumPy](https://img.shields.io/badge/numpy-%23013243.svg?style=flat-square&logo=numpy&logoColor=white)
- **Uvicorn** - ASGI server for production deployment ![Uvicorn](https://img.shields.io/badge/uvicorn-4A90E2?style=flat-square&logo=uvicorn&logoColor=white)



### Fontend Stack
**Flutter (Dart)**Cross-platform mobile and web development ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white)
                                                            ![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white)
                                                            
**Figma** UI/UX design and prototyping  ![Figma](https://img.shields.io/badge/Figma-F24E1E?style=flat-square&logo=figma&logoColor=white)



### Database & Storage
- **Google Firestore** - NoSQL cloud database for user data and cache ![Firestore](https://img.shields.io/badge/Firestore-FF6B35?style=flat-square&logo=firebase&logoColor=white)

- **Firebase Admin SDK** - Server-side Firebase integration ![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=flat-square&logo=firebase&logoColor=black)
-**SharedPreferences** - Local data persistence


### AI & ML
- **Google Gemini AI** (gemini-2.0-flash-thinking-exp) - AI reasoning and verification![Google Gemini](https://img.shields.io/badge/Google%20Gemini-4285F4?style=flat-square&logo=google&logoColor=white)
- **Statistical Engine** - Custom Python algorithms for weather prediction
- **NASA POWER API** - Historical weather data (39+ years)![NASA](https://img.shields.io/badge/NASA-0B3D91?style=flat-square&logo=nasa&logoColor=white)

### Security & Authentication
- **JWT (JSON Web Tokens)** - Stateless authentication
- **Passlib + Bcrypt** - Password hashing
- **Firebase Authentication** - User management
- **CORS Middleware** - Cross-origin resource sharing

### DevOps & Deployment

![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat-square&logo=docker&logoColor=white)
![Render](https://img.shields.io/badge/Render-46E3B7?style=flat-square&logo=render&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-2088FF?style=flat-square&logo=github-actions&logoColor=white)



### Primary Data Source
- **NASA POWER API** (Prediction Of Worldwide Energy Resources)
  - **Temporal Coverage**: 1986-2024 (39 years)
  - **Spatial Resolution**: 0.5° × 0.5° (~50km grid)
  - **Parameters**: Precipitation, Temperature, Wind Speed, Humidity
  - **Update Frequency**: Monthly updates by NASA
  - **Validation**: Cross-validated with ground stations

### Sample Dataset
- **Bangalore Weather Data** (1986-2023): 13,871 daily weather records
- **Parameters**: Wind Speed (WS10M), Relative Humidity (RH2M), Max/Min Temperature (T2M_MAX/T2M_MIN), Precipitation (PRECTOTCORR)
## 🚀 How the App Works

### 1. Data Collection & Processing
```mermaid
graph TD
    A[User Input: Location + Date] --> B[NASA POWER API]
    B --> C[Fetch 39 Years Historical Data]
    C --> D[Statistical Analysis Engine]
    D --> E[Calculate Rain Probability]
    E --> F[Generate Confidence Score]
    F --> G[AI Reasoning Agent]
    G --> H[User-Friendly Insights]
```

### 2. User Experience Flow
1. **Location Selection**: Map-based or search input
2. **Date Selection**: Calendar picker for any future date
3. **Prediction Display**: Probability, confidence, and AI insights
4. **Historical Analysis**: View past weather patterns
5. **Planning Tools**: Best days finder, comparison features

## 🎯 Key Features

### Core Functionality
- ✅ **Historical Weather Analysis**: 39 years of NASA data
- ✅ **Statistical Predictions**: Transparent probability calculations
- ✅ **AI-Powered Insights**: Google Gemini explanations
- ✅ **Confidence Scoring**: Know when to trust predictions
- ✅ **Location-Based**: Precise coordinate-based forecasts

### Advanced Features
- 🗺️ **Interactive Maps**: Visual location selection
- 🔍 **Best Days Finder**: Optimal weather date suggestions
- 📱 **Cross-Platform**: Flutter mobile and web support
- 🔐 **User Authentication**: Firebase-based user accounts
- 📈 **Comparison Tools**: Multi-location weather comparison

## 📱 Screenshots & Demo


## Prerequisites
- Python 3.8+
- Flutter SDK 3.9.2+
- Firebase project
- Google Cloud Console access
- NASA POWER API access (free)

## 🧠 **AI Integration**

### Two-Stage AI System

#### **Stage 1: Data Verification Agent**
- **Model**: Gemini 2.0 Flash Thinking Exp
- **Purpose**: Validates statistical calculations
- **Temperature**: 0.3 (low for accuracy)
- **Max Tokens**: 500
- **Outputs**:
  - Validity status
  - Confidence level
  - Detected anomalies
  - Validation notes

#### **Stage 2: Reasoning Agent**
- **Model**: Gemini 2.0 Flash Thinking Exp
- **Purpose**: Generates human-readable insights
- **Temperature**: 0.7 (creative but grounded)
- **Max Tokens**: 800
- **Outputs**:
  - Weather summary
  - Precipitation likelihood explanation
  - Activity recommendations
  - Risk factors
  - Historical context

### AI Features
- ✅ Optional (works without API key)
- ✅ Graceful degradation
- ✅ Error handling with fallbacks
- ✅ Context-aware prompts
- ✅ Structured JSON responses



## 🧪 Testing

### Backend Tests
```bash
cd BACKEND
python -m pytest app/tests/
```

### Frontend Tests
```bash
cd FRONTEND
flutter test
```

## 📈 Performance Metrics

### Accuracy Benchmarks
- **Rain Prediction**: 65-75% accuracy (vs 50% random)
- **Temperature Prediction**: ±2-3°C average error
- **Confidence Scoring**: 95% for complete datasets

### Response Times
- **API Response**: < 2 seconds average
- **Data Processing**: < 1 second for 39 years
- **AI Insights**: < 3 seconds generation time

## 🙏 Acknowledgments
- **NASA POWER API** for providing comprehensive weather data
- **Google Gemini** for AI-powered insights
- **Firebase** for authentication and database services
- **Flutter Team** for the excellent cross-platform framework
- **FastAPI** for the high-performance Python web framework

### 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/ROHANBAIJU/will_it_rain.git
cd will_it_rain

# Start the backend
cd BACKEND && pip install -r requirements.txt && uvicorn app.main:app --reload

# Start the frontend
cd ../FRONTEND && flutter pub get && flutter run
```

**Built with  using NASA data, statistical science, and AI reasoning.**



