FROM maquchizi/opengazettes-aleph:latest

ENV ELASTICSEARCH_INDEX aleph
ENV ALEPH_SETTINGS /aleph/code4sa_aleph_config.py
ENV KE_GAZETTE_ARCHIVE_URI: https://s3-eu-west-1.amazonaws.com/cfa-opengazettes-ke/gazettes/

COPY code4sa_aleph_config.py /aleph/code4sa_aleph_config.py
COPY requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

RUN mkdir /app
COPY CHECKS /app/CHECKS

WORKDIR /aleph

CMD newrelic-admin run-program gunicorn --workers 1 --worker-class gevent --timeout 600 --max-requests 3000 --max-requests-jitter 100 --log-file - --access-logfile - aleph.manage:app
