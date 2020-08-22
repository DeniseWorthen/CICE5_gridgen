subroutine editmask(maskin)
#ifdef output_grid_1deg
  use netcdf
  use param
  use grdvars
  use charstrings
  
  implicit none

  real(kind=4), intent(inout) :: maskin(ni,nj)

  ! local variables
  integer :: rc, ncid, id
  integer :: i,j,npts,ii,jj,k
  character(len=256) :: fname_in

       integer, allocatable, dimension(:) :: iedit,jedit
  real(kind=4), allocatable, dimension(:) :: zedit

  real(kind=4), dimension(ni,nj) :: tmpmask

!---------------------------------------------------------------------
! get the edits
!---------------------------------------------------------------------

  fname_in = trim(dirsrc)//trim(editfile)

  rc = nf90_open(fname_in, nf90_nowrite, ncid)
  print *, 'reading edits from ',trim(fname_in)
  print *, 'nf90_open = ',trim(nf90_strerror(rc))

  rc = nf90_inq_dimid(ncid, 'nEdits', id)
  rc = nf90_inquire_dimension(ncid, id, len=npts)

  allocate(iedit(1:npts), jedit(1:npts),zedit(1:npts))

  rc = nf90_inq_varid(ncid,  'iEdit',    id)
  rc = nf90_get_var(ncid,         id, iedit)
  rc = nf90_inq_varid(ncid,  'jEdit',    id)
  rc = nf90_get_var(ncid,         id, jedit)
  rc = nf90_inq_varid(ncid,  'zEdit',    id)
  rc = nf90_get_var(ncid,         id, zedit)
  rc = nf90_close(ncid)

!---------------------------------------------------------------------
!
!---------------------------------------------------------------------

  tmpmask = maskin
  do k = 1,npts
    ii = iedit(k); jj = jedit(k)
    print *,k,ii,jj,maskin(ii,jj),zedit(k)
    if(maskin(ii,jj) .eq. 0.0)tmpmask(ii,jj) = 1.0
  end do
  maskin = tmpmask

  deallocate(iedit,jedit,zedit)
#endif
end subroutine editmask
