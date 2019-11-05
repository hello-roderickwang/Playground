import {Request, Response} from 'express-serve-static-core'
import {
	loadPatient, loadPatientsList, loadPatientIdsList,
	addNewPatient, updateExistingPatient, deletePatientFolder
} from '../lib/patient'

export function listPatients (req: Request, res: Response) {
	loadPatientsList().then(patients => {
		res.send({patients})
	}).catch(e => {
		console.warn("Error getting patients list:", e.message)
		res.status(e.httpStatus || 500).send({message: e.message})
	})
}

export function listPatientIds (req: Request, res: Response) {
	loadPatientIdsList().then(patients => {
		res.send({patients})
	}).catch(e => {
		console.warn("Error getting patient IDs:", e.message)
		res.status(e.httpStatus || 500).send({message: e.message})
	})
}

export function getPatient (req: Request, res: Response) {
	loadPatient(req.params.id).then(patient => {
		res.send(patient)
	}).catch(e => {
		console.warn("Error loading patient:", e.message)
		res.status(e.httpStatus || 500).send({message: e.message})
	})
}

export function addPatient (req: Request, res: Response) {
	addNewPatient(req.body).then(patient => {
		res.send(patient)
	}).catch(e => {
		console.warn("Error adding patient:", e.message)
		res.status(e.httpStatus || 500).send({message: e.message})
	})
}

export function updatePatient (req: Request, res: Response) {
	updateExistingPatient(req.body).then(patient => {
		res.send(patient)
	}).catch(e => {
		console.warn("Error updating patient:", e.message)
		res.status(e.httpStatus || 500).send({message: e.message})
	})
}

export function deletePatient (req: Request, res: Response) {
	deletePatientFolder(req.params.id).then(() => {
		res.send({status: 'ok'})
	}).catch(e => {
		console.warn("Error deleting patient:", e.message)
		res.status(e.httpStatus || 500).send({message: e.message})
	})
}
