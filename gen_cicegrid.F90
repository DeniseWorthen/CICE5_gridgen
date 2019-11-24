program gen_cicegrid

! Denise.Worthen@noaa.gov
!
!---------------------------------------------------------------------
! this code generate CICE gird fixed file based on MOM6 ocean_hgrid.nc
! information on MOM6 supergrid can be found at
! https://gist.github.com/adcroft/c1e207024fe1189b43dddc5f1fe7dd6c
!
! also: https://mom6.readthedocs.io/en/latest/api/generated/modules/mom_grid.html
!
! also:
! MOM_grid_initialize.F90 :
!  MOM6 variable geoLonBu <==> CICE variable ulon
!  MOM6 variable geoLatBu <==> CICE variable ulat
!  MOM6 variable     dxCv <==> CICE variable htn
!  MOM6 variable     dyCu <==> CICE variable hte
!
! MOM6 code snippets follow:
!
! from MOM_grid_initialize.F90  (tmpZ = x)
!  do J=G%JsdB,G%JedB ; do I=G%IsdB,G%IedB ; i2 = 2*I ; j2 = 2*J
!    G%geoLonBu(I,J) = tmpZ(i2,j2)
! so....
!          ulon(I,J) = x(i2,j2)
 
! from MOM_grid_initialize.F90  (tmpZ = y)
!  do J=G%JsdB,G%JedB ; do I=G%IsdB,G%IedB ; i2 = 2*I ; j2 = 2*J
!    G%geoLatBu(I,J) = tmpZ(i2,j2)
! so....
!          ulat(I,J) = y(i2,j2)

! from MOM_grid_initialize.F90  (tmpV = dx)
!  do J=G%JsdB,G%JedB ; do i=G%isd,G%ied ; i2 = 2*i ; j2 = 2*j
!    dxCv(i,J) = tmpV(i2-1,j2) + tmpV(i2,j2)
! so....
!     htn(i,J) =   dx(i2-1,j2) +   dx(i2,j2)

! from MOM_grid_initialize.F90  (tmpU = dy)
!  do J=G%JsdB,G%JedB ; do i=G%isd,G%ied ; i2 = 2*i ; j2 = 2*j
!    dyCu(I,j) = tmpU(i2,j2-1) + tmpU(i2,j2)
! so....
!     hte(I,j) =   dy(i2,j2-1) +   dy(i2,j2)
!
! rotation angle on supergrid vertices can be found 
! using the formula in MOM_shared_initialization.F90, accounting 
! for indexing difference between reduced grid and super grid
!
!         SuperGrid                 Reduced grid
! 
!  i-1,j+1         i+1,j+1
!     X-------X-------X             I-1,J      I,J
!     |       |       |                X-------X      
!     |       |       |                |       |
!     |       | i,j   |                |   T   |
!     X-------X-------X                |       |
!     |       |       |                X-------X
!     |       |       |             I-1,J-1   I,J-1
!     |       |       |
!     X-------X-------X
!  i-1,j-1         i+1,j-1
!      
! so that in angle formulae 
!         I==>i+1,I-1==>i-1
!         J==>j+1,J-1==>j-1 
!
! CICE expects angle to be XY -> LatLon so change the sign from MOM6 value
! This has been determined from the HYCOM code: ALL/cice/src/grid2cice.f 
!
!            anglet(i,j) =    -pang(i+i0,  j+j0)   !radians
!c           pang is from lon-lat to x-y, but anglet is the reverse

