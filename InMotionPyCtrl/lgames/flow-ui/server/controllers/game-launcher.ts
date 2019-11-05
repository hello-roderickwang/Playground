// Games launcher
import {Request, Response} from 'express-serve-static-core'
import {runGame} from '../lib/game'

export function launchGame (req: Request, res: Response) {
	const game = req.params.game
	runGame(
		req.body.clinid, req.body.patid, game
	).then(() => {
		res.send({status: 'ok'})
	}).catch (e => {
		console.warn(`Failed to run game '${game}':`, e.message)
		res.status(e.statusCode || 500).send({message: e.message})
	})
}
