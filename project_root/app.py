from flask import Flask, render_template, request, jsonify
import pandas as pd
import pickle
import logging

app = Flask(__name__)

# Initialize logging
logging.basicConfig(level=logging.DEBUG)

# Load model and data
try:
    data = pd.read_csv('cleaned_medicines.csv')

    with open('medicine_model.pkl', 'rb') as model_file:
        model = pickle.load(model_file)

    with open('vectorizer.pkl', 'rb') as vectorizer_file:
        vectorizer = pickle.load(vectorizer_file)

    logging.info("✅ Model and data loaded successfully.")
except Exception as e:
    logging.error(f"❌ Error loading model or data: {e}")
    exit(1)

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/search', methods=['POST'])
def search_medicine():
    try:
        request_data = request.get_json()
        query = request_data.get('medicine', '').strip()

        if not query:
            return jsonify({'status': 'error', 'message': 'No input provided.'}), 400

        # Vectorize the query
        query_vector = vectorizer.transform([query])

        # Find nearest neighbors
        distances, indices = model.kneighbors(query_vector, n_neighbors=10)


        results = []
        for dist, idx in zip(distances[0], indices[0]):
            medicine_info = {
                'Medicine Name': data.iloc[idx]['name'],
                'Manufacturer': data.iloc[idx]['manufacturer_name'],
                'Type': data.iloc[idx]['type'],
                'Pack Size': data.iloc[idx]['pack_size_label'],
                'Price (₹)': data.iloc[idx]['price(₹)'],
                'Symptoms': data.iloc[idx]['symptoms'] if 'symptoms' in data.columns else '',
                'Score': round(1 - dist, 4)  # Higher score = better match
            }
            results.append(medicine_info)

        # Sort by score (high to low)
        results = sorted(results, key=lambda x: x['Score'], reverse=True)

        return jsonify({'status': 'success', 'data': results})

    except Exception as e:
        logging.error(f"❌ Error during search: {e}")
        return jsonify({'status': 'error', 'message': 'An error occurred during search. Please try again later.'}), 500

if __name__ == '__main__':
    app.run(debug=True)
