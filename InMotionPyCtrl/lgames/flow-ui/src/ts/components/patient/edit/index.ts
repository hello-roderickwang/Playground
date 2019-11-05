import * as m from 'mithril'
import {createPatient} from '../../../../../server/models/patient'
import {PATIENT, SHOW_PATIENT_DETAILS} from '../../../state'
import {updatePatient} from '../../../actions/patient'
import patientForm from '../form'
import patientIdView from './patient-id'
import {openModal} from '../../modal'

let submitting = false

function submitUpdatePatient (form: HTMLFormElement) {
	if (submitting) return
	submitting = true
	updatePatient(form).then(pdata => {
		submitting = false
		PATIENT(createPatient(pdata))
		openModal({
			title: "Updated Patient ID " + pdata.id,
			buttons: [{id: 'ok', text: "Ok"}],
			onclick() {
				m.route.set('/patient/dashboard')
			}
		})
	}).catch(err => {
		submitting = false
		openModal({
			title: err && err.message
				? err.message
				: 'There was an error updating this patient',
			buttons: [{id: 'ok', text: "Ok"}]
		})
		m.redraw()
	})
}

export default {
	view() {
		const patient = PATIENT()
		if (!patient) {
			return m('.patient-management', "Error: No patient selected")
		}
		return m('.patient-management',
			m('.name-time-div', "Edit Patient"),
			m('.hr'),
			m('.tab-content',
				m('.tab-pane',
					m('div',
						m('.single-col',
							SHOW_PATIENT_DETAILS()
								// Show patient edit form
								? m(patientForm, {
									mode: 'edit',
									patient,
									onsubmit: submitUpdatePatient
								})
								// Only show patient ID
								: m(patientIdView, {patient})
						)
					),
					m('.cta-wrapper-flex',
						m('button.btn-pill-blue.pull-left',
							{
								onclick() {
									m.route.set('/patient/dashboard')
								}
							},
							"Cancel"
						),
						m('button.btn-pill-blue',
							{
								onclick() {
									if (!SHOW_PATIENT_DETAILS()) {
										// No edits happened - go straight back to dashboard
										m.route.set('/patient/dashboard')
									} else {
										submitUpdatePatient(
											document.querySelector('#form-patient') as HTMLFormElement
										)
									}
								}
							},
							"Save and Continue"
						)
					)
				)
			)
		)
	}
}
