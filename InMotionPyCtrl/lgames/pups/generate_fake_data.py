from utils import north_cw_rose, angles, Hz
from pylab import *
from os.path import join as pjoin
from shutil import copy


def ellipse(ra, rb, ang, x0, y0, Nb=50):
    """
    ra - major axis length
    rb - minor axis length
    ang - angle
    x0,y0 - position of centre of ellipse
    Nb - No. of points that make an ellipse
    """

    the = linspace(0, 2*pi, Nb)
    x = ra * cos(the) * cos(ang) - sin(ang) * rb * sin(the) + x0
    y = ra * cos(the) * sin(ang) + cos(ang) * rb * sin(the) + y0
    return x, y


@vectorize
def i_min_jerk(currtime, tottime, distance):
    return (distance * (6.0 * currtime**5 / tottime**5
                        - 15.0 * currtime**4 / tottime**4
                        + 10.0 * currtime**3 / tottime**3))

writedir = '/home/dmd/therapist/test/eval/20050128_Fri/'
pathlen = 0.14
columns = 9
seconds = 2
samples = seconds * Hz
min_jerk_points = i_min_jerk(arange(samples), samples, pathlen)
header = """
s logcolumns {}
s logversion 2.0
# begin user data
s pathlength {}
# end user data
#####""".format(columns, pathlen)


### point to point
def star(toback, theta):
    x = min_jerk_points * cos(theta)
    y = min_jerk_points * sin(theta)
    if toback == 'b':
        x = x[::-1]
        y = y[::-1]

    out = zeros((len(x), columns))
    out[:, 0] = arange(samples) + 1
    out[:, 1] = x
    out[:, 2] = y
    out[1:, 3] = diff(x) * Hz
    out[1:, 4] = diff(y) * Hz
    return out

### point to point
for movement in range(8):
    for toback in ('t', 'b'):
        compass = north_cw_rose[movement % 8]
        out = star(toback, angles[compass])
        ptpfilename = pjoin(writedir, 'point_to_point_000000_{}{}{}.dat'.format(compass, toback, movement + 1))
        rdfilename = pjoin(writedir, 'round_dyn_000000_{}{}{}.dat'.format(compass, toback, movement + 1))
        savetxt(ptpfilename, out, fmt='%.6f', header=header, comments='')
        copy(ptpfilename, rdfilename)


### circle
seconds = 2
out = zeros((samples, columns))
x, y = ellipse(ra=.1, rb=.2, ang=pi / 4, x0=0, y0=0, Nb=samples)
out[:, 0] = arange(samples) + 1
out[:, 1] = x
out[:, 2] = y
filename = pjoin(writedir, 'circle_9_ccw_000000_1.dat')
savetxt(filename, out, fmt='%.6f', header=header, comments='')

### Playback Static
allout = zeros((1, columns))
for movement in range(8):
    for toback in ('t', 'b'):
        compass = north_cw_rose[movement % 8]
        out = star(toback, angles[compass])
        out[:, 1:3] *= 0.5
        allout = vstack((allout, out))
filename = pjoin(writedir, 'playback_static_000000_multi.dat')
savetxt(filename, allout[1:, :], fmt='%.6f', header=header, comments='')
