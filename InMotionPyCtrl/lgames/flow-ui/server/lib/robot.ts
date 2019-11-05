import * as fs from 'fs-extra'
import * as path from 'path'
import {spawn, SpawnOptions} from 'child_process'
import {
	STATUS_CMD, CALIBRATE_CMD, ROBOTS_LIST_DIR,
	CURRENT_ROBOT_FILENAME, PROTOCOLS_HOME, LGAMES_HOME,
	NO_IMT_EXECUTABLES
} from '../config'
import state from '../state'
import comm from '../commroom'
import {RobotStatus} from '../models/robot'
import {filterDirectory} from './file-util'
import {Dict} from '../lib/dict'
import {waitMS} from '../lib/wait'
import {rxRobot, rxProtocol} from '../lib/validate'
import ImtError from './imt-error'
import {parseTclConfig} from '../lib/parse-tcl'

const LONG_TESTS: Dict<string> = {
	planar: `${PROTOCOLS_HOME}/planar/clock/adaptive/therapy/long_test`,
	planarhand: `${PROTOCOLS_HOME}/planarhand/clock/adaptivegrasp/therapy/long_test`,
	wrist: `${PROTOCOLS_HOME}/wrist/clock/adaptive/therapy/wr_long_test_ps`
}

const STATUS_THROTTLE = 5000
const STATUS_TYPE_DELAY = 1100

const robotStatus: RobotStatus = {
	time: 0,
	calibrationStatus: undefined,
	readyStatus: undefined
}

export interface RobotResult {
	code: number
	stdout: string
}

/**
 * Spawn a robot child process asynchronously.
 * Takes the same arguments as child_process.spawn.
 * Guards against attempting to run robot wile busy
 * and handles std output buffers.
 */
export function runRobot (
	cmd: string, params?: string[], opts?: SpawnOptions
): Promise<RobotResult> {
	if (state.robotBusy) {
		return Promise.reject(new ImtError('Robot is busy', 400))
	}
	let stdout = ''
	comm.room.send('robotbusy')
	return (
		// If checking status, wait til that's done before
		// starting robot task...
		state.checkingStatus ? waitMS(STATUS_TYPE_DELAY + 500) : Promise.resolve(0)
	).then(() => {
		if (NO_IMT_EXECUTABLES) {
			// For dev systems lacking real/mock IMT executables
			return new Promise<RobotResult>(resolve => { // for dev system with no executables
				setTimeout(() => {
					state.robotBusy = false
					comm.room.send('robotidle')
					resolve({code: 0, stdout: ''})
				}, 3000)
			})
		}
		// Run the robot program
		return new Promise<number>((resolve, reject) => {
			//console.log("Executing:")
			//console.log(cmd + (params ? ' ' + params.join(' ') : ''))
			const proc = spawn(cmd, params, opts)
			state.robotBusy = true
			proc.stdout.on('data', data => {
				const str = data.toString()
				console.log(str)
				stdout += str
			})
			proc.stderr.on('data', data => {
				console.warn(data.toString())
			})
			proc.on('error', err => {
				reject(err)
			})
			proc.on('exit', code => {
				resolve(code)
			})
		}).then(code => {
			state.robotBusy = false
			comm.room.send('robotidle')
			return {code, stdout}
		}).catch(err => {
			state.robotBusy = false
			comm.room.send('robotidle')
			throw err
		})
	})
}

export function runStatus (
	cmd: string, params?: string[], opts?: SpawnOptions
): Promise<RobotResult> {
	if (state.robotBusy) {
		return Promise.reject(new ImtError('Robot is busy', 400))
	}
	let stdout = ''
	if (NO_IMT_EXECUTABLES) {
		// For dev systems lacking real/mock IMT executables
		return new Promise<RobotResult>(resolve => { // for dev system with no executables
			setTimeout(() => {
				state.robotBusy = false
				comm.room.send('robotidle')
				resolve({code: 0, stdout: '1'})
			}, 100)
		})
	}
	// Run the robot status program
	return new Promise<number>((resolve, reject) => {
		//console.log("Executing:")
		//console.log(cmd + (params ? ' ' + params.join(' ') : ''))
		const proc = spawn(cmd, params, opts)
		proc.stdout.on('data', data => {
			const str = data.toString()
			//console.log(str)
			stdout += str
		})
		proc.stderr.on('data', data => {
			console.warn(data.toString())
		})
		proc.on('error', err => {
			reject(err)
		})
		proc.on('exit', code => {
			resolve(code)
		})
	}).then(code => {
		return {code, stdout}
	}).catch(err => {
		throw err
	})
}

