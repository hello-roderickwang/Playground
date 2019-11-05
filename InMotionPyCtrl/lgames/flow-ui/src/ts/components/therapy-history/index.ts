import * as m from 'mithril'
import * as stream from 'mithril/stream'
import {Stream} from 'mithril/stream'
import {
	Activity, activityMap, therapyCategoryMap, therapySubcategoryMap
} from '../../../../server/models/therapy'
import {
	Session, SessionActivity
} from '../../../../server/models/therapy-session'
import {dateStr, timeStr} from '../../lib/date'
import therapySession from './session'
import {PATIENT} from '../../state'
import {loadTherapyHistory} from '../../actions/patient'

const sessions = stream<Session[]>([])
const viewSession = stream<Session | undefined>()

interface SessionItem {
	mode: string
	protocol: string
	activity: string
}

/** Given an activity session log data return a label */
function activityLabel (activities: Activity[], sa: SessionActivity) {
	const a = activities.find(
		a => sa.cat == a.cat && sa.subcat == a.subcat && sa.activity === a.id /* tslint:disable-line triple-equals */
	)
	return a ? a.label : sa.activity
}

/** Converts raw session data to readable items */
const sessionItems: Stream<SessionItem[] | undefined> = viewSession.map(s =>
	s ? s.activities.map(a => ({
		mode: a.mode === 'therapy' ? therapyCategoryMap[a.cat!] || 'Therapy' : 'Evaluation',
		protocol: a.subcat ? therapySubcategoryMap[a.subcat] : '',
		activity: activityLabel(activityMap[a.mode].activities, a)
	}))
	: undefined
)

function loadHistory() {
	sessions([])
	const patient = PATIENT()
	if (!patient) {
		console.warn("No patient selected")
		return
	}
	loadTherapyHistory(patient.id).then(sessions)
}

export default {
	oninit() {
		loadHistory()
	},
	view() {
		const ssItems = sessionItems()
		return m('.therapy-history',
			m('.name-time-div', "Therapy History"),
			m('.hr'),
			m('.tab-content',
				m('.tab-pane',
					m('div',
						m('.single-col',
							m('table',
								m('thead',
									m('tr',
										m('th', "Session Date"),
										m('th', "Session Time"),
										m('th', "")
										//m('th', "")
									)
								),
								m('tbody',
									sessions().map(s => m(session, {session: s})),
								)
							)
						)
					)
				)
			),
			!!ssItems && m(therapySession, {
				content: m('table.session',
					m('tr',
						m('th', "Mode"),
						m('th', "Protocol"),
						m('th', "Activity")
					),
					ssItems.map(item =>
						m('tr',
							m('td', item.mode),
							m('td', item.protocol),
							m('td', item.activity)
						)
					)
				),
				onclose() {
					viewSession(undefined)
				}
			})
		)
	}
}

const session: m.Component<{session: Session},{}> = {
	view({attrs: {session}}) {
		return m('tr',
			m('td', dateStr(session.date)),
			m('td', timeStr(session.date)),
			m('td',
				m('button.btn-blue',
					{
						onclick() {
							viewSession(session)
						}
					},
					"View"
				)
			)
			/* m('td',
				m('button.btn-blue.btn-arrow',
					{
						onclick() {
							m.route.set('/robot/orientation')
						}
					},
					"Repeat This Session"
				)
			) */
		)
	}
}
