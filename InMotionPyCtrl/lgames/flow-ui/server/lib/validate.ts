import {rxPatient} from '../models/patient'

// Validation regexps
export const rxClinician = /^[0-9A-Za-z_\-]+$/
export const rxProtocol = /^[0-9A-Za-z_\-]+$/
export const rxTherapy = /^[0-9A-Za-z_\-\/]+$/
export const rxRobot = /^[0-9A-Za-z_\-]+$/

export function validClinID (str: string) {
	return rxClinician.test(str)
}

export function validPatID (str: string) {
	return rxPatient.test(str)
}

// TODO: Test against whitelist
export function validProtocol (str: string) {
	return rxProtocol.test(str)
}

// TODO: Test against whitelist
export function validTherapy (str: string) {
	return rxTherapy.test(str)
}