! where anglet is the angle variable being written to the CICE grid file 
! and pang is HYCOM's own rotation angle. 
!
! Tripole Seam flip: ipL,ipR left,right poles on seam
!
! ipL-1     ipL    ipL+1       ipR-1     ipR    ipR+1
!    x-------x-------x     |||    x-------x-------x 
!
! Fold over; ipL must align with ipR
!  
!  ipR+1     ipR    ipR-1
!     x-------x-------x 
!  ipL-1     ipL    ipL+1
!     x-------x-------x 
!
!
!---------------------------------------------------------------------

  use netcdf
  use param
  use grdvars
  use physcon
  use charstrings
  use icegriddefs

  implicit none
 
  ! local variables
 
  character(len=256) :: fname_out, fname_in
  character(len=300) :: cmdstr

  ! from geolonB fix in MOM6
  real(kind=8) :: len_lon ! The periodic range of longitudes, usually 360 degrees.
  real(kind=8) :: pi_720deg ! One quarter the conversion factor from degrees to radians.
  real(kind=8) :: lonB(2,2)  ! The longitude of a point, shifted to have about the same value.
  real(kind=8) :: lon_scale 

  integer :: rc,ncid,xtype
  integer :: id, vardim(2)
  integer :: ni_dim,nj_dim
  integer :: i,j,n,m,ii,jj,i2,j2
  integer :: ipole(2),i1
  integer :: system

  real(kind=8) :: modulo_around_point
!---------------------------------------------------------------------
! get the mask 
!---------------------------------------------------------------------

  fname_in = trim(dirsrc)//trim(maskfile)

  rc = nf90_open(fname_in, nf90_nowrite, ncid)
  print *, 'reading ocean mask from ',trim(fname_in)
  print *, 'nf90_open = ',trim(nf90_strerror(rc))

  rc = nf90_inq_varid(ncid,  trim(maskname), id)
  rc = nf90_inquire_variable(ncid, id, xtype=xtype)
  if(xtype .eq. 5)rc = nf90_get_var(ncid,      id,  wet4)
  if(xtype .eq. 6)rc = nf90_get_var(ncid,      id,  wet8)
  rc = nf90_close(ncid)
  
  if(xtype.eq. 6)wet4 = real(wet8,4)

!---------------------------------------------------------------------
! read supergrid file
!---------------------------------------------------------------------

  fname_in = trim(dirsrc)//'ocean_hgrid.nc'

  rc = nf90_open(fname_in, nf90_nowrite, ncid)
  print *, 'reading supergrid from ',trim(fname_in)
  print *, 'nf90_open = ',trim(nf90_strerror(rc))
  
  rc = nf90_inq_varid(ncid, 'x', id)  !lon
  rc = nf90_get_var(ncid,    id,  x)
 
  rc = nf90_inq_varid(ncid, 'y', id)  !lat
  rc = nf90_get_var(ncid,    id,  y)
 
  rc = nf90_inq_varid(ncid, 'dx', id)  
  rc = nf90_get_var(ncid,     id, dx)
  
  rc = nf90_inq_varid(ncid, 'dy', id)  
  rc = nf90_get_var(ncid,     id, dy)
  rc = nf90_close(ncid)

!---------------------------------------------------------------------
! to find angleq on seam, replicate supergrid values across seam
!---------------------------------------------------------------------

  !pole on supergrid
  ipole = -1
      j = ny
  do i = 1,nx/2
   if(y(i,j) .eq. 90.0)ipole(1) = i
  enddo
  do i = nx/2+1,nx
   if(y(i,j) .eq. 90.0)ipole(2) = i
  enddo
  print *,'poles found at ',ipole

  xsgp1(:,0:ny) = x(:,0:ny)
  ysgp1(:,0:ny) = y(:,0:ny)
  
  !check
  do i = ipole(1)-5,ipole(1)+5
   i2 = ipole(2)+(ipole(1)-i)+1
   print *,i,i2
  enddo
   print *
  do i = ipole(2)-5,ipole(2)+5
   i2 = ipole(2)+(ipole(1)-i)+1
   print *,i,i2
  enddo

  !replicate supergrid across pole
  do i = 1,nx
    i2 = ipole(2)+(ipole(1)-i)
   xsgp1(i,ny+1) = xsgp1(i2,ny)
   ysgp1(i,ny+1) = ysgp1(i2,ny)
  enddo
 
  !check  
   j = ny+1
  i1 = ipole(1); i2 = ipole(2)-(ipole(1)-i1)
  print *,'replicate X across seam on SG'
  print *,xsgp1(i1-2,j),xsgp1(i2+2,j)
  print *,xsgp1(i1-1,j),xsgp1(i2+1,j)
  print *,xsgp1(i1,  j),xsgp1(i2,  j)
  print *,xsgp1(i1+1,j),xsgp1(i2-1,j)
  print *,xsgp1(i1+2,j),xsgp1(i2-2,j)

  print *,'replicate Y across seam on SG'
  print *,ysgp1(i1-2,j),ysgp1(i2+2,j)
  print *,ysgp1(i1-1,j),ysgp1(i2+1,j)
  print *,ysgp1(i1,  j),ysgp1(i2,  j)
  print *,ysgp1(i1+1,j),ysgp1(i2-1,j)
  print *,ysgp1(i1+2,j),ysgp1(i2-2,j)

