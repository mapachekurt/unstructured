FROM quay.io/unstructured-io/base-images:wolfi-base-latest as base

USER root
WORKDIR /app

# Copy application files and dependencies
COPY ./requirements requirements/
COPY unstructured unstructured
COPY test_unstructured test_unstructured
COPY example-docs example-docs
COPY app.py app.py

# Adjust permissions and set up environment
RUN chown -R notebook-user:notebook-user /app && \
    apk add font-ubuntu git && \
    fc-cache -fv && \
    ln -s /usr/bin/python3.11 /usr/bin/python3

USER notebook-user

# Install Python dependencies from any requirements text files
RUN find requirements/ -type f -name "*.txt" -exec pip3.11 install --no-cache-dir --user -r '{}' ';'

# Install FastAPI and Uvicorn for serving the application
RUN pip3.11 install --user fastapi uvicorn[standard]

# Download and initialize Unstructured models
RUN python3.11 -c "from unstructured.nlp.tokenize import download_nltk_packages; download_nltk_packages()" && \
    python3.11 -c "from unstructured.partition.model_init import initialize; initialize()" && \
    python3.11 -c "from unstructured_inference.models.tables import UnstructuredTableTransformerModel; model = UnstructuredTableTransformerModel(); model.initialize('microsoft/table-transformer-structure-recognition')"

ENV PATH="${PATH}:/home/notebook-user/.local/bin"
ENV TESSDATA_PREFIX=/usr/local/share/tessdata

# Expose the port the FastAPI application will run on
EXPOSE 8000

# Run the FastAPI app using Uvicorn
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
