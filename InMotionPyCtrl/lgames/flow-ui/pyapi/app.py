import os
import re
import subprocess
from flask import Flask, Response, jsonify

CROB_HOME = os.environ['CROB_HOME'] if 'CROB_HOME' in os.environ else './mock-sys/opt/imt/crob'
LGAMES_HOME = os.environ['LGAMES_HOME'] if 'LGAMES_HOME' in os.environ else './mock-sys/opt/imt/lgames'

HEADERS = {'Access-Control-Allow-Origin': '*'}
GAMES = ['cs', 'pick', 'pong', 'race', 'squeegee']
RXID = re.compile('^[0-9a-z]+$')

app = Flask(__name__)

# Simple test route
@app.route('/api')
def index():
    return jsonify({'status': u'ok'})

# Run calibration
@app.route('/api/calibrate', methods=['GET'])
def calibrate():
    cmd = '{0}/tools/plcenter'.format(CROB_HOME)
    try:
        subprocess.call([cmd])
    except EnvironmentError as e:
        print 'Error running "{0}": {1} ({2})'.format(cmd, e.strerror, e.errno)
        return jsonify({'error': u'Error running calibration: {0}'.format(e.strerror)}), 500, HEADERS
    return jsonify({'status': u'ok'}), 200, HEADERS

# Launch game
@app.route('/api/game/<gamename>/<clinid>/<patid>', methods=['GET'])
def rungame(gamename, clinid, patid):
    if gamename not in GAMES:
        return jsonify({'error': u'Unknown game'}), 403, HEADERS
    if not RXID.match(clinid):
        return jsonify({'error': u'Invalid clinician ID'}), 403, HEADERS
    if not RXID.match(patid):
        return jsonify({'error': u'Invalid patient ID'}), 403, HEADERS
    cmd = '{0}/{1}/run{1}'.format(LGAMES_HOME, gamename)
    #os.environ['CLINID'] = clinid
    #os.environ['PATID'] = patid
    env = os.environ.copy()
    env['CLINID'] = clinid
    env['PATID'] = patid
    try:
        #subprocess.call([cmd], env=env)
        subprocess.Popen([cmd], shell=True, env=env)
    except EnvironmentError as e:
        print 'Error running "{0}": {1} ({2})'.format(cmd, e.strerror, e.errno)
        return jsonify({'error': u'Error running game \'{0}\': {1}'.format(gamename, e.strerror)}), 500, HEADERS
    return jsonify({'status': u'ok'}), 200, HEADERS

# Start app
if __name__ == '__main__':
    app.run(debug=True)
