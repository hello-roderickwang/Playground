export default class ImtError extends Error {
	httpStatus: number
	constructor (msg: string, status: number) {
		super(msg)
		this.httpStatus = status
	}
}
