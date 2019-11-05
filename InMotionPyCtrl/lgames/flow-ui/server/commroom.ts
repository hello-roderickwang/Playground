export interface Room {
	send(id: string, data?: any): boolean
}

const state = {
	room: undefined as any as Room
}

function _createRoom (io: SocketIO.Server) {
	let socket: SocketIO.Socket | undefined

	io.on('connection', _sock => {
		socket = _sock
		const socketId = socket.client.id
		console.log('client ' + socketId + ' connected')

		socket.on('disconnect', () => {
			console.log("client " + socketId + " disconnected")
		})

		socket.on('test', event => {
			console.log("Recieved test message")
		})
	})

	function send (id: string, data?: any) {
		if (!socket) {
			console.warn("Can't send: no socket")
			return false
		}
		//console.log('sending:', id)
		socket.emit(id, data)
		return true
	}

	return {send}
}

export function createRoom (io: SocketIO.Server) {
	if (state.room) {
		throw new Error("Room already created")
	}
	state.room = _createRoom(io)
	return state.room
}

export default state
