// Entry point to lauch Chromium fullscreen

import {ChildProcess, spawn} from 'child_process'
import {startServer} from './server'
import {waitMS} from './lib/wait'

startServer().then(({port}) => {
	waitMS(5000).then(() => {
		let proc: ChildProcess
		try {
			proc = spawn('chromium-browser', ['--kiosk', `http://localhost:${port}/`])
		} catch (e) {
			console.warn("Failed to launch chromium: " + e.message)
			process.exit()
			return
		}
		proc.on('error', err => {
			console.warn("Error while running chromium: " + err.message)
		})
		proc.stdout.on('data', data => {
			console.log(data.toString())
		})
		proc.on('close', code => {
			console.log("Chromium closed. Exiting.")
			process.exit()
		})
	})
})
