export interface RobotStatus {
	/** Timestamp of last status check */
	time: number
	/** Status */
	calibrationStatus: 'calibrated' | 'uncalibrated' | undefined
	readyStatus: 'ready' | 'busy' | undefined
}
