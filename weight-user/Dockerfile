# Base image
FROM python:3.12-slim AS python-base-requirements

# App image
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

# Final image
FROM python-base-requirements AS python-base-requirements-app
WORKDIR /app
COPY ./src .
CMD ["python", "user-server.py"]   
