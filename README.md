# Aleph in Dokku

This is one of three primary mechanisms for Code for Africa to run Aleph inside Dokku. There are three aspects:

1. aleph-dokku - web interface
2. [aleph-dokku-worker](https://github.com/opengazettes/aleph-dokku-worker) - runs background tasks
3. [aleph-dokku-beat](https://github.com/opengazettes/aleph-dokku-beat) - scheludes background tasks using Celery Beat

This repo uses Dokku's Dockerfile support to build an image based on our [customised version of Aleph](https://github.com/opengazettes/aleph) which
is built using [Docker Hub](http://hub.docker.com/r/opengazettes/aleph/).

Here's a spiffy diagram:

               +-------------+   +-------------+                         
               | Dockerfile  |   | aleph repo  |                         
               | aleph-base  |   |             |                         
               +------+------+   +------+------+                 upstream
                      |                 |            --------------------
                      |                 |                        opengazettes
                      |          +------+------+                         
                      |          | aleph repo  |                         
                      |   +------+             |                         
                      |   |      +-------------+                         
               +------+---|--+                                           
               | Dockerfile  +--------------------------------+          
           +---+ aleph       +---------+                      |          
           |   +-------------+         |                      |          
           |                           |                      |          
    +------+-----+          +----------+---------+  +---------+---------+
    | Dokku      |          | Dokku              |  | Dokku             |
    | aleph      |          | aleph-dokku-worker |  | aleph-dokku-beat  |
    +------------+          +--------------------+  +-------------------+

## Development

Developing against the prod cluster isn't very practical because of the need to tunnel connections to ElasticSearch.

The aleph repo has an example docker-compose file which sets up all the dependencies to run a full cluster locally. It's super convenient. You can modify it (it even supports relative paths) to map the assets in this repo into the container for local development.

You can for example configure it like this from the aleph repo clone directory

Modify the web service like this
```
  web:
      build: ../aleph-dokku
      ports:
        - "13376:8000"
      links:
        - postgres
        - elasticsearch
        - rabbitmq
      volumes:
        - "/:/host"
        - "./logs:/var/log"
        - "../aleph-dokku/code4africa_aleph_config.py:/aleph/code4africa_aleph_config.py"
        - "./filestore:/aleph/filestore"
      environment:
        ALEPH_ELASTICSEARCH_URI: http://elasticsearch:9200/
        ALEPH_DATABASE_URI: postgresql://aleph:aleph@postgres/aleph
        ALEPH_BROKER_URI: amqp://guest:guest@rabbitmq:5672
        ALEPH_SETTINGS: /aleph/code4africa_aleph_config.py
      env_file:
        - aleph.env
```

aleph.env
```
# Name needs to be a slug, as it is used e.g. for the ES index, SQS queue name:
ALEPH_APP_NAME=aleph
ALEPH_FAVICON=https://investigativedashboard.org/static/favicon.ico
ALEPH_APP_URL=http://localhost:13376
ALEPH_LOGO=http://assets.pudo.org/img/logo_bigger.png

# Random string:
ALEPH_SECRET_KEY=oru239cn293uner923unc130nc
ALEPH_URL_SCHEME=http

# Expects Google OAuth credentials to be set up:
# https://console.developers.google.com/apis/credentials?
# Source host would be http://localhost:13376
# and the redirect URL would be http://localhost:13376/api/1/sessions/callback

ALEPH_OAUTH_KEY=...
ALEPH_OAUTH_SECRET=...

GOOGLE_OAUTH_KEY=...
GOOGLE_OAUTH_SECRET=...

FACEBOOK_OAUTH_KEY=...
FACEBOOK_OAUTH_SECRET=...

# Where and how to store the underlying files:
ALEPH_ARCHIVE_TYPE=file
ALEPH_ARCHIVE_BUCKET=cfa-opengazettes-ke

# Or, if 'ALEPH_ARCHIVE_TYPE' configuration is 'file':
ALEPH_ARCHIVE_PATH=/aleph/filestore
```

## Deployment

```
dokku config:set aleph ALEPH_APP_NAME=opengazettes_ke \
    ALEPH_APP_TITLE="Open Gazettes Kenya" \
    ALEPH_ARCHIVE_BUCKET=cfa-opengazettes-ke \
    ALEPH_BROKER_URI=amqp://... \
    ALEPH_DATABASE_URI=postgres://... \
    ALEPH_ELASTICSEARCH_URI=http://... \
    ALEPH_FAVICON=https://opengazettes.or.ke/favicon.ico \
    ALEPH_LOGO=https://opengazettes.org.za/img/icon-openbook.png \
    ALEPH_OAUTH_KEY=... \
    ALEPH_OAUTH_SECRET=... \
    ALEPH_SECRET_KEY=... \
    ALEPH_URL_SCHEME=https \
    AWS_ACCESS_KEY_ID=... \
    AWS_SECRET_ACCESS_KEY=... \
    FACEBOOK_OAUTH_KEY=... \
    FACEBOOK_OAUTH_SECRET=... \
    GOOGLE_OAUTH_KEY=... \
    GOOGLE_OAUTH_SECRET=... \
    KE_GAZETTE_ARCHIVE_URI=https://s3-eu-west-1.amazonaws.com/cfa-opengazettes-ke/gazettes/ \
    POLYGLOT_DATA_PATH=/opt/aleph/data

dokku docker-options:add aleph run,deploy  "-v /var/log/aleph:/var/log"
dokku docker-options:add aleph run,deploy  "-v /var/lib/aleph:/opt/aleph/data"
```

Then push this repo to your dokku remote:

    git push dokku

**Note:**

If you make changes to the underlying `opengazettes/aleph` image, you must run `docker pull opengazettes/aleph` on the server before running `git push dokku` so that the remote picks up changes to the image.
