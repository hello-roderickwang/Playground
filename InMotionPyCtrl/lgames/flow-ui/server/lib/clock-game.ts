import * as path from 'path'
import {
	PROTOCOLS_HOME, LGAMES_HOME, CLOCK_GAME_FILENAME
} from '../config'
import {validClinID, validProtocol, validTherapy} from './validate'
import {patientExists} from './patient'
import {loadCurrentRobot, runRobot, RobotResult} from './robot'
import ImtError from './imt-error'

const CLOCK_GAME_DIR = path.join(LGAMES_HOME, 'clock')
const CLOCK_GAME_CMD = path.join(CLOCK_GAME_DIR, CLOCK_GAME_FILENAME)

export function runClockGame (
	clinid: string, patid: string, protocol: string, therapy: string
): Promise<RobotResult> {
	if (!validClinID(clinid)) {
		return Promise.reject(new ImtError('Invalid clinid', 406))
	}
	if (!validProtocol(protocol)) {
		return Promise.reject(new ImtError('Invalid protocol', 406))
	}
	if (!validTherapy(therapy)) {
		return Promise.reject(new ImtError('Invalid therapy', 406))
	}
	return patientExists(patid).then(exists => {
		if (!exists) {
			throw new ImtError('Invalid patid', 406)
		}
		return loadCurrentRobot()
	}).then(currentRobot => {
		// Build the game parameter
		const gameParam = path.join(
			PROTOCOLS_HOME, currentRobot, 'clock', protocol, therapy
		)
		return runRobot(CLOCK_GAME_CMD, [gameParam, patid], {
			cwd: CLOCK_GAME_DIR,
			env: {...process.env, PATID: patid, CLINID: clinid}
		})
	})
}
