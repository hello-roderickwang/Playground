import * as fs from 'fs-extra'
import * as path from 'path'
import {THERAPIST_HOME, THERAPY_HISTORY_FILENAME} from '../config'
import {
	createSessionActivity, createSessionStart, Session, createSession
} from '../models/therapy-session'
import {patientExists} from './patient'
import ImtError from './imt-error'

export function appendStartSession (patid: string): Promise<void> {
	return patientExists(patid).then(exists => {
		if (!exists) {
			throw new ImtError("Invalid Patient ID", 406)
		}
		const ss = createSessionStart({date: new Date()})
		const fname = path.join(THERAPIST_HOME, patid, THERAPY_HISTORY_FILENAME)
		return fs.appendFile(fname, JSON.stringify(ss) + '\n')
	})
}

export function appendActivity (
	patid: string, data: {[id: string]: any}
): Promise<void> {
	return patientExists(patid).then(exists => {
		if (!exists) {
			throw new ImtError("Invalid Patient ID", 406)
		}
		const activity = createSessionActivity({
			...data, type: 'Activity', time: new Date()
		})
		const fname = path.join(THERAPIST_HOME, patid, THERAPY_HISTORY_FILENAME)
		return fs.appendFile(fname, JSON.stringify(activity) + '\n')
	})
}

export function loadTherapyHistory (patid: string): Promise<Session[]> {
	const fname = path.join(THERAPIST_HOME, patid, THERAPY_HISTORY_FILENAME)
	return patientExists(patid).then(exists => {
		if (!exists) {
			throw new ImtError("Invalid Patient ID", 406)
		}
		return fs.pathExists(fname)
	}).then(exists => {
		return exists
			? fs.readFile(fname, {encoding: 'utf8'}).then(
				str => parseTherapyHistory(str)
			)
			: []
	})
}

function parseTherapyHistory (str: string): Session[] {
	const lines = str.split('\n').filter(line => !!line.trim())
	const sessions: Session[] = []
	let session: Session | undefined
	lines.forEach(line => {
		const data = JSON.parse(line)
		if (data.type === 'SessionStart') {
			if (session) {
				sessions.push(session)
			}
			const sstart = createSessionStart(data)
			session = createSession({date: sstart.date})
		} else if (data.type === 'Activity') {
			if (!session) {
				throw new ImtError("Read activitiy before session start", 500)
			}
			session.activities.push(createSessionActivity(data))
		} else {
			console.warn("Failed to parse line in therapy history with unknown type:", line)
			throw new ImtError("Got line with unknown type", 500)
		}
	})
	// Must add last one
	if (session) {
		sessions.push(session)
	}
	return sessions
}

/*

File format:

{type: "sessionStart", "date": "2017-01-01T11:02:00.000Z"}
{type: "activity", "time": "2017-01-01T11:02:00.000Z", "mode": "orientation", "protocol": "10cm", "activityType": "therapy", "activity": "oneway_rec"}
{type: "activity", "time": "2017-01-01T11:02:00.000Z", "mode": "orientation", "protocol": "10cm", "activityType": "therapy", "activity": "oneway_rec"}
{type: "activity", "time": "2017-01-01T11:02:00.000Z", "mode": "orientation", "protocol": "10cm", "activityType": "therapy", "activity": "oneway_rec"}
{type: "sessionStart", "date": "2017-01-01T11:02:00.000Z"}
{type: "activity", "time": "2017-01-01T11:02:00.000Z", "mode": "orientation", "protocol": "10cm", "activityType": "therapy", "activity": "oneway_rec"}
{type: "activity", "time": "2017-01-01T11:02:00.000Z", "mode": "orientation", "protocol": "10cm", "activityType": "therapy", "activity": "oneway_rec"}
...

*/
