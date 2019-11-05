import * as path from 'path'
import {LGAMES_HOME} from '../config'
import D from '../lib/dict'
import {validClinID} from './validate'
import {patientExists} from './patient'
import {loadCurrentRobot, runRobot, RobotResult} from './robot'
import ImtError from './imt-error'

const GAMES = ['cs', 'pick', 'pong', 'race', 'squeegee']
const GAME_DIRS = D<string>()
const GAME_CMDS = D<string>()
GAMES.forEach(game => {
	GAME_DIRS[game] = path.join(LGAMES_HOME, game)
	GAME_CMDS[game] = path.join(LGAMES_HOME, game, `run${game}`)
})

export function runGame (
	clinid: string, patid: string, game: string
): Promise<RobotResult> {
	if (!validClinID(clinid)) {
		return Promise.reject(new ImtError('Invalid clinid', 406))
	}
	const gameCmd = GAME_CMDS[game]
	if (!gameCmd) {
		return Promise.reject(new ImtError('Invalid game', 406))
	}
	const gameDir = GAME_DIRS[game]
	return patientExists(patid).then(exists => {
		if (!exists) {
			throw new ImtError('Invalid patid', 406)
		}
		return loadCurrentRobot()
	}).then(currentRobot => {
		return runRobot(gameCmd, [], {
			cwd: gameDir,
			env: {...process.env, PATID: patid, CLINID: clinid}
		})
	})
}
