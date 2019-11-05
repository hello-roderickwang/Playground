import * as m from 'mithril'
import {API_URL} from '../../config'
import {CLINID, PATIENT, ROBOT_BUSY, ROBOT_STATUS} from '../../state'
import {openModal} from '../modal'

let calibrating = false

function logout() {
	CLINID('')
	PATIENT(undefined)
	m.route.set('/')
}

export default {
	view() {
		const robotStatus = ROBOT_STATUS()
		const statusOk = robotStatus
			&& robotStatus.calibrationStatus === 'calibrated'
			&& robotStatus.readyStatus === 'ready'
		const statusOn = robotStatus && robotStatus.readyStatus === 'ready'
		return m('.launcher.home',
			m('.name-time-div', "Home"),
			m('.hr'),
			m('.launch-grid.launch-grid-top',
				calibrating || ROBOT_BUSY()
				? m('button',
					{type: 'button', disabled: true},
					m('span.icon',
						{style: 'background-image: url(img/icon-setuprobot.png)'},
					),
					m('span.text', "Calibrating...")
				)
				: m('button',
					{
						type: 'button',
						disabled: ROBOT_BUSY(),
						onclick() {
							openModal({
								title: "Set-up Robot",
								//content: statusOn
								//	? "WARNING: Remove the patient from the robot and ensure the workspace is clear."
								content: [
									m('p',
										"Press the START Button ",
										m('img.icon', {src: 'img/icon-start.svg'}),
										" on the Control Box on the right side of the table."
									),
									m('p',
										m('img.icon', {src: 'img/icon-warning.svg'}),
										" WARNING: Ensure that the patient is removed from the robot and the workspace is clear prior to robot setup."
									)
								],
								buttons: [
									{id: 'ok', text: 'Start'},
									{id: 'cancel', text: 'Cancel'}
								],
								onclick(id) {
									if (id === 'ok') {
										calibrateRobot()
									}
								}
							})
						}
					},
					m('span.icon',
						{style: 'background-image: url(img/icon-setuprobot.png)'},
					),
					m('span.text', "Set-up Robot")
				),
				m('button',
					{
						type: 'button',
						disabled: !statusOk,
						onclick() {m.route.set('/patient/add')}
					},
					m('span.icon', {
						style: 'background-image: url(img/icon-addpatient.png)'
					}),
					m('span.text', "Add a Patient")
				),
				m('button',
					{
						type: 'button',
						disabled: !statusOk,
						onclick() {m.route.set('/patient/search')}
					},
					m('span.icon',
						{style: 'background-image: url(img/icon-findpatient.png)'},
					),
					m('span.text', "Find a Patient")
				)
			),
			m('.launch-grid.launch-grid-bottom',
				m('button',
					{
						type: 'button',
						disabled: !PATIENT() || !statusOk,
						onclick() {m.route.set('/robot/reports')}
					},
					m('span.icon',
						{style: 'background-image: url(img/icon-report.png)'},
					),
					m('span.text', "Reports & Analytics")
				),
				m('button',
					{type: 'button', onclick() {m.route.set('/admin')}},
					m('span.icon',
						{style: 'background-image: url(img/icon-admin.png)'},
					),
					m('span.text', "Admin")
				),
				m('button',
					{
						type: 'button',
						onclick() {
							openModal({
								title: "Log Out",
								content: "Are you sure you want to log out?",
								buttons: [
									{id: "yes", text: "Yes"},
									{id: "no", text: "No"}
								],
								onclick(id) {
									if (id === 'yes') {
										logout()
									}
								}
							})
						}
					},
					m('span.icon',
						{style: 'background-image: url(img/icon-logout.png)'},
					),
					m('span.text', "Log Out")
				)
			)
		)
	}
}

function calibrateRobot() {
	calibrating = true
	setTimeout(() => {
		calibrating = false
		m.redraw()
	}, 2000)
	m.request({url: API_URL + '/calibrate', method: 'post'})
}
