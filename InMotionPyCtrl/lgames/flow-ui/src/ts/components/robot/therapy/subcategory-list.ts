import * as m from 'mithril'
import {Stream} from 'mithril/stream'
import {
	TherapyCategory, TherapySubcategory, activityMap, therapySubcategoryMap
} from '../../../../../server/models/therapy'
import {rangeOfMotion} from '../../../protocols'
import radio from '../../widgets/radio'

export interface Attrs {
	category: Stream<TherapyCategory>
	subcategory: Stream<TherapySubcategory>
}

const subcategoryList: m.FactoryComponent<Attrs> = function(
	{attrs: {category, subcategory}}
) {
	const activities = activityMap.therapy.activities
	// Need to rebuild subcatetories list whenever parent category changes
	const subcategories = category.map(c => {
		return (Object.keys(therapySubcategoryMap) as TherapySubcategory[])
			.filter(sc =>
				activities.some(
					a => a.subcat === sc && a.cat === c && a.range === rangeOfMotion()
				)
			)
			.map(sc => ({
				id: sc,
				label: therapySubcategoryMap[sc]
			}))
	})

	function onremove() {
		subcategories.end(true)
	}

	function view () {
		return m('.subcategory-col',
			m('.h2-wrapper',
				m('h2', 'Protocol')
			),
			m('.list-wrapper',
				subcategories().map(subcat =>
					m('.list-item',
						m(radio,
							{
								name: 'therapy-subcat',
								id: 'therapy-subcat-' + subcat.id,
								value: subcat.id,
								checked: subcategory() === subcat.id,
								onclick() {subcategory(subcat.id)}
							},
							subcat.label
						)
					)
				)
			)
		)
	}

	return {onremove, view}
}

export default subcategoryList
