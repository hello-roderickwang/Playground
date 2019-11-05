import * as m from 'mithril'
import {API_URL} from '../../config'
import {CLINID, PATIENT} from '../../state'
import {openModal} from '../modal'

export default {
	view() {
		return m('.games',
			m('h1', "Games"),
			m('.games-grid',
				m('button.gamesbtn1',
					{onclick() {m.route.set('/game-clock')}},
					"Games Console"
				),
				m('button.gamesbtn2',
					{onclick() {launch('cs')}},
					"CS"
				),
				m('button.gamesbtn3',
					{onclick() {launch('pick')}},
					"Pick"
				),
				m('button.gamesbtn4',
					{onclick() {launch('pong')}},
					"Pong"
				),
				m('button.gamesbtn5',
					{onclick() {launch('race')}},
					"Race"
				),
				m('button.gamesbtn6',
					{onclick() {launch('squeegee')}},
					"Squeegee"
				),
			),
			m('button',
				{onclick() {window.history.back()}},
				"Back to Home"
			),
		)
	}
}

/** Launches a game */
function launch (id: string) {
	const clinid = CLINID()
	const patient = PATIENT()
	if (!clinid || !patient) {
		//alert("Must select Clinician ID and Patient ID.")
		openModal({
			title: "Error",
			content: "You must select a Patient ID and Clinician ID.",
			buttons: [
				{id: "ok", text: "Okay"}
			]
		})
		return
	}
	m.request({
		//url: `${API_URL}/game/${id}/${CLINID()}/${PATID()}`
		url: `${API_URL}/game/${id}`,
		method: 'post',
		data: {clinid, patid: patient.id}
	})
}
