"""
Sample scoring script for testing container deployment in Azure ML

This script demonstrates a minimal ML model serving endpoint
for validating the Artifactory -> ACR -> Azure ML workflow.
"""

import json
import logging
import os
from typing import Any, Dict, List

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def init():
    """Initialize the model service."""
    global model
    
    logger.info("Initializing Contoso Lab Model Service")
    logger.info(f"Python version: {os.sys.version}")
    logger.info(f"Environment variables: {dict(os.environ)}")
    
    # Simulate model loading
    model = {
        "name": "contoso-lab-model",
        "version": "1.0.0",
        "description": "Sample model for Artifactory integration testing",
        "status": "ready"
    }
    
    logger.info(f"Model loaded successfully: {model}")


def run(raw_data: str) -> str:
    """
    Process incoming requests.
    
    Args:
        raw_data: JSON string containing input data
        
    Returns:
        JSON string with prediction results
    """
    try:
        logger.info(f"Received request: {raw_data}")
        
        # Parse input data
        data = json.loads(raw_data)
        
        # Simulate prediction
        predictions = []
        for item in data.get("data", []):
            prediction = {
                "input": item,
                "prediction": "sample_prediction_" + str(hash(str(item)) % 1000),
                "confidence": 0.85,
                "model": model["name"],
                "version": model["version"]
            }
            predictions.append(prediction)
        
        result = {
            "predictions": predictions,
            "model_info": model,
            "status": "success"
        }
        
        logger.info(f"Returning predictions: {result}")
        return json.dumps(result)
        
    except Exception as e:
        error_msg = f"Error processing request: {str(e)}"
        logger.error(error_msg)
        return json.dumps({"error": error_msg, "status": "failed"})


if __name__ == "__main__":
    # Test locally
    init()
    
    sample_input = json.dumps({
        "data": [
            {"feature1": 1.0, "feature2": 2.0},
            {"feature1": 3.0, "feature2": 4.0}
        ]
    })
    
    result = run(sample_input)
    print(f"Test result: {result}")