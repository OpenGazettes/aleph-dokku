FROM opengazettes/aleph:latest

ENV ELASTICSEARCH_INDEX aleph
ENV ALEPH_SETTINGS /aleph/code4africa_aleph_config.py
ENV KE_GAZETTE_ARCHIVE_URI: https://s3-eu-west-1.amazonaws.com/cfa-opengazettes-ke/gazettes/

COPY code4africa_aleph_config.py /aleph/code4africa_aleph_config.py
COPY requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

RUN mkdir /app
COPY CHECKS /app/CHECKS

WORKDIR /aleph

CMD gunicorn -w 5 -b 0.0.0.0:8000 --name aleph_gunicorn --log-level info --log-file /var/log/gunicorn.log --workers 1 --worker-class gevent --timeout 600 --max-requests 3000 --max-requests-jitter 100 aleph.manage:app
