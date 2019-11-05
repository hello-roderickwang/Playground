# IMT System Documentation & Notes

This document contains an overview of the existing IMT systems that the new UI interacts with. This overview is limited to the scope of systems that the UI interacts with. Other low level systems and programs are not covered.

## System environment variables

The following environment variables are assumed to be set:

	ROBOT_HOME=/opt/imt/robot
	LGAMES_HOME=/opt/imt/robot/lgames
	PROTOCOLS_HOME=/opt/imt/robot/protocols
	CROB_HOME=/opt/imt/robot/crob
	I18N_HOME=/opt/imt/i18n
	IMAGES_HOME=/opt/imt/images
	THERAPIST_HOME=/home/imt/therapist
	IMT_CONFIG=/home/imt/imt/robot4/imt_config

(The software will use whatever paths those variables are set to. The values above are typical but may vary on installed systems.)

## Robot Status

The following program can be run to check robot status:

	$CROB_HOME/tools/ucplc <mode>

Where `mode` can be `check-cal` or `check-ready`

Output values of "1" or "1.0" should be interpreted as calibrated or ready. Other values (eg: "0") mean not calibrated or not ready.

Use `ucplc -h` for a full list of options.

## Game Launcher

Legacy software executes:

	$LGAMES_HOME/choosegame/cg.tcl

And displays the following grid of icons:

	clock   cs     pick

	pong    race   squeegee

(The above will be replaced by the new UI application. `cons` was the old Clock launcher UI.)

### Launching specific games

Each game can be launched by executing the corresponding command: (excepting clock which is a special case)

* cs (maze) `$LGAMES_HOME/cs/runcs`
* pick `$LGAMES_HOME/pick/runpick`
* pong `$LGAMES_HOME/pong/runpong`
* race `$LGAMES_HOME/race/runrace`
* squeegee `$LGAMES_HOME/race/runrace`

The current working directory must be set to the respective game's directory.

Each of the above expect 2 environment variables to be set:

`PATID` - Patient ID, which matches a folder name within the `therapist` folder

`CLINID` - Clinician ID, a 2-character identifier.

Each game spawns its own window.

### Launching the Clock game

The clock game is launched with by:

	$LGAMES_HOME/clock/clock.tcl gamename patid

*Note:* Current working directory must be set to `$LGAMES_HOME/clock`

`gamename` is custructed like so:

	$PROTOCOLS_HOME/[currentRobot]/clock/[protocol]/[therapy]

**Andy's notes:** This is the full path file name in the therapy_list or eval_list, that is also the name of the file in the protocols tree that has the variables for the chosen game. You need to construct the gamename from the pieces indicating which robot, which game, which protocol, which type (eval or therapy), and which game (from the entry list).

`patid` is passed both on the command line and as an env variable

So the full command would be:

	$LGAMES_HOME/clock/clock.tcl $PROTOCOLS_HOME/<current-robot>/<game-name>/<protocol>/<type>/<gametaskname> $PATID

Example:

	/opt/imt/robot/lgames/clock/clock.tcl /opt/imt/robot/protocols/planar/clock/adaptive/therapy/adaptive_1 test

(things in `<angle-brackets>` here are descriptions of local variables, not true names)

	$LGAMES_HOME /opt/imt/robot/lgames
	$PROTOCOLS_HOME /opt/imt/robot/protocols
	<current-robot> planar
	<game-name> clock
	<protocol> adaptive
	<type> therapy
	<gametaskname> adaptive_1
	$PATID test

---

## List of robots:

	imt/protocols/
		[types of robots]
		planar/
			clock/
		linear/
			clock/
		planarhand/
			clock/
		etc..

---

## Protocols

are configured by robot4/config/config.tcl

Configs saved in

	~/imt_config

First read robot from

	~/imt_config/current_robot

Then based on current robot, read from:

	~/imt_config/planar/robot.cfg

Use the list in:

	planar,clock,proto,sellist {...}

To set the current protocol write to:

	~/imt_config/robots/planar/clock/current_protocol.cfg

Env variables: (runs automatically on system startup)

	~/imt_config/imt.rc

---

## Therapy/Evaluation:

The lists of therapies and evaluations are found in:

	/opt/imt/robot/protocols/planar/clock/adaptive
		therapy_list
		eval_list

To invoke clock game, pass: `therapy/oneway_rec_1`

Whenever changing protocols, re-populate the therapies/evaluation list using that directory

---

## Patient Data

Historically patient data (including logs output by robot programs) has been stored in:

	~/imt/therapist

Which is a symlink that points to:

	~/Private/therapist

Each patient is stored in a folder with the same name as the Patient ID. This is typically used in the environment variable `$PATID` to identify the current patient to various programs.

So a patient's data would be found in `~/imt/therapist/<patientid>`

The Clinician ID is stored in the environment variable `$CLINID`.

The new UI layer is adding new files to this folder:

`patient.json` will contain patient information in the following JSON format:

	{
		"id": "zsmith",
		"firstName": "Zeke",
		"lastName": "Smith",
		"birthDate": "1990-03-15T00:00:00.000Z",
		"gender": "M",
		"impairmentSide": "left",
		"dateOnset": "2014-06-19T00:00:00.000Z",
		"typeLocation": "Type/Location text",
		"diagnosis": "Diagnosis text",
		"otherImpairments": "Other impairments text.",
		"precautions": "Precautions text.",
		"positioningConsiderations": "Positioning Text"
	}

`notes.json` will contain notes in the format:

	{
		"notes": [
			{
				"date": "2017-07-22T12:30:00.000Z",
				"text": "Note text 1"
			},
			{
				"date": "2017-07-23T15:00:00.000Z",
				"text": "Note text 2"
			},
			{
				etc...
			}
		]
	}
