//import {BrowserWindow} from 'electron'
//const {BrowserWindow} = require('electron').remote
//const PDFWindow = require('electron-pdf-window')
import {ChildProcess, spawn} from 'child_process'

const port = process.env.NODE_EXPRESS_SERVER_PORT || 3000

/* export function openNewWindow (url: string, opts: any) {
	const win = new BrowserWindow(opts)
	win.setMenu(null as any)
	if (url[0] !== '/') {
		url = '/' + url
	}
	win.loadURL('http://localhost:' + port + url)
	return win
} */

/* export function openNewPdfWindow (url: string, opts: any) {
	const win = new BrowserWindow(opts)
	PDFWindow.addSupport(win)
	win.setMenu(null as any)
	if (url[0] !== '/') {
		url = '/' + url
	}
	win.loadURL('http://localhost:' + port + url)
	return win
} */

export function spawnFirefox (url: string) {
	let proc: ChildProcess
	try {
		if (url[0] !== '/') {
			url = '/' + url
		}
		proc = spawn('firefox', ['http://localhost:' + port + url])
	} catch (e) {
		console.warn("Failed to run firefox:", e)
		return
	}
	proc.stdout.on('data', data => {
		console.log(data.toString())
	})
	proc.on('error', err => {
		console.warn('Error while running firefox:', err.message)
	})
	proc.on('exit', code => {
		console.log('firefox ended with code:', code)
	})
}
