from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from ultralytics import YOLO
from PIL import Image
import io
import base64
import json
import os
import time

app = Flask(__name__)
CORS(app)

# Load model once at startup
model = YOLO("yolov8n.pt")  # Downloads automatically on first run

UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "model": "yolov8n"})


@app.route("/detect", methods=["POST"])
def detect():
    if "image" not in request.files:
        return jsonify({"error": "No image provided"}), 400

    file = request.files["image"]
    if file.filename == "":
        return jsonify({"error": "Empty filename"}), 400

    try:
        start_time = time.time()

        # Open and process image
        img = Image.open(file.stream).convert("RGB")
        original_size = {"width": img.width, "height": img.height}

        # Run YOLOv8 inference
        results = model(img, conf=float(request.form.get("confidence", 0.25)))
        inference_time = round((time.time() - start_time) * 1000, 1)

        # Parse detections
        detections = []
        for r in results:
            for box in r.boxes:
                detections.append({
                    "label": model.names[int(box.cls)],
                    "confidence": round(float(box.conf), 3),
                    "bbox": {
                        "x1": round(float(box.xyxy[0][0])),
                        "y1": round(float(box.xyxy[0][1])),
                        "x2": round(float(box.xyxy[0][2])),
                        "y2": round(float(box.xyxy[0][3])),
                    }
                })

        # Sort by confidence
        detections.sort(key=lambda d: d["confidence"], reverse=True)

        # Generate annotated image as base64
        annotated_array = results[0].plot()
        annotated_img = Image.fromarray(annotated_array)
        buf = io.BytesIO()
        annotated_img.save(buf, format="JPEG", quality=90)
        buf.seek(0)
        annotated_b64 = base64.b64encode(buf.read()).decode("utf-8")

        # Count unique labels
        label_counts = {}
        for d in detections:
            label_counts[d["label"]] = label_counts.get(d["label"], 0) + 1

        return jsonify({
            "success": True,
            "inference_time_ms": inference_time,
            "total_objects": len(detections),
            "original_size": original_size,
            "label_counts": label_counts,
            "detections": detections,
            "annotated_image": f"data:image/jpeg;base64,{annotated_b64}"
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/models", methods=["GET"])
def list_models():
    return jsonify({
        "models": [
            {"id": "yolov8n", "name": "YOLOv8 Nano", "description": "Fastest, lightest"},
            {"id": "yolov8s", "name": "YOLOv8 Small", "description": "Balanced speed/accuracy"},
            {"id": "yolov8m", "name": "YOLOv8 Medium", "description": "Higher accuracy"},
        ]
    })


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)