import os
import logging
import pickle
import pandas as pd
from flask import Flask, render_template, request, jsonify

# Base directory (where this file lives)
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

app = Flask(
    __name__,
    template_folder=os.path.join(BASE_DIR, "templates"),
    static_folder=os.path.join(BASE_DIR, "static"),
)

# Initialize logging
logging.basicConfig(level=logging.DEBUG)

# Load model and data
try:
    data_path = os.path.join(BASE_DIR, "cleaned_medicines.csv")
    model_path = os.path.join(BASE_DIR, "medicine_model.pkl")
    vectorizer_path = os.path.join(BASE_DIR, "vectorizer.pkl")

    data = pd.read_csv(data_path)

    with open(model_path, "rb") as model_file:
        model = pickle.load(model_file)

    with open(vectorizer_path, "rb") as vectorizer_file:
        vectorizer = pickle.load(vectorizer_file)

    logging.info("✅ Model and data loaded successfully.")
except Exception as e:
    logging.error(f"❌ Error loading model or data: {e}")
    exit(1)


@app.route("/")
def home():
    return render_template("index.html")


@app.route("/search", methods=["POST"])
def search_medicine():
    try:
        request_data = request.get_json()
        query = request_data.get("medicine", "").strip()

        if not query:
            return jsonify({"status": "error", "message": "No input provided."}), 400

        # Vectorize the query
        query_vector = vectorizer.transform([query])

        # Find nearest neighbors
        distances, indices = model.kneighbors(query_vector, n_neighbors=10)

        results = []
        for dist, idx in zip(distances[0], indices[0]):
            medicine_info = {
                "Medicine Name": data.iloc[idx]["name"],
                "Manufacturer": data.iloc[idx]["manufacturer_name"],
                "Type": data.iloc[idx]["type"],
                "Pack Size": data.iloc[idx]["pack_size_label"],
                "Price (₹)": data.iloc[idx]["price(₹)"],
                "Symptoms": (
                    data.iloc[idx]["symptoms"] if "symptoms" in data.columns else ""
                ),
                "Score": round(1 - dist, 4),  # Higher score = better match
            }
            results.append(medicine_info)

        # Sort by score (high to low)
        results = sorted(results, key=lambda x: x["Score"], reverse=True)

        return jsonify({"status": "success", "data": results})

    except Exception as e:
        logging.error(f"❌ Error during search: {e}")
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "An error occurred during search. Please try again later.",
                }
            ),
            500,
        )


if __name__ == "__main__":
    # On production (Render, etc.) use gunicorn instead of debug server
    app.run(host="0.0.0.0", port=5000, debug=True)
