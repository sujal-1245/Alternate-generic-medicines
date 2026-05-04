<h1 align="center">💊 Dawaikhana – Smart Generic Medicine Finder</h1>

<p align="center">
  <b>AI-powered system to find affordable generic medicines and nearby pharmacies</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Backend-Flask-blue?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/Frontend-Flutter-green?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/ML-TF--IDF%20%2B%20KNN-orange?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/Maps-Google%20Maps%20%7C%20Leaflet-red?style=for-the-badge"/>
</p>

---

## 🌟 Overview

**Dawaikhana** is a machine learning-powered healthcare application that helps users:

- 🔍 Search medicines using **name or symptoms**
- 💊 Discover **generic alternatives** for expensive branded drugs
- 📊 Compare medicines based on price and details
- 📍 Locate **nearby pharmacies** using map integration

Unlike existing platforms, Dawaikhana combines **AI-based recommendation + real-world accessibility** in one system.

---

## 🎥 Demo

<p align="center">


https://github.com/user-attachments/assets/52dd5e75-2f3d-442e-ae03-8765e36160dc

  
</p>

---

## 📱 Mobile Application

<p align="center">
  
  <img width="120" alt="image" src="https://github.com/user-attachments/assets/440ec80c-4f1c-4c5b-9ff4-33a8d3e0f490" />
  
  <img width="120" alt="image" src="https://github.com/user-attachments/assets/c1d83334-7d41-4f34-aa01-ad6a901c0251" />
  
  <img width="120" alt="image" src="https://github.com/user-attachments/assets/4adfb5b3-d17f-41fc-9efc-ee04479c459a" />

  <img width="120" alt="image" src="https://github.com/user-attachments/assets/7fd33003-e5a6-44b0-acac-a52139f9c10d" />

  <img width="120" alt="image" src="https://github.com/user-attachments/assets/586889df-9706-4979-8c15-303cb79f6473" />

  <img width="120" alt="image" src="https://github.com/user-attachments/assets/70b7bb80-26ca-442b-b38c-24ea19b01f63" />

  
</p>

---

## 🌐 Web Application

<p align="center">
  <img width="352"  alt="image" src="https://github.com/user-attachments/assets/f19183b5-5710-4749-9c1b-08cecd40fac4" />


  <img width="352" alt="image" src="https://github.com/user-attachments/assets/393bef48-f2e1-4ceb-bd46-2c2f9a860776" />

</p>

<p align="center">
  <img width="352"  alt="image" src="https://github.com/user-attachments/assets/6b332c2c-8557-4de2-bcf0-10f57b0b7ebc" />


  <img width="352"  alt="image" src="https://github.com/user-attachments/assets/304c3a33-78eb-4af5-b028-e6702fee43b3" />

</p>

---

## 🧠 Key Features

### 🔍 Intelligent Search
- Accepts **medicine names OR symptoms**
- Handles **misspellings and variations**

### 💊 Generic Recommendation Engine
- Finds **cheaper alternatives**
- Maintains **same composition & effectiveness**

### 📊 ML-Based Ranking
- Uses **TF-IDF vectorization**
- KNN for **similarity-based retrieval**
- Ranked results using similarity score

### 📍 Pharmacy Locator
- Web: **Leaflet + OpenStreetMap**
- Mobile: **Google Maps integration**

---

## 🔬 Machine Learning Pipeline

```

User Input (Medicine / Symptoms)
↓
Text Preprocessing
↓
TF-IDF Vectorization
↓
KNN Similarity Search
↓
Ranking (Score = 1 - Distance)
↓
Top Results
↓
Pharmacy Locator

```

✔ Supports:
- Exact queries  
- Misspelled inputs  
- Symptom-based searches  

---

## 🧪 Performance Metrics

| Query Type         | Precision | Recall | Accuracy |
|-------------------|----------|--------|----------|
| Exact Queries      | 0.70     | 0.70   | 0.92     |
| Misspelled Queries | 0.73     | 0.73   | 1.00     |
| Symptom-Based      | 0.15     | 0.15   | 0.35     |

⚡ Average Response Time: **< 500ms**

---

## 🏗 System Architecture

<p align="center">
  <img src="screenshots/workflow.png" width="600"/>
</p>

### Components:

- **Frontend (Flutter + Web UI)**
- **Backend (Flask REST API)**
- **ML Module (TF-IDF + KNN)**
- **Geolocation Module (Maps APIs)**

---

## ⚙️ Backend Workflow

- Receives user query
- Converts to TF-IDF vector
- Finds nearest neighbors using KNN
- Computes similarity score
- Returns ranked results as JSON

---

## 📂 Project Structure

```

Alternate-generic-medicines/
│
├── backend/
│   ├── app.py
│   ├── medicine_model.pkl
│   ├── vectorizer.pkl
│   ├── cleaned_medicines.csv
│
├── frontend/
│   ├── flutter_app/
│   └── web_app/
│
├── templates/
├── static/
├── screenshots/
│
└── README.md

````

---

## 🚀 How to Run

### 🔹 Backend (Flask)

```bash
pip install -r requirements.txt
python app.py
````

---

### 🔹 Web App

Open in browser:

```
http://localhost:5000
```

---

### 🔹 Flutter App

```bash
cd flutter_app
flutter pub get
flutter run
```

---

## 🌍 Deployment

Live Demo:
👉 [https://alternate-generic-medicines.onrender.com/](https://alternate-generic-medicines.onrender.com/)

---

## 🔮 Future Scope

* 🤖 Transformer-based semantic search (BERT)
* 📄 Prescription OCR (Tesseract / LSTM)
* 📦 Real-time pharmacy inventory integration
* 👤 Personalized recommendations
* 🏥 Integration with healthcare systems

---

## ⚠️ Limitations

* Dependent on dataset quality
* Symptom mapping not medically exhaustive
* No real-time inventory tracking yet

---

## 🤝 Contributing

Pull requests are welcome.
For major changes, open an issue first.

---

## 📜 License

MIT License

---

## 👨‍💻 Author

<p align="center"> <a href="https://github.com/sujal-1245" target="_blank"> <img src="https://img.shields.io/badge/GitHub-Sujal--1245-181717?style=for-the-badge&logo=github&logoColor=white"/> </a> </p> ```
