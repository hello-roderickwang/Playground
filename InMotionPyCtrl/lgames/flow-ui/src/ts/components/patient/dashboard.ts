import * as m from 'mithril'
import {PATIENT} from '../../state'

export default {
	view() {
		//const patient = PATIENT()
		return m('.launcher.patient-dashboard',
			m('.name-time-div', "Patient Dashboard"),
			m('.hr'),
			m('.launch-grid.launch-grid-top',
				m('button',
					{
						type: 'button',
						onclick() {m.route.set('/therapy-history')}
					},
					m('span.icon',
						{style: 'background-image: url(img/icon-history.png)'},
					),
					m('span.text', "Therapy History")
				),
				m('button',
					{
						type: 'button',
						onclick() {m.route.set('/robot/reports')}
					},
					m('span.icon',
						{style: 'background-image: url(img/icon-report-lg.png)'},
					),
					m('span.text', "View Reports")
				),
				m('button',
					{
						type: 'button',
						onclick() {m.route.set('/patient/edit')}
					},
					m('span.icon',
						{style: 'background-image: url(img/icon-managepatient.png)'},
					),
					m('span.text', "Edit Patient")
				)
			),
 			/* m('.launch-grid.launch-grid-top',
				m('button',
					{
						type: 'button',
						//disabled: true,
						onclick() {m.route.set('/patient/notes')}
					},
					m('span.icon',
						{style: 'background-image: url(img/icon-note.png)'},
					),
					m('span.text', "Patient Notes")
				),
			), */
			m('.btn-pill-blue-wrapper',
				m('button.btn-pill-blue',
					{
						onclick() {
							// startTherapySession(PATIENT()!.id)
							m.route.set('/robot/orientation')
						},
						type: 'button'
					},
					"Return to Therapy"
				)
			)
		)
	}
}
