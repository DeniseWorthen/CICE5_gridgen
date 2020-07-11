module charstrings

  implicit none

#ifdef output_grid_qdeg
  character(len=256) :: dirsrc = &
    '/scratch1/NCEPDEV/nems/emc.nemspara/RT/FV3-MOM6-CICE5/benchmark-20191112/MOM6_FIX_025deg/'
!    '/scratch1/NCEPDEV/nems/emc.nemspara/RT/FV3-MOM6-CICE5/benchmark-20180913/MOM6_FIX_025deg/'
  character(len= 10) :: res = 'mx025'

  character(len=100) :: maskfile = 'ocean_topog.nc'
  character(len= 12) :: maskname = 'wet'
#endif
#ifdef output_grid_hdeg
  character(len=256) :: dirsrc = &
    '/scratch1/NCEPDEV/nems/emc.nemspara/RT/FV3-MOM6-CICE5/master-20191125/MOM6_FIX/050/'
  character(len= 10) :: res = 'mx050'

  character(len=100) :: maskfile = 'ocean_mask.nc'
  character(len= 12) :: maskname = 'mask'
#endif
#ifdef output_grid_1deg
! temporary location
  character(len=256) :: dirsrc = &
    '/scratch2/NCEPDEV/climate/Denise.Worthen/NEMS_INPUT0.1/OM4_360x320_C180/mosaic_unpacked.20150713/'
  character(len= 10) :: res = 'mx100'

  character(len=100) :: maskfile = 'ocean_mask.nc'
  character(len= 12) :: maskname = 'mask'
#endif
  character(len=256) :: dirout = '/scratch2/NCEPDEV/climate/Denise.Worthen/TTout/'
  character(len=256) :: history
  character(len=  8) :: cdate

end module charstrings
