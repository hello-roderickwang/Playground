// Electron app entry point

import {BrowserWindow, app} from 'electron'
import {ChildProcess, spawn} from 'child_process'
import * as path from 'path'
import * as http from 'http'

const isFullscreen = process.argv[2] === '-fs'

let serverProcess: ChildProcess | undefined
let serverPort: number | undefined

// Keep a global reference of the window object, if you don't, the window will
// be closed automatically when the JavaScript object is garbage collected.
// mainWindow values:
//	 undefined     - Not yet created
//   null          - Created, then closed, but app still running
//   BrowserWindow - Created, open, running
let mainWindow: Electron.BrowserWindow | null | undefined

function createWindow (port: number) {
	// Create the browser window.
	mainWindow = new BrowserWindow(
		isFullscreen ? {
			fullscreen: true
		} : {
			width: 1140, height: 880
		}
	)

	mainWindow.setMenu(null)

	mainWindow.loadURL('http://localhost:' + port + '/')

	// Open the DevTools.
	// mainWindow.webContents.openDevTools()

	// Emitted when the window is closed.
	mainWindow.on('closed', () => {
		// Dereference the window object, usually you would store windows
		// in an array if your app supports multi windows, this is the time
		// when you should delete the corresponding element.
		mainWindow = null
	})
}

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.on('ready', () => {
	startServer().then(({port}) => {
		serverPort = port
		createWindow(serverPort)
	}).catch(e => {
		console.log("Error starting server:", e.message)
	})
})

// Quit when all windows are closed.
app.on('window-all-closed', () => {
	// On OS X it is common for applications and their menu bar
	// to stay active until the user quits explicitly with Cmd + Q
	if (process.platform !== 'darwin') {
		app.quit()
	}
})

app.on('activate', () => {
	// On OS X it's common to re-create a window in the app when the
	// dock icon is clicked and there are no other windows open.
	if (mainWindow === null) {
		if (serverPort != null) {
			createWindow(serverPort)
		} else {
			console.warn("Can't create window on activate: serverPort undefined")
		}
	}
})

if (isFullscreen) {
	// When the window blurs, we assume that whatever window appears
	// on top should remain on top, so our app will not respond to
	// mouse events until it is focused again. This is to prevent
	// our fullscreen window from obscuring important system UI.
	app.on('browser-window-blur', () => {
		if (mainWindow != null) {
			mainWindow.setIgnoreMouseEvents(true)
		}
	})

	// When app regains focus, we should accept mouse events again.
	app.on('browser-window-focus', () => {
		if (mainWindow != null) {
			mainWindow.setIgnoreMouseEvents(false)
		}
	})
}

app.on('quit', () => {
	console.log("Electron quitting")
	if (serverProcess) {
		const req = http.request(
			{
				host: 'localhost',
				port: serverPort,
				path: '/api/server/stop',
				method: 'POST'
			},
			res => {
				if (serverProcess) {
					console.log("Killing server process")
					serverProcess.kill()
					serverProcess = undefined
				}
			}
		)
		req.end()
	}
	serverPort = undefined
	mainWindow = undefined
})

/**
 * Start express server in a separate process
 */
function startServer() {
	// Expected in stdout from server process
	const rxServer = /server running on port \[([0-9]+)]/

	return new Promise<{port: number}>((resolve, reject) => {
        const serverRoot = path.resolve(__dirname, '..', 'server')
		const serverStartScript = path.join(serverRoot, 'index.ts')
		// Start the server using ts-node so that it can execute Typescript directly
		const tsnode = path.resolve(__dirname, '..', 'node_modules', 'ts-node', 'dist', 'bin.js')
		console.log("Starting server:", serverStartScript)
        try {
            serverProcess = spawn('node', [
                tsnode, '--project', serverRoot, serverStartScript
            ])
        } catch (err) {
			reject(err)
			return
		}
		let resolved = false
		let output = ''
		serverProcess.stdout.on('data', data => {
			const str = data.toString()
			console.log(str.trim())
			if (!resolved) {
				output += str
				// Resolve when we see the output for the express server running
				const result = rxServer.exec(output)
				if (result != null) {
					let port = Number.parseInt(result[1])
					if (Number.isNaN(port)) {
						console.warn("Could not parse port from server output. Falling back on default.")
						port = 3000
					}
					resolved = true
					resolve({port})
				}
			}
		})
		serverProcess.stderr.on('data', data => {
			console.warn(data.toString().trim())
		})
		serverProcess.on('error', err => {
			console.warn('error:', err)
			if (!resolved) {
				resolved = true
				reject(err)
			}
		})
		serverProcess.on('exit', code => {
			console.log("Server process ended")
			serverProcess = undefined
		})
	})
}
