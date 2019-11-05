import * as m from 'mithril'
import {Stream} from 'mithril/stream'
import {TherapyCategory, activityMap, therapyCategoryMap} from '../../../../../server/models/therapy'
import {rangeOfMotion} from '../../../protocols'
import radio from '../../widgets/radio'

export interface Attrs {
	category: Stream<TherapyCategory>
}

const categoryList: m.FactoryComponent<Attrs> = function({attrs: {category}}) {
	const activities = activityMap.therapy.activities
	const categories = (Object.keys(therapyCategoryMap) as TherapyCategory[])
		.filter(c =>
			activities.some(a => a.cat === c && a.range === rangeOfMotion())
		)
		.map(c => ({
			id: c,
			label: therapyCategoryMap[c]
		}))

	function view () {
		return m('.category-col',
			m('.h2-wrapper',
				m('h2', 'Mode')
			),
			m('.list-wrapper',
				categories.map(cat =>
					m('.list-item',
						m(radio,
							{
								name: 'therapy-cat',
								id: 'therapy-cat-' + cat.id,
								value: cat.id,
								checked: category() === cat.id,
								onclick() {category(cat.id)}
							},
							cat.label
						)
					)
				)
			)
		)
	}

	return {view}
}

export default categoryList