/** Query a specific robot status */
export function getOneStatus (mode: 'calibration' | 'ready'): Promise<RobotStatus> {
	const cmdMode = mode === 'calibration' ? 'check-cal' : 'check-ready-lamp'
	return runStatus(STATUS_CMD, [cmdMode]).then(({code, stdout}) => {
		stdout = String(stdout).trim()
		const rval = Number(stdout)
		//console.log('ucplc ended with code:', code, 'result:', stdout)
		if (mode === 'calibration') {
			robotStatus.calibrationStatus = rval === 1 ? 'calibrated' : 'uncalibrated'
		} else {
			robotStatus.readyStatus = rval === 1 ? 'ready' : 'busy'
		}
		robotStatus.time = Date.now()
		return {...robotStatus}
	})
}

/** Return the complete robot status */
export function getStatus(): Promise<RobotStatus> {
	if (state.robotBusy) {
		return Promise.reject(new ImtError('Robot is busy', 400))
	}
	if (state.checkingStatus) {
		console.warn("Robot is already checking status")
		return Promise.resolve({...robotStatus})
	}
	const t = Date.now()
	if (t - robotStatus.time < STATUS_THROTTLE) {
		return Promise.resolve({...robotStatus})
	}
	state.checkingStatus = true
	return getOneStatus('ready').then(
		() => waitMS(STATUS_TYPE_DELAY)
	).then(
		() => getOneStatus('calibration')
	).then(status => {
		state.checkingStatus = false
		return status
	}).catch(err => {
		state.checkingStatus = false
		throw err
	})
}

export function calibrateRobot(): Promise<RobotResult> {
	return runRobot(CALIBRATE_CMD)
}

export function runLongTest() {
	return loadCurrentRobot().then(robot => {
		if (!LONG_TESTS[robot]) {
			throw new ImtError("long test not available for current robot", 500)
		}
		const cmd = '/usr/bin/wish'
		const params = [
			`${LGAMES_HOME}/clock/clock.tcl`,
			LONG_TESTS[robot],
			'test'
		]
		return runRobot(cmd, params)
	})
}

export function loadRobotsList() {
	return filterDirectory(
		ROBOTS_LIST_DIR,
		(f, s) => rxRobot.test(f) && s.isDirectory()
	).then(
		robots => robots.sort()
	)
}

export function loadCurrentRobot() {
	return fs.readFile(
		CURRENT_ROBOT_FILENAME,
		{encoding: 'utf8'}
	).then(str => {
		const robot = String(str).trim()
		if (!robot) {
			throw new ImtError("Current robot file empty", 500)
		}
		return robot
	})
}

export function saveCurrentRobot (robot: string) {
	if (!robot || !rxRobot.test(robot)) {
		Promise.reject(new ImtError('Invalid robot name', 400))
	}
	return loadRobotsList().then(robots => {
		if (robots.indexOf(robot) < 0) {
			console.warn('Unrecognized robot name: ', robot)
			throw new ImtError('Unrecognized robot name', 406)
		}
		return fs.writeFile(
			CURRENT_ROBOT_FILENAME,
			robot + '\n', // should include newline char(?)
			{encoding: 'utf8'}
		).then(() => robot)
	})
}

export function loadProtocolsList() {
	return loadCurrentRobot().then(
		robot => filterDirectory(
			path.join(PROTOCOLS_HOME, robot, 'clock'),
			(f, s) => rxProtocol.test(f) && s.isDirectory()
		)
	)
}

export function loadTherapiesList (protocol: string) {
	if (!rxProtocol.test(protocol)) {
		return Promise.reject(new ImtError(`Invalid protocol: '${protocol}'`, 406))
	}
	let dir: string
	return loadCurrentRobot().then(robot => {
		dir = path.join(PROTOCOLS_HOME, robot, 'clock', protocol)
		return fs.pathExists(dir)
	}).then(exists => {
		if (!exists) {
			throw new ImtError(`Protocol not found: '${protocol}'`, 404)
		}
		return fs.readFile(path.join(dir, 'therapy_list'), {encoding: 'utf8'})
	}).then(
		tcl => parseTclConfig(tcl)
	)
}

export function loadEvaluationsList (protocol: string) {
	if (!rxProtocol.test(protocol)) {
		return Promise.reject(new ImtError(`Invalid protocol: '${protocol}'`, 406))
	}
	let dir: string
	return loadCurrentRobot().then(robot => {
		dir = path.join(PROTOCOLS_HOME, robot, 'clock', protocol)
		return fs.pathExists(dir)
	}).then(exists => {
		if (!exists) {
			throw new ImtError(`Protocol not found: '${protocol}'`, 404)
		}
		return fs.readFile(path.join(dir, 'eval_list'), {encoding: 'utf8'})
	}).then(
		tcl => parseTclConfig(tcl)
	)
}
