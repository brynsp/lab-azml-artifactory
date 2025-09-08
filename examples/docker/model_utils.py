"""
Model utilities for the Contoso Lab sample container.

This module provides helper functions for model operations,
demonstrating best practices for containerized ML models.
"""

import json
import logging
import os
import pickle
from typing import Any, Dict, List, Optional
import numpy as np

logger = logging.getLogger(__name__)


class ContosoLabModel:
    """Sample model class for demonstration purposes."""
    
    def __init__(self, model_name: str = "contoso-sample-model", version: str = "1.0.0"):
        self.model_name = model_name
        self.version = version
        self.is_loaded = False
        self.model_data = None
        
    def load_model(self, model_path: Optional[str] = None) -> None:
        """Load the model (simulated for demo purposes)."""
        try:
            logger.info(f"Loading model: {self.model_name} v{self.version}")
            
            # Simulate model loading
            self.model_data = {
                "weights": np.random.rand(10, 5),
                "bias": np.random.rand(5),
                "feature_names": [f"feature_{i}" for i in range(10)],
                "classes": ["class_a", "class_b", "class_c", "class_d", "class_e"]
            }
            
            self.is_loaded = True
            logger.info("Model loaded successfully")
            
        except Exception as e:
            logger.error(f"Failed to load model: {str(e)}")
            raise
    
    def predict(self, input_data: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Make predictions on input data."""
        if not self.is_loaded:
            raise RuntimeError("Model not loaded. Call load_model() first.")
        
        predictions = []
        
        for item in input_data:
            try:
                # Simulate prediction logic
                feature_values = [item.get(f"feature_{i}", 0.0) for i in range(10)]
                
                # Simple linear transformation for demo
                scores = np.dot(feature_values, self.model_data["weights"]) + self.model_data["bias"]
                predicted_class_idx = np.argmax(scores)
                predicted_class = self.model_data["classes"][predicted_class_idx]
                confidence = float(np.max(scores) / np.sum(np.abs(scores)))
                
                prediction = {
                    "input": item,
                    "predicted_class": predicted_class,
                    "confidence": min(max(confidence, 0.0), 1.0),  # Clamp to [0,1]
                    "scores": scores.tolist(),
                    "model_name": self.model_name,
                    "model_version": self.version
                }
                
                predictions.append(prediction)
                
            except Exception as e:
                logger.error(f"Prediction failed for item {item}: {str(e)}")
                predictions.append({
                    "input": item,
                    "error": str(e),
                    "model_name": self.model_name,
                    "model_version": self.version
                })
        
        return predictions
    
    def get_model_info(self) -> Dict[str, Any]:
        """Get model metadata."""
        return {
            "name": self.model_name,
            "version": self.version,
            "is_loaded": self.is_loaded,
            "features_count": 10 if self.is_loaded else None,
            "classes": self.model_data["classes"] if self.is_loaded else None,
            "description": "Sample model for Contoso Lab Artifactory integration testing"
        }


def validate_input_data(data: Any) -> List[Dict[str, Any]]:
    """Validate and normalize input data."""
    if isinstance(data, dict):
        # Handle single prediction request
        return [data] if "data" not in data else data["data"]
    elif isinstance(data, list):
        # Handle batch prediction request
        return data
    else:
        raise ValueError(f"Invalid input data format. Expected dict or list, got {type(data)}")


def format_response(predictions: List[Dict[str, Any]], status: str = "success") -> Dict[str, Any]:
    """Format the response in a standard structure."""
    return {
        "predictions": predictions,
        "count": len(predictions),
        "status": status,
        "timestamp": str(np.datetime64('now')),
        "lab_info": {
            "source": "Contoso Lab",
            "workflow": "Artifactory -> ACR -> Azure ML",
            "purpose": "Testing container deployment"
        }
    }


if __name__ == "__main__":
    # Test the model utilities
    print("Testing Contoso Lab Model Utilities")
    
    model = ContosoLabModel()
    model.load_model()
    
    test_data = [
        {f"feature_{i}": np.random.rand() for i in range(10)},
        {f"feature_{i}": np.random.rand() for i in range(10)}
    ]
    
    predictions = model.predict(test_data)
    response = format_response(predictions)
    
    print(json.dumps(response, indent=2))