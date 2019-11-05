import {config as dotenvConfig} from 'dotenv'
dotenvConfig()

import * as path from 'path'
import * as express from 'express'
import {createServer, Server} from 'http'
import * as bodyParser from 'body-parser'
import * as createIO from 'socket.io'
//import createWildcard = require('socketio-wildcard')
import createRouter from './router'
import {createRoom} from './commroom'
const port = Number(process.env.NODE_EXPRESS_SERVER_PORT || 3000)
let server: Server | undefined

export function startServer() {
	if (server) {
		console.warn("Server already started.")
		return Promise.resolve({port})
	}

	const app = express()
	server = createServer(app)
	app.use(bodyParser.json())
	app.use(bodyParser.urlencoded({extended: true}))

	// Serve static client app assets
	app.use('/', express.static(path.resolve(__dirname, '..', 'public')))

	// Setup API routes
	const router = createRouter(stopServer)
	app.use('/api', router)

	const promise = new Promise<{port: number}>((resolve, reject) => {
		server!.listen(port, () => {
			// Must output this string so that the parent process can
			// determine what port our server is running on.
			console.log('Express server running on port [' + port + ']')
			resolve({port})
		})
	})

	// Setup socket server
	const io = createIO(server)
	// This add-on allows us to catch wildcard (*) events
	//io.use(createWildcard())
	// Create the room that will manage client socket connections & communication
	createRoom(io)

	return promise
}

export function stopServer() {
	if (!server) {
		console.warn("Cannot stop server - not started.")
		return
	}
	console.log("Stopping server")
	server.close()
	server = undefined
}