!---------------------------------------------------------------------
! rotation angle on supergrid vertices
! lonB: x(i-1,j-1) has same relationship to x(i,j) on SG as 
!       geolonT(i,j) has to geolonBu(i,j) on the reduced grid
!---------------------------------------------------------------------

   pi_720deg = atan(1.0) / 180.0
     len_lon = 360.0
  do j=1,ny ; do i=1,nx-1
    do n=1,2 ; do m=1,2
      lonB(m,n) = modulo_around_point(xsgp1(I+m-2,J+n-2), xsgp1(i-1,j-1), len_lon)
    enddo ; enddo

    lon_scale    = cos(pi_720deg*(ysgp1(i-1,j-1) + ysgp1(i+1,j-1) + &
                                  ysgp1(i-1,j+1) + ysgp1(i+1,j+1)) )
    angq(i,j)    = atan2(lon_scale*((lonB(1,2) - lonB(2,1)) + (lonB(2,2) - lonB(1,1))), &
                          ysgp1(i-1,j+1) + ysgp1(i+1,j+1) - &
                          ysgp1(i-1,j-1) - ysgp1(i+1,j-1) )
  enddo ; enddo

  !check  
   j = ny
  i1 = ipole(1); i2 = ipole(2)-(ipole(1)-i1)
  print *,'angq along seam on SG'
  print *,angq(i1-2,j),angq(i2+2,j)
  print *,angq(i1-1,j),angq(i2+1,j)
  print *,angq(i1,  j),angq(i2,  j)
  print *,angq(i1+1,j),angq(i2-1,j)
  print *,angq(i1+2,j),angq(i2-2,j)

!---------------------------------------------------------------------
! fill cice grid variables
!---------------------------------------------------------------------

  do j = 1,nj
   do i = 1,ni
     i2 = 2*i ; j2 = 2*j
    !deg->rad
     ulon(i,j) =     x(i2,j2)*deg2rad
     ulat(i,j) =     y(i2,j2)*deg2rad
    !in rad already
    angle(i,j) = -angq(i2,j2)
    !m->cm
      htn(i,j) = (dx(i2-1,j2) + dx(i2,j2))*100.0
      hte(i,j) = (dy(i2,j2-1) + dy(i2,j2))*100.0
    !deg
      lonT(i,j) =     x(i2-1,j2-1)
     lonCu(i,j) =     x(i2,  j2-1)
     lonCv(i,j) =     x(i2-1,j2  )
    !deg
      latT(i,j) =     y(i2-1,j2-1)
     latCu(i,j) =     y(i2,  j2-1)
     latCv(i,j) =     y(i2-1,j2  )
    !in rad already
    anglet(i,j) = -angq(i2-1,j2-1)
   enddo
  enddo

!---------------------------------------------------------------------
! For the 1/4deg grid, hte at j=720 and j = 1440 is identically=0.0 for 
! j > 840 (64.0N). These are land points, but since CICE uses hte to 
! generate remaining variables, setting them to zero will cause problems
! For 1deg grid, hte at ni/2 and ni are very small O~10-12, so test for 
! hte < 1.0
!---------------------------------------------------------------------

  print *,'min vals of hte at folds ',minval(hte(ni/2,:)),minval(hte(ni,:))
  do j = 1,nj
     ii = ni/2
   if(hte(ii,j) .le. 1.0)hte(ii,j) = 0.5*(hte(ii-1,j) + hte(ii+1,j))
     ii = ni
   if(hte(ii,j) .le. 1.0)hte(ii,j) = 0.5*(hte(ii-1,j) + hte(   1,j))
  enddo
  print *,'min vals of hte at folds ',minval(hte(ni/2,:)),minval(hte(ni,:))

