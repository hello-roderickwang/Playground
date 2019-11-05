import * as m from 'mithril'
import {API_URL} from '../../config'
import {ROBOT_STATUS, ROBOT_BUSY, SHOW_PATIENT_DETAILS} from '../../state'
import {openModal} from '../modal'
import checkbox from '../widgets/checkbox'

export default {
	view() {
		const robotStatus = ROBOT_STATUS()
		const statusOk = robotStatus
			&& robotStatus.calibrationStatus === 'calibrated'
			&& robotStatus.readyStatus === 'ready'
		return m('.launcher.patient-dashboard',
			m('.name-time-div', "Admin"),
			m('.hr'),
			m('.launch-grid.launch-grid-top',
				m('button',
					{
						type: 'button',
						disabled: ROBOT_BUSY(),
						onclick() {m.route.set('/patient/folders')}
					},
					m('span.icon',
						{style: 'background-image: url(img/icon-managepatient.png)'},
					),
					m('span.text', "Manage Patient Files")
				),
				m('button',
					{
						type: 'button',
						disabled: !statusOk || ROBOT_BUSY(),
						onclick: runLongTest
					},
					m('span.icon',
						{style: 'background-image: url(img/icon-report-lg.png)'},
					),
					m('span.text', "Long Test")
				),
				m('.additional-options-wrapper',
					m(checkbox,
						{
							name: 'show',
							id: 'show-patient-info',
							value: 'patient-info',
							checked: SHOW_PATIENT_DETAILS(),
							onclick(e: MouseEvent) {
								SHOW_PATIENT_DETAILS(!SHOW_PATIENT_DETAILS())
							}
						},
						"Show Patient Info Section"
					)
				)
			)
		)
	}
}

function runLongTest() {
	if (ROBOT_BUSY()) {
		console.warn("Cannot run long test - robot busy")
		return
	}
	ROBOT_BUSY(true)
	m.request({
		url: API_URL + '/long-test',
		method: 'post'
	}).then(() => {
		ROBOT_BUSY(false)
	}).catch(e => {
		openModal({
			title: "Error running long test",
			content: e.message,
			buttons: [
				{id: 'ok', text: "Ok"}
			],
			onclick() {ROBOT_BUSY(false)}
		})
	})
}
