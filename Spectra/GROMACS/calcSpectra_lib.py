import MDAnalysis as mda
import numpy as np
import math

def convert2NMD(NMA_univ, out_path):
    output_file=out_path

    nof_atoms = NMA_univ.atoms.n_atoms
    atomnames = NMA_univ.atoms.names

    resnames = NMA_univ.atoms.resnames
    resids = NMA_univ.atoms.resindices
    #chainids = NMA_univ.atoms.segids
    chainids = np.repeat('A', nof_atoms)
    bfactors = np.repeat('0', nof_atoms)
    # Actually frame 0 are the eq coordinates
    NMA_univ.trajectory[0]
    coordinates = NMA_univ.atoms.positions

    nof_modes = NMA_univ.trajectory.n_frames - 1

    print('Starts to write nmd file....')
    nmd_file = open(output_file, 'w')
    print('name SUBPART', file=nmd_file)
    print('atomnames', *atomnames, sep=' ', file=nmd_file)
    print('resnames', *resnames, sep=' ', file=nmd_file)
    print('resids', *resids, sep=' ', file=nmd_file)
    print('chainids', *chainids, sep=' ', file=nmd_file)
    print('bfactors', *bfactors, sep=' ', file=nmd_file)
    print('coordinates', end=' ', file=nmd_file)
    for line in coordinates:
        print(*line, end=' ', file=nmd_file)
    print(' ', file=nmd_file)


    print('writing normal mode vectors...')
    for mode in range(nof_modes):
        print(mode)
        mode_num = mode + 1
        print('mode', mode_num, sep=' ', end=' ', file=nmd_file)
        NMA_univ.trajectory[mode_num]
        vec = NMA_univ.atoms.positions
        for line in vec:
            print(*line, end=' ', file=nmd_file)
        print(' ', file=nmd_file)
    nmd_file.close()


def pvec(theta):  # THz polarization vector
    pvector1 = math.cos((theta * math.pi) / 180) * np.array([0, 0, 1])
    pvector2 = math.sin((theta * math.pi) / 180) * np.array([1 / (math.sqrt(2)), -1 / (math.sqrt(2)), 0])
    return pvector1 + pvector2


def Ialignxtl_iso(f, gamma, eigfreq, DDA):
    # gamma - gamma coefficient
    # eigfreq -
    # DDA - array of dipole derivative
    totvalue = 0
    nof_modes = np.size(eigfreq)
    for i in range(7, nof_modes):
        vectormag = math.sqrt(DDA[0, i] * DDA[0, i] + DDA[1, i] * DDA[1, i] + DDA[2, i] * DDA[2, i])
        value = (((gamma * gamma) / eigfreq[i]) * vectormag * vectormag) / (
                        (f - eigfreq[i]) * (f - eigfreq[i]) + gamma * gamma)
        totvalue += value
    return totvalue


def Ialignxtl_aniso(f, gamma, R, theta, eigfreq, DDA):
    # gamma - gamma coefficient
    # eigfreq -
    # DDA - array of dipole derivative
    # theta - polarization angle
    totvalue = 0
    nof_modes = np.size(eigfreq)
    symops = np.shape(R)[0]
    pv = pvec(theta)
    pv2 = float(np.dot(pv, pv))
    for j in range(symops):
        totvaluei = 0
        product = np.dot(R[j, :, :], DDA)
        for i in range(7, nof_modes):
            subproduct = product[:, i]
            product2 = float(np.dot(subproduct, pv))
            value = ((gamma / eigfreq[i]) * product2 * product2) / (
                        ((f - eigfreq[i]) * (f - eigfreq[i]) + gamma * gamma) * pv2)
            totvaluei = value + totvaluei
        totvalue = totvalue + totvaluei
    return totvalue


def calcSpectra(file_prefix, gamma, maxfreq, res, ISOTROPIC=True, ANISOTROPIC=False, R=False):
    if ANISOTROPIC and R is False:
        raise Exception('Please provide R matrix in order to anisotropic spectra calculation!')

    # Read GROMACS eigenvectors and charges
    tpr_path='%s.tpr' % file_prefix
    eigvec_path='%s_vec.trr' % file_prefix
    eigfreq_path='%s_freq.xvg' % file_prefix
    out_path_iso='%s_iso.csv' % file_prefix
    out_path_aniso = '%s_aniso.csv' % file_prefix

    u = mda.Universe(tpr_path, eigvec_path)
    charges = u.atoms.charges
    total_charge = np.sum(charges)
    traj_length = u.trajectory.n_frames
    atom_num = charges.shape[0]
    # And calculate dipole derivatives (CHARMM source code file vibio.F90 line 164)
    nof_modes = traj_length - 1
    V = np.zeros((3, nof_modes))
    for i in range(1, traj_length):
        # Remeber frame 0 is not eigenvector !!!
        u.trajectory[i]
        eigenvec = u.atoms.positions
        eigenvec = eigenvec / 10
        if eigenvec.shape[0] != atom_num:
            print("Warning!!!! nof != eigenvec length")

        dip_der = np.array([0.0, 0.0, 0.0])
        for j in range(0, atom_num):
            ucg = charges[j] - total_charge / atom_num
            dip_der += eigenvec[j, :] * ucg

        V[:, i-1] = dip_der

    # read GROMACS eigenfrequencies
    data = np.loadtxt(eigfreq_path, comments=["@", "#"])
    freqin = data[:, 1]

    ###################### ISOTROPIC ###########################
    if ISOTROPIC:
        print('Isotropic calculation...')
        outfile = open(out_path_iso, 'w')
        for f in np.arange(0, maxfreq, res):
            outstring = ''
            ialign = Ialignxtl_iso(f, gamma, freqin, V)
            outstring = ', ' + str(ialign)
            outfile.write(str(f) + outstring + '\n')
            if f % 10 == 0:
                print('f = ', f)

        print("I am done!")
        #convert2NMD(u)

    ###################### ANISOTROPIC ###########################
    if ANISOTROPIC:
        ##############################################################################
        # Apply transformation to align orientation of protein within frame to that in
        # crystal. Not necessary if already aligned.
        # M = np.array([[0.0683610588312149, -0.6129125952720642, -0.787187933921814],
        #               [0.86541748046875,  0.4289986789226532, -0.25886809825897217],
        #               [0.49636611342430115, -0.6635497212409973, 0.5597521066665649]])  # For 115
        # M = np.array([[-0.013308688998222351, 0.9973279237747192, 0.07183252274990082],
        #               [0.41388630867004395, 0.07089032977819443, -0.9075641632080078],
        #               [-0.9102312922477722, 0.017652008682489395, -0.41372382640838623]])  # for 25
        # V = np.dot(M, V)
        ##############################################################################
        freq_list = np.arange(0, maxfreq, res)
        freq_ren = np.size(freq_list)
        outabs = np.zeros((freq_ren, 14))
        for f in range(freq_ren):
        #    outstring = ''
            for k in range(13):
                fout = freq_list[f]
                outabs[f, 0] = fout
                outabs[f, k + 1] = Ialignxtl_aniso(fout, gamma, R, k * 15, freqin, V)
            if f % 10 == 0:
                print('f = ', f)
        np.savetxt(out_path_aniso, outabs, delimiter=',')  # , newline='\n')
