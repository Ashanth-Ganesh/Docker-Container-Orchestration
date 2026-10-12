FROM python:3.13-alpine

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app

COPY scripts.py /app/scripts.py
COPY IF-1.txt /home/data/IF.txt
COPY AlwaysRememberUsThisWay-2.txt /home/data/AlwaysRememberUsThisWay.txt
RUN mkdir -p /home/data/output

CMD ["python", "/app/scripts.py"]
