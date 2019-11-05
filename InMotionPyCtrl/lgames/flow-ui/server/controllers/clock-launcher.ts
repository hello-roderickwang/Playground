import {Request, Response} from 'express-serve-static-core'
import {runClockGame} from '../lib/clock-game'

export function launchClockGame (req: Request, res: Response) {
	runClockGame(
		req.body.clinid, req.body.patid,
		req.body.protocol, req.body.therapy
	).then(() => {
		res.send({status: 'ok'})
	}).catch (e => {
		console.warn("Failed to run clock game:", e.message)
		res.status(e.statusCode || 500).send({message: e.message})
	})
}
