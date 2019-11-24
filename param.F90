module param

  implicit none

  ! output grid size
#ifdef output_grid_qdeg
  integer, parameter :: ni = 1440, nj = 1080
#endif
  ! super-grid source variables
  integer, parameter :: nx  = ni*2, ny  = nj*2

  ! required CICE grid variables
  integer, parameter :: nreqd = 6  ! 5 required, +1 for kmt
  ! for debug_output
  integer, parameter :: nxtra = 7

#ifdef debug_output
  integer, parameter :: ncice = nreqd + nxtra
#else
  integer, parameter :: ncice = nreqd
#endif

end module param
