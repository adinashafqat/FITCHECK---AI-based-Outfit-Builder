# FIT CHECK

---

## **PROJECT OBJECTIVES**

FitCheck aims to simplify outfit planning by combining wardrobe management with real-time weather data.

- Create a digital closet with images, categories, and seasonal tags  
- Provide real-time weather updates  
- Filter clothing based on weather conditions (Summer, Winter, All Year)  
- Offer an interactive outfit builder  
- Generate AI-based style tips  
- Manage user profiles with authentication  

---

## **KEY FEATURES**

### **User Authentication**
- Secure sign-up and login using Firebase Authentication  

### **Digital Closet**
- Add, view, and delete clothing items  
- Store image, name, category, and season  

### **Weather Integration**
- Fetch real-time weather data from WeatherAPI  
- Display temperature, condition, and location  

### **Smart Filtering**
- Automatically hides unsuitable items  

### **AI Style Assistant**
- Provides outfit suggestions and daily fashion tips  

### **Outfit Builder**
- Swipeable interface for mixing tops and bottoms  

### **User Profile**
- Profile picture, settings, help, and privacy controls  

### **Local Storage**
- Uses Hive for offline data storage  

---

## **SYSTEM ARCHITECTURE**

### **Core Services**
- AuthService – Handles authentication  
- DatabaseService – Manages Hive database  
- WeatherService – Fetches API data  
- AICommentService – Generates style tips  

### **UI STRUCTURE**
- LoginScreen / SignUpScreen → AuthWrapper → MainApp  
- Main tabs:
  - HomeDashboard  
  - MyClosetScreen  
  - OutfitBuilderScreen  
  - ProfileScreen  

---

## **APPLICATION FLOW**

### **Authentication Flow**
- App starts → AuthWrapper checks login  
- If not logged in → Login / Signup  
- On success → MainApp  

### **Main App Flow**

**HomeDashboard**
- Displays weather and AI suggestions  

**MyClosetScreen**
- Shows filtered clothing items  

**OutfitBuilderScreen**
- Mix and match outfits  

**ProfileScreen**
- Manage user settings and logout  

---

## **TECHNOLOGY STACK**

- Flutter (Dart)  
- Firebase Authentication  
- Hive Database  
- WeatherAPI  

**Packages:**
- image_picker  
- http  
- google_fonts  

---

## **SETUP**

```bash
git clone https://github.com/adinashafqat/fitcheck.git
cd fitcheck
flutter pub get
flutter run
