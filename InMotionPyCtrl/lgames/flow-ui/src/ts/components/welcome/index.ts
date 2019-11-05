import * as m from 'mithril'
import {validClinID} from '../../../../server/lib/validate'
import {CLINID, PATIENT} from '../../state'
import modal, {modalIsOpen, openModal} from '../modal'

export default {
	oninit() {
		CLINID('')
		PATIENT(undefined)
	},
	oncreate({dom}) {
		window.setTimeout(() => {
			const el = dom.querySelector('#input-clinid') as HTMLInputElement | undefined
			if (el) el.focus()
		}, 100)
	},
	view() {
		return m('.welcome',
			m('h1.logo',
				m('img', {
					src: 'img/bionik-logo-white.svg',
					alt: 'Bionik Laboratories'
				})
			),
			m('form',
				{
					onsubmit (e: Event) {
						e.preventDefault()
						if (validClinID(CLINID())) {
							m.route.set('/home')
						} else {
							openModal({
								title: "Invalid Clinician ID",
								buttons: [{id: 'ok', text: "Ok"}]
							})
						}
					}
				},
				m('.clinician-id',
					m('label', "Clinician ID:"),
					m('input', {
						id: 'input-clinid',
						type: 'text',
						value: CLINID(),
						oninput: m.withAttr('value', CLINID)
					})
				),
				m('div',
					m('button.btn-blue',
						{
							type: 'submit',
							disabled: !CLINID()
						},
						"Continue"
					)
				)
			),
			m('button.btn-shutdown.btn-blue',
				{
					onclick() {
						openModal({
							title: "Logout System",
							content: "Are you sure you want to log out of the system?",
							buttons: [
								{id: 'yes', text: "Yes"},
								{id: 'no', text: "No"}
							],
							onclick(id) {
								if (id === 'yes') {
									logoutSystem()
								}
							}
						})
					}
				},
				m('img', {src: 'img/icon-power.png', alt: ''}),
				"Logout System"
			),
			m('.small-note', "(press Alt-F4 to exit GUI)"),
			m('.version', "Software ver. 2.0.0"),
			m(fontPreloader),
			modalIsOpen() && m(modal)
		)
	}
} as m.Component<{},{}>

// A component to preload all fonts so they don't shift
// layouts while loading the first time on other pages.

const fonts = ['rubiklight', 'rubikregular', 'latobold']

const fontPreloader: m.Component<{},{}> = {
	view() {
		return m('.font-preloader',
			fonts.map(f => m('span', {style: 'font-family: ' + f}, 'a'))
		)
	}
}

/** Logs out of the system */
function logoutSystem() {
	m.request({url: '/api/system/logout', method: 'post'})
}
