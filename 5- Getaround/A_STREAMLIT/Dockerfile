FROM continuumio/miniconda3

WORKDIR /home/app

RUN apt-get update && apt-get install -y nano unzip curl

RUN curl -fsSL https://get.deta.dev/cli.sh | sh

COPY requirements.txt /dependencies/requirements.txt
RUN pip install --no-cache-dir -r /dependencies/requirements.txt

COPY . /home/app

#EXPOSE 8501

#CMD ["streamlit", "run", "--server.port=$PORT", "app.py"]


#COPY start.sh /home/app/start.sh
RUN chmod +x /home/app/start.sh

CMD ["/home/app/start.sh"]