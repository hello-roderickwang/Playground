import {spawn, ChildProcess} from 'child_process'
import * as username from 'username'
import {Request, Response} from 'express-serve-static-core'
import {LOGOUT_SYSTEM_CMD} from '../config'
import {Dict} from '../lib/dict'

const logoutParams: Dict<string[]> = {
	qdbus: ['org.kde.ksmserver', '/KSMServer', 'logout', '0', '3', '3'],
	loginctl: ['terminate-user', username.sync()],
	'xfce4-session-logout': ['--logout']
}

export function logout (req: Request, res: Response) {
	let proc: ChildProcess
	try {
		proc = spawn(
			LOGOUT_SYSTEM_CMD, logoutParams[LOGOUT_SYSTEM_CMD],
			{detached: true}
		)
	} catch (e) {
		console.warn("Error attempting to logout:", e.message)
		res.status(500).send({message: "Error logging out: " + e.message})
		return
	}
	// Log stdout to console
	proc.stdout.on('data', data => {
		console.log(data.toString())
	})
	proc.on('error', err => {
		console.warn("Error logging out:", err.message)
	})
	proc.on('close', data => {
		process.exit()
	})
	// HTTP response to client
	res.send({status: 'ok'})
}
