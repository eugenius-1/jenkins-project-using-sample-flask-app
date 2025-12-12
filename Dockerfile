FROM python:3.12-alpine3.23


WORKDIR /app

COPY requirements.txt /app

RUN pip install -r requirements.txt

COPY . /app

EXPOSE 5000

CMD [ "python", "run.py" ]