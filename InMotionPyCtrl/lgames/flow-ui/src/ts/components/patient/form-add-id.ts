import * as m from 'mithril'
import D from '../../lib/dict'

export type FormMode = 'add'

export interface Attrs {
	onsubmit(id: string): any
}

/**
 * ID-only patient add form
 */
const patientForm: m.FactoryComponent<Attrs> = function patientForm() {
	const patient = D<any>()

	function view (onsubmit: (id: string) => any) {
		return m('form',
			{
				id: 'form-patient',
				onsubmit(e: Event) {
					e.preventDefault()
					console.log('submitting:', patient)
					onsubmit(patient.id)
				}
			},
			m('.patient-info-left-col',
				m('.input-container',
					m('label', {for: 'id'},
						m('span', "Patient ID "),
						m('span', {style: 'color: #FFDD99'}, "*mandatory")
					),
					m('input', {
						type: 'text', id: 'id', name: 'id',
						maxLength: 30,
						value: patient.id,
						oninput: m.withAttr('value', id => {patient.id = String(id)})
					})
				)
			),
			m('.patient-info-right-col')
		)
	}

	return {
		view({attrs: {onsubmit}}) {
			return view(onsubmit)
		}
	}
}

export default patientForm
