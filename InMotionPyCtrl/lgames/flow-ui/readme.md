# Bionik InMotion UI

*For system interaction documentation, see the file `system.md` in this repo.*

*For a list of system changes the new UI requires, see the file `system-changes.md`.*

## Install:

Clone this git repo to your computer.

### Prerequisites

Install [node.js](https://nodejs.org/). (Includes `npm` package manager.)

[Additional notes](https://nodejs.org/en/download/package-manager/) for Linux installs.

Quick summary for Ubuntu:

	$ curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
	$ sudo apt-get install nodejs

After that, the commands `node` and `npm` should be available. Eg:

	$ node --version
	$ npm --version

### Recommended VSCode editor extensions

* eslint
* EditorConfig
* tslint
* postcss-sugarss-language

### Install the node.js, Electron app dependencies

in the repo root directory:

	$ npm install

This will install the app's dependencies listed in `package.json`. The folder `node_modules` will be created and those package files will live there. The `node_modules` directory should be excluded from git repos.

### Optional configuration overrides

This software relies on some assumed environment variables to be set. (See `system.md` for more details.)

When running on computer that does not have the typical IMT configuration, you may use a `.env` file to set some custom environment variables that will be available to this application. See the file `.env-example`. Make a copy of that file called `.env` and make changes as needed.

A properly configured IMT system should not require the use of the `.env` file.

## Mocking an IMT system on a development computer

A mock filesystem can be used to mimick the robot system. To mock an IMT system on a development PC, use the following .env:

	ROBOT_HOME=./mock-imt/opt/imt/robot
	LGAMES_HOME=./mock-imt/opt/imt/robot/lgames
	PROTOCOLS_HOME=./mock-imt/opt/imt/robot/protocols
	CROB_HOME=./mock-imt/opt/imt/robot/crob
	I18N_HOME=./mock-imt/opt/imt/i18n
	IMAGES_HOME=./mock-imt/opt/imt/images
	THERAPIST_HOME=./mock-imt/home/imt/therapist
	IMT_CONFIG=./mock-imt/home/imt/imt/robot4/imt_config

## Compile, serve, rebuild on save:

In the project root directory:

If you have previously run a `build`, then first you should remove old compiled files:

	$ npm run clean

Then to start the dev server and compilers/file watchers:

	$ npm start

This is a script command in the `package.json` file. This simply runs `node app/index`. This starts the node server app, which will be running on the configured port (port 3000 by default.)

In a browser, go to `http://localhost:3000` (use the configured port.)

You should see a screen with 3 buttons: "Launch 1", "Launch 2", "Launch 3". Each of these buttons will execute its associated command (as configured in `app/config.js`.)

To end the server, press `ctrl-c` in the terminal.

## Run the Electron app:

Build the application first with:

	$ npm run build

Then execute the `run.sh` script.

## Addtional System Configurations

See: `system-changes.md`
