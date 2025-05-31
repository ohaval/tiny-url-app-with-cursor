#!/usr/bin/env python3
"""
Web service wrapper for the redirect URL Lambda function.

Transforms the Lambda handler into a containerized microservice.
"""

from src.handlers.redirect_url import handler as lambda_handler
import json
import os
import sys
from flask import Flask, request, jsonify, redirect

# Add the src directory to Python path for imports
sys.path.insert(0, '/app/src')


# Initialize Flask application
app = Flask(__name__)

# Set default environment variables for containerized deployment
os.environ.setdefault('AWS_DEFAULT_REGION', 'us-east-1')


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint for container orchestration."""
    return jsonify({"status": "healthy", "service": "redirect"}), 200


@app.route('/<short_code>', methods=['GET'])
def redirect_url(short_code):
    """
    URL redirection endpoint.

    Transforms HTTP request into Lambda event format and handles redirects.
    """
    try:
        # Transform Flask request into Lambda event format
        lambda_event = {
            'httpMethod': 'GET',
            'path': f'/{short_code}',
            'headers': dict(request.headers),
            'body': None,
            'queryStringParameters': (dict(request.args)
                                      if request.args else None),
            'pathParameters': {'shortCode': short_code},
            'requestContext': {
                'requestId': 'container-request',
                'stage': 'prod'
            }
        }

        # Call the Lambda handler
        lambda_response = lambda_handler(lambda_event, None)

        # Handle different response types
        status_code = lambda_response.get('statusCode', 500)

        # If it's a redirect response (302), handle it specially
        if status_code == 302:
            location = lambda_response.get('headers', {}).get('Location')
            if location:
                return redirect(location, code=302)

        # For error responses, return JSON
        response_body = json.loads(lambda_response.get('body', '{}'))
        return jsonify(response_body), status_code

    except Exception as e:
        app.logger.error(f"Error processing redirect: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500


@app.route('/', methods=['GET'])
def root():
    """Root endpoint with service information."""
    return jsonify({
        "service": "tiny-url-redirect",
        "version": "1.0.0",
        "endpoints": {
            "GET /<short_code>": "Redirect to original URL",
            "GET /health": "Health check"
        }
    }), 200


if __name__ == '__main__':
    # Get port from environment variable or default to 8001
    port = int(os.environ.get('PORT', 8001))

    # Run the Flask application
    app.run(
        host='0.0.0.0',  # Listen on all interfaces for container networking
        port=port,
        debug=False,     # Disable debug mode in production
        threaded=True    # Enable threading for better performance
    )
