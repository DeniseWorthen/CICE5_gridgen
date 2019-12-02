module grdvars

  use param

  implicit none

  ! super-grid source variables
  real(kind=8), dimension(0:nx,0:ny)   :: x, y, angq
  real(kind=8), dimension(  nx,0:ny)   :: dx
  real(kind=8), dimension(0:nx,  ny)   :: dy

  !super-grid replicate row
  real(kind=8), dimension(0:nx,0:ny+1) :: xsgp1, ysgp1

  ! pole locations
  integer(kind=4) :: ipole(2)

  real(kind=8), dimension(ni,nj) :: ulon, ulat
  real(kind=8), dimension(ni,nj) ::  htn, hte
  real(kind=8), dimension(ni,nj) :: angle

  real(kind=8), dimension(ni,nj) ::  latT, lonT  ! lat and lon of T on C-grid
  real(kind=8), dimension(ni,nj) :: latCv, lonCv ! lat and lon of V on C-grid
  real(kind=8), dimension(ni,nj) :: latCu, lonCu ! lat and lon of U on C-grid
  real(kind=8), dimension(ni,nj) :: anglet

  ! ocean mask from fixed file, stored as either r4 or r8
     real(kind=4), dimension(ni,nj) :: wet4
     real(kind=8), dimension(ni,nj) :: wet8

end module grdvars
