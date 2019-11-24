module charstrings

  implicit none

#ifdef output_grid_qdeg
  character(len=256) :: dirsrc = &
    '/scratch1/NCEPDEV/nems/emc.nemspara/RT/FV3-MOM6-CICE5/benchmark-20191112/MOM6_FIX_025deg/'
!    '/scratch1/NCEPDEV/nems/emc.nemspara/RT/FV3-MOM6-CICE5/benchmark-20180913/MOM6_FIX_025deg/'
  character(len= 10) :: res = 'mx025'
#endif
#ifdef output_grid_hdeg
  character(len=256) :: dirsrc = &
    '/scratch2/NCEPDEV/stmp1/Jessica.Meixner/ForCristiana/halfdegbaseline/MOM6_FIX_05deg/'    
  character(len= 10) :: res = 'mx050'
#endif

  character(len=256) :: dirout = './'
  character(len=100) :: maskfile = 'ocean_topog.nc'
  character(len= 12) :: maskname = 'wet'

  character(len=256) :: history
  character(len=  8) :: cdate

end module charstrings
