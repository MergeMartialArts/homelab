FROM ghcr.io/paperless-ngx/paperless-ngx:latest

RUN apt-get update \
    && apt-get install -y \
       tesseract-ocr-tha \
    && rm -rf /var/lib/apt/lists/*