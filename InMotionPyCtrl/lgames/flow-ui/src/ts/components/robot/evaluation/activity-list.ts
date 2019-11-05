import * as m from 'mithril'
import {Stream} from 'mithril/stream'
import {Activity} from '../../../../../server/models/therapy'
import radioArrow from '../../widgets/radio-arrow'
//import checkbox from '../../widgets/checkbox'

export interface Attrs {
	activities: Activity[]
	completed: boolean[]
	activityIndex: Stream<number>
}

//let lockedSequence = true

export default {
	view ({attrs: {activities, completed, activityIndex}}) {
		return m('.single-col',
			m('.h2-wrapper',
				m('h2', "Assessments")
			),
			/* m('.right-cta',
				m(checkbox,
					{
						name: 'edit-selection',
						id: 'edit-selection',
						value: 'edit-selection',
					},
					"Edit assessment selection"
				)
			), */
			m('.list-wrapper.test-options-list',
				activities.map((a, i) =>
					m('div',
						{
							class: 'list-item',
							id: 'activity-list-item-' + i
						},
						m(radioArrow,
							{
								name: 'activity',
								id: 'activity-' + a.id,
								value: a.id,
								checked: activityIndex() === i && !a.missing,
								disabled: a.missing,
								onclick() {activityIndex(i)}
							},
							a.label
						),
						/* m(checkbox,
							{
								name: 'activity',
								id: 'activity-checkbox-' + i,
								value: String(i),
								checked: true,
								disabled: lockedSequence || a.missing,
							}
						),
						m('.checkmark', {
							style: 'visibility:' + (completed[i] ? 'visible' : 'hidden')
						})*/
					)
				)
			)
		)
	}
} as m.Component<Attrs,{}>
