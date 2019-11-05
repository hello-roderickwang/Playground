import * as m from 'mithril'
import {Stream} from 'mithril/stream'
import {Activity} from '../../../../../server/models/therapy'
import radio from '../../widgets/radio'
import radioArrow from '../../widgets/radio-arrow'
//import checkbox from '../../widgets/checkbox'

export interface Attrs {
	activities: Activity[]
	completed: boolean[]
	activityIndex: Stream<number>
}

export default {
	view ({attrs: {activities, completed, activityIndex}}) {
		return m('.activity-col',
			m('.h2-wrapper',
				m('h2', "Activities")
			),
			m('.list-wrapper.test-options-list',
				activities.map((a, i) =>
					m('div',
						{
							class: 'list-item',
							id: 'activity-list-item-' + i
						},
						m(a.type === 'game' ? radio : radioArrow,
							{
								name: 'activity',
								id: 'activity-' + a.id,
								value: a.id,
								checked: activityIndex() === i,
								disabled: a.missing,
								onclick() {activityIndex(i)}
							},
							a.label
						)
						/* m(checkbox,
							{
								name: 'activity',
								id: 'activity-checkbox' + a.id,
								value: a.id,
								disabled: a.missing,
							}
						),
						m('.checkmark', {
							style: 'visibility:' + (completed[i] ? 'visible' : 'hidden')
						}) */
					)
				)
			)
		)
	}
} as m.Component<Attrs,{}>
