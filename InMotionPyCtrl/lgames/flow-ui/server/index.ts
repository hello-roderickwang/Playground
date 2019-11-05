// Entry point to start standalone server (no Electron)

import {startServer, stopServer} from './server'

startServer()

process.on('exit', code => {
	console.log("Stopping express server...")
	stopServer()
})
