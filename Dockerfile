FROM python:2.7

# kobocat needs java, otherwise "Survey Publishing failed: pyxform odk validate dependency: java not found"
RUN apt-get update && apt-get install -y unzip nodejs npm coffeescript default-jre-headless
# npm install scripts look for node binary, in Debian upon which the official
# python image is built it's called nodejs
RUN ln -vs /usr/bin/nodejs /usr/bin/node

ADD https://github.com/kimetrica/dkobo/archive/2.015.46.zip /dkobo.zip

RUN unzip dkobo.zip && mv dkobo-2.015.46 dkobo

WORKDIR /dkobo
RUN pip install -r requirements.txt

# bower doesn't like to be run as root. There is an option to override,
# but it's better to just use an unprivileged user.
RUN useradd --create-home dkobo
RUN chown -R dkobo.dkobo /dkobo
USER dkobo

# installing packages from package.json
RUN npm install
RUN node_modules/bower/bin/bower install
RUN ./node_modules/grunt-cli/bin/grunt build

# this will create a local sqlite database, which is OK for testing but not
# deployment obviously
ADD admin_user_fixture.json /dkobo/admin_user_fixture.json
RUN python manage.py syncdb --noinput
RUN python manage.py migrate
# we used --noinput to not be prompted for a superuser, which means we have to
# create one ourselves. It's not possible to set a password non-interactively, so
# the best way is to use a fixture for the superuser.
RUN python manage.py loaddata /dkobo/admin_user_fixture.json

EXPOSE 8000

# this will be used for a redirect when forms have been submitted to kobocat
# from dkobo. So this can't be kobocat hostname because it doesn't exist in
# docker host system
ENV KOBOCAT_URL http://localhost:9000
ENV KOBOCAT_INTERNAL_URL http://localhost:9000
# we need to use localhost here and not enketo hostname because the browser is redirected
ENV ENKETO_SERVER http://localhost:8005

# this is to preserve sqlite db. Using directory to make sure there is no problem due to inode change etc.
VOLUME /dkobo

CMD python manage.py runserver 0.0.0.0:8000
