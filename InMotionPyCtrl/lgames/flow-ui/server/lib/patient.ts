import * as fs from 'fs-extra'
import * as path from 'path'
import {THERAPIST_HOME} from '../config'
import {
	Patient, createPatient, rxPatient
} from '../models/patient'
import D, {Dict} from './dict'
import {filterDirectory} from './file-util'
import {validPatID} from './validate'
import ImtError from './imt-error'

export function patientExists (patientId: string) {
	if (!validPatID) {
		return Promise.resolve(false)
	}
	const dir = path.join(THERAPIST_HOME, patientId)
	//console.log(dir)
	return fs.pathExists(dir).then(exists => {
		return exists
			? fs.lstat(dir).then(s => s.isDirectory())
			: false
	})
}

/** Load existing Patient details */
export function loadPatient (patientId: string) {
	if (!rxPatient.test(patientId)) {
		return Promise.reject(new ImtError("Invalid patient ID", 406))
	}
	const dir = path.join(THERAPIST_HOME, patientId)
	let fname: string
	return fs.pathExists(dir).then(exists => {
		if (!exists) {
			throw new ImtError("Patient ID not found.", 404)
		}
		fname = path.join(dir, 'patient.json')
		return fs.pathExists(fname)
	}).then(exists => exists
		? fs.readFile(fname, {encoding: 'utf8'}).then(json => {
			let data: Dict<any>
			try {
				data = JSON.parse(json)
			} catch (e) {
				console.warn("Warning: Failed to parse patient.json file for patient " + patientId)
				data = {id: patientId}
			}
			return data
		})
		: {id: patientId}
	).then(
		data => createPatient(data)
	)
}

/** Create & save a new patient directory & file. */
export function addNewPatient (data: Dict<any>) {
	// Validate and create a valid patient object
	let patient: Patient
	try {
		patient = createPatient(data)
	} catch (e) {
		return Promise.reject(e)
	}
	// Test if this patient ID already exists
	const dir = path.join(THERAPIST_HOME, patient.id)
	return fs.pathExists(dir).then(exists => {
		if (exists) {
			console.warn(`Patient directory already exists for ID ${patient.id}`)
			throw new ImtError('Patient directory already exists.', 400)
		}
		return fs.mkdir(dir)
	}).then(
		() => fs.writeFile(
			path.join(dir, 'patient.json'), JSON.stringify(patient),
			{encoding: 'utf8'}
		)
	).then(
		() => patient
	)
}

/** Update existing patient data */
export function updateExistingPatient (data: Dict<any>) {
	let patient: Patient
	return patientExists(data.id).then(exists => {
		if (!exists) {
			throw new ImtError("Patient ID not found", 404)
		}
		patient = createPatient(data)
		return fs.writeFile(
			path.join(THERAPIST_HOME, patient.id, 'patient.json'),
			JSON.stringify(patient),
			{encoding: 'utf8'}
		)
	}).then(
		() => patient
	)
}

/** Load the list of patients IDs. */
export function loadPatientIdsList() {
	return filterDirectory(
		THERAPIST_HOME,
		(f, s) =>  rxPatient.test(f) && s.isDirectory()
	).then(
		patIds => patIds.sort()
	)
}

/** Load list of full patient details (only ID if no json file present) */
export function loadPatientsList() {
	return loadPatientIdsList().then(
		patids => Promise.all(
			patids.map(patid => {
				const fname = path.join(THERAPIST_HOME, patid, 'patient.json')
				return fs.pathExists(fname).then(exists => exists
					? fs.readFile(fname, {encoding: 'utf8'}).then(json => {
						let data: Dict<any>
						try {
							data = JSON.parse(json)
						} catch (e) {
							console.warn("Failed to parse patient.json for patient ID: ", patid)
							data = {id: patid}
						}
						return data
					})
					: {id: patid}
				)
			})
		)
	).then(
		patObjs => patObjs.map(createPatient)
	)
}

/** Delete patient folder and all files within */
export function deletePatientFolder (id: string) {
	return patientExists(id).then(exists => {
		if (!exists) {
			throw new ImtError("Patient ID not found", 404)
		}
		return fs.remove(
			path.join(THERAPIST_HOME, id)
		)
	})
}
