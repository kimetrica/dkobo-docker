FROM python:2.7

# kobocat needs java, otherwise "Survey Publishing failed: pyxform odk validate dependency: java not found"
RUN apt-get update && apt-get install -y unzip nodejs npm coffeescript default-jre-headless sudo
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

ADD start_gunicorn.sh /dkobo/start_gunicorn.sh

EXPOSE 8000

CMD /dkobo/start_gunicorn.sh
