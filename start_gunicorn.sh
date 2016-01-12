#!/bin/bash
# python manage.py collectstatic --noinput

exec gunicorn -t 800 -w 4 -b 0.0.0.0:8000 dkobo.wsgi:application
