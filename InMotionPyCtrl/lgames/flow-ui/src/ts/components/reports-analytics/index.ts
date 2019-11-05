import * as m from 'mithril'

export default {
	view() {
		return m('.launcher.patient-dashboard',
			m('.name-time-div', "Reports & Analytics"),
			m('.hr'),
			m('.launch-grid.launch-grid-top',
				m('button',
					{
						type: 'button',
						disabled: true,
						onclick() {
							m.route.set('/')
						}
					},
					m('span.icon',
						{style: 'background-image: url(img/icon-analytics.png)'},
					),
					m('span.text', "Analytics")
				),
				m('button',
					{type: 'button', onclick() {m.route.set('/robot/reports')}},
					m('span.icon',
						{style: 'background-image: url(img/icon-report-lg.png)'},
					),
					m('span.text', "Reports")

				)
			)
		)
	}
}
