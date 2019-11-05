const {spawn} = require('child_process')

const cmd = '/opt/imt/robot/crob/tools/plcenter'

let proc
try {
	proc = spawn(cmd)
} catch (e) {
	console.warn("Failed to spawn:", e)
	process.exit()
}
// Log stdout to console
proc.stdout.on('data', data => {
	console.log(data.toString())
})
proc.on('error', err => {
	console.warn('Error while running:', err.message)
	process.exit()
})
proc.on('exit', code => {
	console.log('Ended with code:', code)
	process.exit()
})
