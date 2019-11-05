import * as m from 'mithril'

export default {
	view() {
		return m('.welcome.animation',
			m('.logo',
				m('img', {src: 'img/inmotion-robot-logo.png', alt: 'Inmotion Robots Rehabilitation'}),
			),
			m('.hr'),
			m('h1', "Inmotion Interactive Robotic Therapy")
		)
	}
}