#!/usr/bin/env python3
"""
Web service wrapper for the shorten URL Lambda function.

Transforms the Lambda handler into a containerized microservice.
"""

from src.handlers.shorten_url import handler as lambda_handler
import json
import os
import sys
from flask import Flask, request, jsonify

# Add the src directory to Python path for imports
sys.path.insert(0, '/app/src')


# Initialize Flask application
app = Flask(__name__)

# Set default environment variables for containerized deployment
os.environ.setdefault('AWS_DEFAULT_REGION', 'us-east-1')
os.environ.setdefault('BASE_URL', 'http://localhost:8000')


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint for container orchestration."""
    return jsonify({"status": "healthy", "service": "shorten"}), 200


@app.route('/shorten', methods=['POST'])
def shorten_url():
    """
    URL shortening endpoint.

    Transforms HTTP request into Lambda event format and back.
    """
    try:
        # Transform Flask request into Lambda event format
        lambda_event = {
            'httpMethod': 'POST',
            'path': '/shorten',
            'headers': dict(request.headers),
            'body': request.get_data(as_text=True),
            'queryStringParameters': (dict(request.args)
                                      if request.args else None),
            'pathParameters': None,
            'requestContext': {
                'requestId': 'container-request',
                'stage': 'prod'
            }
        }

        # Call the Lambda handler
        lambda_response = lambda_handler(lambda_event, None)

        # Transform Lambda response back to Flask response
        status_code = lambda_response.get('statusCode', 500)
        response_body = json.loads(lambda_response.get('body', '{}'))

        return jsonify(response_body), status_code

    except Exception as e:
        app.logger.error(f"Error processing request: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500


@app.route('/', methods=['GET'])
def root():
    """Root endpoint with service information."""
    return jsonify({
        "service": "tiny-url-shorten",
        "version": "1.0.0",
        "endpoints": {
            "POST /shorten": "Create a short URL",
            "GET /health": "Health check"
        }
    }), 200


if __name__ == '__main__':
    # Get port from environment variable or default to 8000
    port = int(os.environ.get('PORT', 8000))

    # Run the Flask application
    app.run(
        host='0.0.0.0',  # Listen on all interfaces for container networking
        port=port,
        debug=False,     # Disable debug mode in production
        threaded=True    # Enable threading for better performance
    )
