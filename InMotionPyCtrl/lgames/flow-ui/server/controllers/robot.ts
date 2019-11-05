import {Request, Response} from 'express-serve-static-core'
import {
	loadCurrentRobot, saveCurrentRobot, loadRobotsList,
	loadProtocolsList, loadEvaluationsList, loadTherapiesList,
	calibrateRobot as calibrate, getStatus, runLongTest
} from '../lib/robot'

export function getCurrentRobot (req: Request, res: Response) {
	loadCurrentRobot().then(current_robot => {
		res.send({current_robot})
	}).catch(e => {
		console.warn("Error getting current_robot:", e.message)
		res.status(e.httpStatus || 500).send({message: e.message})
	})
}

export function getRobotStatus (req: Request, res: Response) {
	getStatus().then(result => {
		res.send(result)
	}).catch(e => {
		console.warn("Error getting robot status:", e.message)
		res.status(e.httpStatus || 500).send({message: e.message})
	})
}

export function setCurrentRobot (req: Request, res: Response) {
	saveCurrentRobot(req.body.current_robot).then(current_robot => {
		res.send({current_robot})
	}).catch(e => {
		console.warn("Error setting current_robot:", e.message)
		res.status(e.httpStatus || 500).send({message: e.message})
	})
}

export function listRobots (req: Request, res: Response) {
	loadRobotsList().then(robots => {
		res.send({robots})
	}).catch(e => {
		console.warn("Error listing robots:", e.message)
		res.status(e.httpStatus || 500).send({message: e.message})
	})
}

export function listProtocols (req: Request, res: Response) {
	loadProtocolsList().then(protocols => {
		res.send({protocols})
	}).catch(e => {
		console.warn("Error listing protocols:", e.message)
		res.status(e.httpStatus || 500).send({message: e.message})
	})
}

export function listTherapies (req: Request, res: Response) {
	loadTherapiesList(req.params.protocol).then(therapies => {
		res.send(therapies)
	}).catch(e => {
		console.warn("Error listing therapies:", e.message)
		res.status(e.httpStatus || 500).send({message: e.message})
	})
}

export function listEvaluations (req: Request, res: Response) {
	loadEvaluationsList(req.params.protocol).then(evaluations => {
		res.send(evaluations)
	}).catch(e => {
		console.warn("Error listing evaluations:", e.message)
		res.status(e.httpStatus || 500).send({message: e.message})
	})
}

export function calibrateRobot (req: Request, res: Response) {
	calibrate().then(result => {
		res.send({status: 'ok'})
	}).catch(e => {
		res.status(e.httpStatus || 500).send({message: e.message})
	})
}

export function longTest (req: Request, res: Response) {
	runLongTest().then(result => {
		res.send({status: 'ok'})
	}).catch(e => {
		res.status(e.httpStatus || 500).send({message: e.message})
	})
}
