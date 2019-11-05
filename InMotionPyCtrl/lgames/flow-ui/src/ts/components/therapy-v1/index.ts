import * as m from 'mithril'
import * as stream from 'mithril/stream'
import D, {Dict} from '../../lib/dict'
import {PATIENT, CLINID} from '../../state'
import radio from '../widgets/radio'
import {openModal} from '../modal'

const protocols = stream<string[]>([])
const evaluations = stream(D<string>())
const therapies = stream(D<string>())

const protocol = stream<string>()
protocol.map(p => {
	loadTherapies(p)
	loadEvaluations(p)
})

const therapyId = stream('')

let loadingProtocols = false
let loadingTherapies = false
let loadingEvaluations = false

function loadProtocols() {
	if (loadingProtocols) {
		console.warn("Already loading protocols")
	}
	m.request<{protocols: string[]}>('/api/protocols').then(p => {
		loadingProtocols = false
		protocols(p.protocols)
		if (protocols().length > 0) {
			protocol(protocols()[0])
		}
	}).catch(err => {
		loadingProtocols = false
		console.warn("Error loading protocols:", err)
	})
}

function loadTherapies (prot: string) {
	if (loadingTherapies) {
		console.warn("Already loading therapies")
	}
	m.request<Dict<string>>('/api/therapies/' + prot).then(t => {
		loadingTherapies = false
		therapies(t)
		if (t && !D.isEmpty(t)) {
			therapyId(D.firstKey(t)!)
		} else {
			therapyId('')
		}
	}).catch(err => {
		loadingTherapies = false
		console.warn("Error loading therapies:", err)
	})
}

function loadEvaluations (prot: string) {
	if (loadingEvaluations) {
		console.warn("Already loading evaluations")
	}
	m.request<Dict<string>>('/api/evaluations/' + prot).then(t => {
		loadingEvaluations = false
		evaluations(t)
	}).catch(err => {
		loadingEvaluations = false
		console.warn("Error loading evaluations:", err)
	})
}

function launchClockGame (
	clinid: string, patid: string, protocol: string, therapy: string
) {
	m.request({
		url: '/api/game/clock',
		method: 'post',
		data: {clinid, patid, protocol, therapy}
	})
}

export default {
	oninit() {
		loadProtocols()
	},
	view() {
		const clinid = CLINID()
		const patient = PATIENT()
		return m('.therapy',
			m('.name-time-div', patient
				? `${patient.lastName}, ${patient.firstName} ID: ${patient.id}`
				: "Lastname, Firstname ID: "
			),
			m('.hr'),
			m('.tab-content',
				m('.tab-pane',
					m('div',
						m('.left-col',
							m('.h2-wrapper',
								m('h2', "Protocols")
							),
							m('.list-wrapper',
								protocols().map(p =>
									m(radio, {
										id: p, name: 'protocol', value: p,
										onclick (e: MouseEvent) {
											if ((e.currentTarget as HTMLInputElement).checked) {
												protocol(p)
											}
										}
									}, p)
								)
							)
						),
						m('.right-col',
							m('.h2-wrapper',
								m('h2', "Activities: " + protocol())
							),
							m('.therapy-wrapper',
								m('.h3-wrapper',
									m('h3', "Therapy"),
								),
								m('.list-wrapper',
									Object.keys(therapies()).map(id => {
										const t = therapies()[id]
										return m(radio, {
											id, name: 'therapy', value: id,
											onclick (e: MouseEvent) {
												if ((e.currentTarget as HTMLInputElement).checked) {
													therapyId(id)
												}
											}
										}, t)
									})
								)
							),
							m('.therapy-wrapper',
								m('.h3-wrapper',
									m('h3', "Evaluation"),
								),
								m('.list-wrapper',
									Object.keys(evaluations()).map(id => {
										const t = evaluations()[id]
										return m(radio, {
											id, name: 'therapy', value: id,
											onclick (e: MouseEvent) {
												if ((e.currentTarget as HTMLInputElement).checked) {
													therapyId(id)
												}
											}
										}, t)
									})
								)
							),
						)
					),
					m('div',
						m('button.btn-pill-blue',
							{
								disabled: !protocol() || !therapyId(),
								onclick() {
									if (!clinid || !patient) {
										openModal({title: "Clinician ID and Patient ID must be selected."})
										return
									}
									if (!protocol() || !therapyId()) {
										openModal({title: "Must select Protocol and Therapy/Evaluation"})
										return
									}
									launchClockGame(clinid, patient.id, protocol(), therapyId())
								}
							},
							"Start Robot Therapy"
						)
					)

				)
			)
		)
	}
}