!---------------------------------------------------------------------
! some basic error checking
! find the i-th index of the poles at j= nj
! the corner points must lie on the pole
!---------------------------------------------------------------------

  ipole = -1
      j = nj
  do i = 1,ni/2
   if(ulat(i,j)/deg2rad .eq. 90.0)ipole(1) = i
  enddo
  do i = ni/2+1,ni
   if(ulat(i,j)/deg2rad .eq. 90.0)ipole(2) = i
  enddo
  print *,'poles found at ',ipole

  !htn must be the same along seam
   j = nj
  i1 = ipole(1); i2 = ipole(2)+1
  print *,'HTN across seam '
  print *,htn(i1-2,j),htn(i2+2,j)
  print *,htn(i1-1,j),htn(i2+1,j)
  print *,htn(i1,  j),htn(i2,  j)
  print *,htn(i1+1,j),htn(i2-1,j)
  print *,htn(i1+2,j),htn(i2-2,j)

  print *,'latCv across seam '
  print *,latCv(i1-2,j),latCv(i2+2,j)
  print *,latCv(i1-1,j),latCv(i2+1,j)
  print *,latCv(i1,  j),latCv(i2,  j)
  print *,latCv(i1+1,j),latCv(i2-1,j)
  print *,latCv(i1+2,j),latCv(i2-2,j)

  print *,'lonCv across seam '
  print *,lonCv(i1-2,j),lonCv(i2+2,j)
  print *,lonCv(i1-1,j),lonCv(i2+1,j)
  print *,lonCv(i1,  j),lonCv(i2,  j)
  print *,lonCv(i1+1,j),lonCv(i2-1,j)
  print *,lonCv(i1+2,j),lonCv(i2-2,j)

  print *,'angleT across seam '
  print *,angleT(i1-2,j),angleT(i2+2,j)
  print *,angleT(i1-1,j),angleT(i2+1,j)
  print *,angleT(i1,  j),angleT(i2,  j)
  print *,angleT(i1+1,j),angleT(i2-1,j)
  print *,angleT(i1+2,j),angleT(i2-2,j)

!---------------------------------------------------------------------
! write out cice grid file
!---------------------------------------------------------------------

  ! create a history attribute
   call date_and_time(date=cdate)
   history = 'created on '//trim(cdate)//' from '//trim(fname_in)

   call write_cdf

!---------------------------------------------------------------------
! extract the kmt into a separate file
!---------------------------------------------------------------------

   fname_in =  trim(dirout)//'grid_cice_NEMS_'//trim(res)//'.nc'
  fname_out = trim(dirout)//'kmtu_cice_NEMS_'//trim(res)//'.nc'

     cmdstr = 'ncks -O -v kmt '//trim(fname_in)//'  '//trim(fname_out)
     rc = system(trim(cmdstr))

end program gen_cicegrid
! -----------------------------------------------------------------------------
!> Return the modulo value of x in an interval [xc-(Lx/2) xc+(Lx/2)]
!! If Lx<=0, then it returns x without applying modulo arithmetic.
function modulo_around_point(x, xc, Lx) result(x_mod)
  real(kind=8), intent(in) :: x  !< Value to which to apply modulo arithmetic
  real(kind=8), intent(in) :: xc !< Center of modulo range
  real(kind=8), intent(in) :: Lx !< Modulo range width
  real(kind=8) :: x_mod          !< x shifted by an integer multiple of Lx to be close to xc.

  if (Lx > 0.0) then
    x_mod = modulo(x - (xc - 0.5*Lx), Lx) + (xc - 0.5*Lx)
  else
    x_mod = x
  endif
end function modulo_around_point