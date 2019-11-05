import * as express from 'express'
import {launchGame} from './controllers/game-launcher'
import {launchClockGame} from './controllers/clock-launcher'
import {
	listPatients, listPatientIds, getPatient, addPatient, updatePatient, deletePatient
} from './controllers/patients'
import {
	listRobots, getCurrentRobot, setCurrentRobot, listProtocols,
	listTherapies, listEvaluations, calibrateRobot, getRobotStatus,
	longTest
} from './controllers/robot'
import {
	generate as generateReport, serve as serveReport, openPdfWindow,
	getTherapyHistory, startTherapySession, addActivity
} from './controllers/reports'
import {
	devices as listMediaDevices, copyPatientData, copyPatientReport
} from './controllers/media'
import {logout} from './controllers/system'

export default function createRouter (stopServer?: () => void) {
	const router = express.Router()

	// API test
	router.get('/test', (req, res) => {
		res.send({status: 'ok'})
	})

	// get robots list
	router.get('/robots', listRobots)

	// get/set current_robot
	router.get('/current-robot', getCurrentRobot)
	router.post('/current-robot', setCurrentRobot)

	// get status
	router.get('/status', getRobotStatus)

	// calibrate robot
	router.post('/calibrate', calibrateRobot)

	// run robot long test
	router.post('/long-test', longTest)

	// clock game launcher
	router.post('/game/clock', launchClockGame)

	// general launcher
	router.post('/game/:game', launchGame)

	// get protocols list (for current_robot)
	router.get('/protocols', listProtocols)

	// Get list of therapies, evaluations
	router.get('/therapies/:protocol', listTherapies)
	router.get('/evaluations/:protocol', listEvaluations)

	// Patients
	router.get('/patients', listPatients)
	router.get('/patientids', listPatientIds)
	router.get('/patient/:id', getPatient)
	router.post('/patient', addPatient)
	router.patch('/patient', updatePatient)
	router.delete('/patient/:id', deletePatient)

	// Reports
	router.get('/report/:patid', serveReport)
	router.post('/report/generate', generateReport)
	router.get('/report/therapy-history/:patid', getTherapyHistory)
	router.post('/report/start-therapy-session/:patid', startTherapySession)
	router.post('/report/add-activity/:patid', addActivity)

	// Windows
	//router.post('/open-window', openWindow)
	router.post('/open-pdf-window', openPdfWindow)

	// External media
	router.get('/media/devices', listMediaDevices)
	router.post('/media/copy-patient', copyPatientData)
	router.post('/media/copy-report', copyPatientReport)

	// System
	router.post('/system/logout', logout)

	// Shutdown the express server
	router.post('/server/stop', (req, res) => {
		if (stopServer) {
			stopServer()
		}
		res.send({message: 'ok'})
		setTimeout(() => {
			process.exit()
		}, 100)
	})

	return router
}
