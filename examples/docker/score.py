import os
import json
import logging
from flask import Flask, request, jsonify # type: ignore
from model_utils import ContosoLabModel, validate_input_data, format_response

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("score")

app = Flask(__name__)
model = ContosoLabModel(
    model_name=os.getenv("MODEL_NAME", "contoso-sample-model"),
    version=os.getenv("MODEL_VERSION", "1.0.0"),
)
model.load_model()


@app.route("/health", methods=["GET"])  # Used by Dockerfile HEALTHCHECK
def health():
    return jsonify(
        {
            "status": "ok",
            "model_loaded": model.is_loaded,
            "model_name": model.model_name,
            "model_version": model.version,
        }
    )


@app.route("/score", methods=["POST"])  # Typical Azure ML scoring endpoint name
def score():
    try:
        data = request.get_json(force=True, silent=False)
        items = validate_input_data(data)
        preds = model.predict(items)
        response = format_response(preds)
        return jsonify(response)
    except Exception as e:  # Return structured error
        logger.exception("Scoring failed")
        return jsonify({"status": "error", "message": str(e)}), 400


@app.route("/info", methods=["GET"])  # Extra metadata endpoint
def info():
    return jsonify(model.get_model_info())


if __name__ == "__main__":
    # Allow override of port via env var (Azure ML often overrides CMD anyway)
    port = int(os.getenv("PORT", "5001"))
    host = os.getenv("HOST", "0.0.0.0")
    app.run(host=host, port=port)
