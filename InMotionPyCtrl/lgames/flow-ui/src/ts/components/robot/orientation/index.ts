import * as m from 'mithril'
import * as stream from 'mithril/stream'
import {Activity, activityMap} from '../../../../../server/models/therapy'
import {startActivity, rangeOfMotion} from '../../../protocols'
import {CLINID, PATIENT} from '../../../state'
import {openModal} from '../../modal'
import rangeList from './range-list'
import activityList from './activity-list'

const orientation: m.FactoryComponent<{}> = function() {
	let activities: Activity[] = []
	let completed: boolean[] = []
	const activityIndex = stream(0)
	const rangeStream = rangeOfMotion.map(r => {
		activities = activityMap.orientation.activities.filter(a => a.range === r)
		completed = activities.map(() => false)
		activityIndex(0)
		return r
	})

	/* Attempt to start orientatio activity */
	function start() {
		const patient = PATIENT()
		const clinid = CLINID()
		if (clinid && patient) {
			const activity = activities[activityIndex()]
			startActivity(
				// Use patient ID 'test' so the software won't
				// record analytics data to this patient folder.
				// (Orientation data should not be recorded)
				clinid, 'test', 'orientation', activity
			).then(() => {
				const i = activityIndex()
				completed[i] = true
				if (i < activities.length - 1) {
					activityIndex(i + 1)
					m.redraw()
					// Make sure this item is scrolled into view
					const el = document.getElementById('activity-list-item-' + i) as HTMLElement
					el && el.scrollIntoView({behavior: 'smooth'})
				}
			})
		} else {
			openModal({
				title: "No clinid or patient selected",
				buttons: [{id: 'ok', text: "Ok"}]
			})
		}
	}

	function onremove() {
		rangeStream.end(true)
	}

	function view() {
		return m('.tab-content',
			m('.tab-pane',
				m('div',
					m(rangeList),
					m(activityList, {
						activities, activityIndex, completed
					})
				),
				m('.cta-wrapper-flex',
					m('button.btn-pill-blue.btn-arrow',
						{
							onclick: start
						},
						m('span', "Start Orientation")
					)
				)
			)
		)
	}

	return {onremove, view}
}

export default orientation
