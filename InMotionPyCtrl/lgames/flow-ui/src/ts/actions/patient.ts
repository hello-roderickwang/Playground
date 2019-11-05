import * as m from 'mithril'
import {Patient, createPatient} from '../../../server/models/patient'
import {Session, createSession} from '../../../server/models/therapy-session'
import {Dict} from '../lib/dict'

export function addPatient (form: Dict<any>): Promise<Patient> {
	let patient: Patient
	const data = {
		id: form.id.value,
		firstName: form.firstName.value,
		lastName: form.lastName.value,
		birthDate: form.birthDate.value,
		gender: form.gender.value,
		dateOnset: form.dateOnset.value,
		impairmentSide: form.impairmentSide.value,
		diagnosis: form.diagnosis.value,
		typeLocation: form.typeLocation.value,
		otherImpairments: form.otherImpairments.value,
		precautions: form.precautions.value,
		positioningConsiderations: form.positioningConsiderations.value
	}
	try {
		patient = createPatient(data)
	} catch (e) {
		console.warn("Invalid patient data:", e.message)
		return Promise.reject({message: 'Invalid patient field: ' + e.message})
	}
	return m.request({
		url: '/api/patient',
		method: 'post',
		data: patient
	})
}

export function addPatientID (id: string): Promise<Patient> {
	let patient: Patient
	const data = {id}
	try {
		patient = createPatient(data)
	} catch (e) {
		console.warn("Invalid patient data:", e.message)
		return Promise.reject({message: 'Invalid patient field: ' + e.message})
	}
	return m.request({
		url: '/api/patient',
		method: 'post',
		data: patient
	})
}

export function updatePatient (form: Dict<any>): Promise<Patient> {
	let patient: Patient
	const data = {
		id: form.id.value,
		firstName: form.firstName.value,
		lastName: form.lastName.value,
		birthDate: form.birthDate.value,
		gender: form.gender.value,
		dateOnset: form.dateOnset.value,
		impairmentSide: form.impairmentSide.value,
		diagnosis: form.diagnosis.value,
		typeLocation: form.typeLocation.value,
		otherImpairments: form.otherImpairments.value,
		precautions: form.precautions.value,
		positioningConsiderations: form.positioningConsiderations.value
	}
	try {
		patient = createPatient(data)
	} catch (e) {
		console.warn("Invalid patient data")
		return Promise.reject({message: 'Invalid patient data'})
	}
	return m.request({
		url: '/api/patient',
		method: 'patch',
		data: patient
	})
}

export function deletePatient (patid: string) {
	return m.request<any>({
		url: '/api/patient/' + patid,
		method: 'DELETE'
	})
}

export function loadTherapyHistory (patid: string) {
	return m.request<{sessions: Session[]}>({
		url: '/api/report/therapy-history/' + patid
	}).then(({sessions}) => {
		return sessions.filter(
			// Filter out obsolete format therapy records
			(s: any) => !s.protocol
		).map(createSession)
	}).catch(e => {
		console.warn("Failed to load therapy history:", e.message)
		return Promise.reject("Failed to load therapy history")
	})
}

export function startTherapySession (patid: string): Promise<void> {
	return m.request<any>({
		url: '/api/report/start-therapy-session/' + patid,
		method: 'post'
	}).then(() => {}).catch(err => {
		console.warn("Error starting therapy session:", err.message)
	})
}

export function recordActivity(
	patid: string, activity: Dict<any>
): Promise<void> {
	return m.request({
		url: '/api/report/add-activity/' + patid,
		method: 'post',
		data: activity
	}).then(() => {}).catch(err => {
		console.warn("Error recording activity:", err.message)
	})
}
