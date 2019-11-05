import * as m from 'mithril'
import {RobotMode} from './protocols'
import app from './components/app'
import welcome from './components/welcome'
import animation from './components/animation'
import home from './components/home'
import games from './components/games'
import robot from './components/robot'
import therapyV1 from './components/therapy-v1'
import therapyHistory from './components/therapy-history'
import patientFolders from './components/patient/folders'
import patientDashboard from './components/patient/dashboard'
import patientSearch from './components/patient/search'
import patientAdd from './components/patient/add'
import patientEdit from './components/patient/edit'
import patientNotes from './components/patient/notes'
import reportsAnalytics from './components/reports-analytics'
import admin from './components/admin'

export default {
	'/': welcome,
	'/animation': animation,
	'/home': {render: () => m(app, m(home))},
	'/games': {render: () => m(app, m(games))},
	'/robot/:mode': {
		render({attrs}: m.Vnode<{mode: RobotMode},{}>) {
			return m(app, m(robot, {mode: attrs.mode}))
		}
	},
	'/therapy-v1': {render: () => m(app, m(therapyV1))},
	'/therapy-history': {render: () => m(app, m(therapyHistory))},
	'/patient/folders': {render: () => m(app, m(patientFolders))},
	'/patient/dashboard': {render: () => m(app, m(patientDashboard))},
	'/patient/search': {render: () => m(app, m(patientSearch))},
	'/patient/add': {render: () => m(app, m(patientAdd))},
	'/patient/edit': {render: () => m(app, m(patientEdit))},
	'/patient/notes': {render: () => m(app, m(patientNotes))},
	'/reports-analytics': {render: () => m(app, m(reportsAnalytics))},
	'/admin': {render: () => m(app, m(admin))},
} as m.RouteDefs
