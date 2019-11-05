import * as m from 'mithril'
import * as stream from 'mithril/stream'
import D from '../../../lib/dict'
import {lift} from '../../../lib/stream'
import {CLINID, PATIENT} from '../../../state'
import {TherapyCategory, therapyCategoryMap, Activity, activityMap} from '../../../../../server/models/therapy'
import {startActivity, startGame, rangeOfMotion} from '../../../protocols'
import {openModal} from '../../modal'
import categoryList from './category-list'
import subcategoryList from './subcategory-list'
import activityList from './activity-list'

const therapyComponent: m.FactoryComponent<{}> = function activityComponent() {
	let activities: Activity[] = []
	let completed: boolean[] = []
	const activityIndex = stream(0)
	const category = stream<TherapyCategory>(
		D.firstKey(therapyCategoryMap) as TherapyCategory
	)
	const subcategory = category.map(c => {
		const subcats = activityMap.therapy.activities
			.filter(a => a.range === rangeOfMotion() && a.cat === c)
			.map(a => a.subcat)
		return subcats[0]!
	})

	// For therapies, activities list needs to be filtered
	// by rangeOfMotion as well as categories, subcategories
	const filterStream = lift(
		(r, c, s) => {
			activities = activityMap.therapy.activities.filter(
				a => a.range === r && a.cat === c && a.subcat === s
			)
			completed = activities.map(() => false)
			activityIndex(0)
			// Make sure the top activity is scrolled into view
			setTimeout(() => {
				const el = document.getElementById('activity-list-item-0') as HTMLElement
				el && el.scrollIntoView({behavior: 'smooth'})
			}, 60)
		},
		rangeOfMotion, category, subcategory
	)

	/** Attempt to start therapy activity */
	function start() {
		const patient = PATIENT()
		const clinid = CLINID()
		if (clinid && patient) {
			const activity = activities[activityIndex()]
			;(activity.type === 'game'
				? startGame(clinid, patient.id, activity.id)
				: startActivity(clinid, patient.id, 'therapy', activity)
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
		filterStream.end(true)
	}

	function view() {
		return m('.tab-content',
			m('.tab-pane',
				m('div',
					m(categoryList, {category}),
					m(subcategoryList, {category, subcategory}),
					m(activityList, {
						activities, completed, activityIndex
					})
				),
				m('.cta-wrapper-flex',
					m('button.btn-pill-blue.btn-arrow',
						{
							onclick: start
						},
						m('span', "Start Therapy"),
					)
				)
			)
		)
	}

	return {onremove, view}
}

export default therapyComponent
