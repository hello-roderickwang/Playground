import {TherapyCategory, TherapySubcategory} from './therapy'

export type SessionActivityMode = 'evaluation' | 'therapy'

export interface SessionActivity {
	type: 'Activity'
	time: Date
	mode: SessionActivityMode
	cat: TherapyCategory | null
	subcat: TherapySubcategory | null
	activity: string
}

export function createSessionActivity (data: {[id: string]: any}): SessionActivity {
	if (data.type != null && data.type !== 'Activity') {
		throw new Error("Invalid type for Activity")
	}
	return {
		type: 'Activity',
		time: new Date(data.time),
		mode: data.mode,
		cat: data.cat,
		subcat: data.subcat,
		activity: data.activity
	}
}

export interface SessionStart {
	type: 'SessionStart'
	date: Date
}

export function createSessionStart (data: {[id: string]: any}): SessionStart {
	if (data.type != null && data.type !== 'SessionStart') {
		throw new Error("Invalid type for SessionStart")
	}
	return {
		type: 'SessionStart',
		date: new Date(data.date)
	}
}

export interface Session {
	date: Date
	activities: SessionActivity[]
}

export function createSession (data: {[id: string]: any} = {}): Session {
	return {
		date: data.date ? new Date(data.date) : new Date(),
		activities: data.activities ? data.activities.map(createSessionActivity) : []
	}
}
