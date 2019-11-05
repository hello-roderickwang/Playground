import * as m from 'mithril'
import {createPatient} from '../../../../../server/models/patient'
import {PATIENT, SHOW_PATIENT_DETAILS} from '../../../state'
import {addPatient, addPatientID, startTherapySession} from '../../../actions/patient'
import patientForm from '../form'
import patientIdForm from '../form-add-id'
import {openModal} from '../../modal'

let submitting = false

function submitAddPatient (data: string | HTMLFormElement) {
	if (submitting) return
	submitting = true
	;(typeof data === 'string'
		? addPatientID(data)
		: addPatient(data)
	).then(pdata => {
		submitting = false
		PATIENT(createPatient(pdata))
		openModal({
			title: "Added patient ID " + pdata.id,
			buttons: [{id: 'ok', text: "Continue to Therapy Session"}],
			onclick(id) {
				startTherapySession(pdata.id)
				m.route.set('/robot/orientation')
			}
		})
	}).catch(err => {
		submitting = false
		openModal({
			title: err && err.message
				? err.message
				: 'There was an error adding this patient',
			buttons: [{id: 'ok', text: "Ok"}]
		})
		m.redraw()
	})
}

export default {
	view() {
		return m('.patient-management',
			m('.name-time-div', "Add New Patient"),
			m('.hr'),
			m('.tab-content',
				m('.tab-pane',
					m('div',
						m('.single-col',
							SHOW_PATIENT_DETAILS()
								? m(patientForm, { // Full form
									mode: 'add',
									onsubmit: submitAddPatient
								})
								: m(patientIdForm, { // ID only form
									onsubmit: submitAddPatient
								})
						)
					),
					m('.cta-wrapper-flex',
						m('button.btn-pill-blue.pull-left',
							{
								onclick() {
									m.route.set('/home')
								}
							},
							"Cancel"
						),
						m('button.btn-pill-blue',
							{
								type: 'button',
								disabled: submitting,
								onclick() {
									const form = document.querySelector('#form-patient') as any
									submitAddPatient(SHOW_PATIENT_DETAILS()
										? form
										: form.id.value
									)
								}
							},
							"Save and Start Therapy Session"
						)
					)
				)
			)
		)
	}
}
