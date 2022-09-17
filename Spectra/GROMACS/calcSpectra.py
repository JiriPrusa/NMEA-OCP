import numpy as np
from calcSpectra_lib import calcSpectra

folder = '/home/jirka/WORK/NMEA/MD/EIGSOL/25'

spec_resolution = 1 # resolution in output spectra (cm-1)
maxfreq = 100  # max freq to calc spectra (cm-1)
gamma = 4
ISOTROPIC = False
ANISOTROPIC = True

# Crystal Group Rotation Matrix (For anisotropic spectra only)
R0 = np.array([[1, 0, 0], [0, 1, 0], [0, 0, 1]])
R1 = np.array([[0, -1, 0], [1, -1, 0], [0, 0, 1]])
R2 = np.array([[-1, 1, 0], [-1, 0, 0], [0, 0, 1]])
R = np.array([R0, R1, R2], float)


for rep in np.arange(10, 11, 1):
    for fil in np.arange(10, 100, 10):
        file_prefix = '%s/%i_frame_%i' % (folder, rep, fil)
        calcSpectra(file_prefix, gamma, maxfreq, spec_resolution, ISOTROPIC, ANISOTROPIC, R)










