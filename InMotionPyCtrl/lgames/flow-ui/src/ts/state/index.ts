import * as m from 'mithril'
import * as stream from 'mithril/stream'
import {API_URL} from '../config'
import {Patient} from '../../../server/models/patient'
import {RobotStatus} from '../../../server/models/robot'

export const PATIENT = stream<Patient | undefined>()
export const CLINID = stream<string>()
export const REPORT_GENERATED = PATIENT.map(() => false)
export const ROBOT_STATUS = stream<RobotStatus | undefined>()
export const ROBOT_BUSY = stream<boolean>(false)
ROBOT_BUSY.map(() => {m.redraw()})

export const SHOW_PATIENT_DETAILS = stream(false)

// Setup socket to get robot status updates

const socket = io()

socket.on('robotbusy', () => {
	console.log("robot busy")
	ROBOT_BUSY(true)
})

socket.on('robotidle', () => {
	console.log("robot idle")
	ROBOT_BUSY(false)
})

export function pollRobotStatus() {
	return m.request<RobotStatus>(API_URL + '/status').then(status => {
		ROBOT_STATUS(status)
	}).catch(err => {
		console.warn("Error fetching robot status.")
		ROBOT_STATUS(undefined)
	})
}
