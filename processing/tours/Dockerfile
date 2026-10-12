FROM python:3.12-slim-bookworm
RUN apt-get update && apt-get install -y --no-install-recommends hugin-tools enblend ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY worker.py .
RUN useradd --uid 10001 --create-home worker
USER 10001
ENV PYTHONUNBUFFERED=1 OMP_NUM_THREADS=4
ENTRYPOINT ["python","/app/worker.py"]
