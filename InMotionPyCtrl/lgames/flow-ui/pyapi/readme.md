# Python REST API for executing robot programs

This is a fallback API developed in case node.js proves troublesome spawning existing tcl, python, bash scripts.

## Install Python dependencies

First install `virtualenv` to your system if not already installed. Then in this repo directory:

	cd pyapi
	virtualenv flask
	flask/bin/pip install flask

## Start Python API

	source pyapi/flask/bin/activate
	python pyapi/app.py

Will run on port 5000 by default.
