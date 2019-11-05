import * as m from 'mithril'
import {RangeOfMotion, rangeOfMotionMap, RANGES_OF_MOTION} from '../../../../../server/models/therapy'
import {rangeOfMotion} from '../../../protocols'
import radio from '../../widgets/radio'

export default {
	view() {
		return m('.left-col',
			m('.h2-wrapper',
				m('h2', 'Range of Motion')
			),
			m('.list-wrapper.range-of-motion-list',
				RANGES_OF_MOTION.map(range => {
					return m('.list-item',
						m(radio,
							{
								name: 'range-of-motion',
								id: 'range-of-motion-' + range,
								value: range.toString(),
								checked: range === rangeOfMotion(),
								onclick() {
									rangeOfMotion(range)
								}
							},
							rangeOfMotionMap[range]
						)
					)
				})
			),
			m('.img-wrapper', {
				style: `background-image: url(img/${rangeOfMotion() === 14 ? 'large' : 'small'}-circle.png)`,
			})
		)
	}
} as m.Component<{},{}>
