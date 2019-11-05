import * as m from 'mithril'
import * as stream from 'mithril/stream'
import {
	RangeOfMotion, Activity, ActivityMap, ActivityGroupID, activityMap
} from '../../server/models/therapy'
import D, {Dict} from './lib/dict'
import {recordActivity} from './actions/patient'

export type ProtocolMap = Dict<{
	therapies: Dict<string>,
	evaluations: Dict<string>
}>

export type RobotMode = 'orientation' | 'therapy' | 'evaluation' | 'reports'

export const protocolMap: ProtocolMap = {}

export const rangeOfMotion = stream<RangeOfMotion>(14)

let loadingProtocols = false

function validateActivity (a: Activity, pmap: ProtocolMap) {
	// Special case for games
	if (a.type === 'game') return
	if (!D.has(pmap, a.protocol)) {
		console.warn(`protocol '${a.protocol}' not found.`)
		a.missing = true
	} else {
		const d = a.type === 'eval' ? pmap[a.protocol].evaluations : pmap[a.protocol].therapies
		if (!D.has(d, `${a.type}/${a.id}`)) {
			console.warn(`activity type: '${a.type}' id: ${a.id} missing`)
			a.missing = true
		}
	}
}

function validateActivityMap (amap: ActivityMap, pmap: ProtocolMap) {
	Object.keys(amap).forEach((group: keyof ActivityMap) => {
		amap[group].activities.forEach(a => {
			validateActivity(a, pmap)
		})
	})
}

/**
 * Ensure that all hard-coded UI activities correspond to
 * existing protocols, therapies and evaluations.
 */
export function loadProtocols(): Promise<ProtocolMap> {
	if (loadingProtocols) {
		console.warn("Already loading protocols")
		return Promise.resolve(protocolMap)
	}
	if (D.size(protocolMap) > 0) {
		// Use already loaded protocols
		return Promise.resolve(protocolMap)
	}
	return m.request<{protocols: string[]}>({
		url: '/api/protocols',
		background: true
	}).then(({protocols}) => {
		loadingProtocols = false
		protocols.forEach(k => {
			protocolMap[k] = {
				therapies: {},
				evaluations: {}
			}
		})
		return Promise.all(
			protocols.map(
				_p => loadTherapies(_p).then(th => {
					protocolMap[_p].therapies = th
					return th
				})
			).concat(protocols.map(
				_p => loadEvaluations(_p).then(ev => {
					protocolMap[_p].evaluations = ev
					return ev
				}))
			)
		).then(
			() => {
				console.log('validating protocolMap:', protocolMap)
				validateActivityMap(activityMap, protocolMap)
				return protocolMap
			}
		)
	}).catch(err => {
		loadingProtocols = false
		console.warn("Error loading protocols:", err)
		throw err
	})
}

function loadTherapies (prot: string) {
	return m.request<Dict<string>>({
		url: '/api/therapies/' + prot, background: true
	})
}

function loadEvaluations (prot: string) {
	return m.request<Dict<string>>({
		url: '/api/evaluations/' + prot, background: true
	})
}

/**
 * Start a therapy activity (clock)
 */
export function startActivity (
	clinid: string, patid: string, activityGroupId: ActivityGroupID, activity: Activity
) {
	return launchClockGame(
		clinid, patid, activity.protocol, activity.type + '/' + activity.id
	).then(() => {
		if (activityGroupId !== 'orientation') {
			// Only record non-orientation activities
			recordActivity(patid, {
				mode: activityGroupId,
				cat: activity.cat || null,
				subcat: activity.subcat || null,
				activity: activity.id,
				range: activity.range
			})
		}
	}).catch(err => {
		console.warn("Error running therapy:", err.message)
	})
}

/**
 * Launch clock game therapy
 */
function launchClockGame (
	clinid: string, patid: string, protocol: string, therapy: string
): Promise<void> {
	return m.request({
		url: '/api/game/clock',
		method: 'post',
		data: {clinid, patid, protocol, therapy}
	}).then(() => {}).catch(err => {
		console.warn("Error launching clock game:", err)
	})
}

/**
 * Launch one of the game activities
 */
export function startGame (
	clinid: string, patid: string, gameId: string
): Promise<void> {
	return m.request({
		url: '/api/game/' + gameId,
		method: 'post',
		data: {clinid, patid}
	}).then(() => {
		recordActivity(patid, {
			mode: 'therapy',
			cat: 'games',
			subcat: 'games',
			activity: gameId,
			range: '14'
		})
	}).catch(err => {
		console.warn(`Error launching game '${gameId}': `, err)
	})
}
