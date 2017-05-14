! Copyright (C) 2014 Santiago Badia, Alberto F. Martín and Javier Principe
!
! This file is part of FEMPAR (Finite Element Multiphysics PARallel library)
!
! FEMPAR is free software: you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation, either version 3 of the License, or
! (at your option) any later version.
!
! FEMPAR is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License
! along with FEMPAR. If not, see <http://www.gnu.org/licenses/>.
!
! Additional permission under GNU GPL version 3 section 7
!
! If you modify this Program, or any covered work, by linking or combining it 
! with the Intel Math Kernel Library and/or the Watson Sparse Matrix Package 
! and/or the HSL Mathematical Software Library (or a modified version of them), 
! containing parts covered by the terms of their respective licenses, the
! licensors of this Program grant you additional permission to convey the 
! resulting work. 
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
module p4est_serial_triangulation_names
  use, intrinsic :: iso_c_binding
  
  use types_names
  use stdio_names
  use memor_names
  use p4est_bindings_names
  
  use FPL

  implicit none
# include "debug.i90"
  private

  integer(ip), parameter :: NUM_CORNERS_2D           = 4
  integer(ip), parameter :: NUM_FACES_2D             = 4
  integer(ip), parameter :: NUM_SUBFACES_FACE_2D     = 2
  integer(ip), parameter :: NUM_FACE_CORNERS_2D      = 2
  integer(ip), parameter :: NUM_FACES_AT_CORNER_2D   = 2
  integer(ip), parameter :: NUM_VEFS_2D              = NUM_CORNERS_2D+NUM_FACES_2D
  integer(ip), parameter :: P4EST_FACE_CORNERS_2D(NUM_FACE_CORNERS_2D,NUM_FACES_2D) = & 
                                                  reshape([1, 3,&
                                                           2, 4,&  
                                                           1, 2,&
                                                           3, 4], [NUM_FACE_CORNERS_2D,NUM_FACES_2D])
                                                  
  integer(ip), parameter :: P4EST_FACES_AT_CORNER_2D(NUM_FACES_AT_CORNER_2D, NUM_CORNERS_2D) = & 
                                                    reshape([1, 3,&
                                                             2, 3,&  
                                                             1, 4,&
                                                             2, 4], [NUM_FACES_AT_CORNER_2D, NUM_CORNERS_2D])
                                                  
  integer(ip), parameter :: P4EST_OPPOSITE_CORNER(NUM_CORNERS_2D) = [ 4, 3, 2, 1 ]
  integer(ip), parameter :: P4EST_2_FEMPAR_CORNER(NUM_CORNERS_2D) = [ 1, 2, 3, 4 ]
  integer(ip), parameter :: P4EST_2_FEMPAR_FACE  (NUM_FACES_2D)   = [ 3, 4, 1, 2 ]
  
  ! TODO: this data type should extend an abstract triangulation,
  !       and implement its corresponding accessors
  type p4est_serial_triangulation_t
    private
    integer(ip) :: num_cells          = -1
    integer(ip) :: num_dimensions     = -1
    integer(ip) :: num_vefs           = -1
    integer(ip) :: num_proper_vefs    = -1 
    integer(ip) :: num_improper_vefs  = -1 
    type(c_ptr) :: p4est_connectivity = c_null_ptr
    type(c_ptr) :: p4est              = c_null_ptr
    type(c_ptr) :: p4est_mesh         = c_null_ptr
    ! TODO: I am pretty sure that a type(c_ptr) :: p4est_ghost
    !       member variable will be needed (at least in the parallel realization)
    
    ! p4est quadrant connectivity (1:NUM_FACES_2D/3D,1:nQuads) => neighbor quadrant
    integer(P4EST_F90_LOCIDX),pointer     :: quad_to_quad(:,:)   => NULL()
    ! p4est face connectivity (1:NUM_FACES_2D/3D,1:nQuads) => neighbor faceId + orientation + non-conform info
    integer(P4EST_F90_QLEVEL),pointer     :: quad_to_face(:,:)   => NULL()   
    ! p4est face connectivity for mortars NUM_SUBFACES_FACE_2D/3D,1:nHalfFaces), (~small sides)
    integer(P4EST_F90_LOCIDX),pointer     :: quad_to_half(:,:)   => NULL()
    integer(P4EST_F90_LOCIDX),pointer     :: quad_to_corner(:,:) => NULL()

    ! TODO: The following 3x member variables should be replaced by our F200X implementation of "std::vector<T>" 
    ! p4est Integer coordinates of first quadrant node (xy/xyz,nQuads)
    integer(P4EST_F90_LOCIDX), allocatable :: quad_coords(:,:)
    ! p4est Integer Level of quadrant
    integer(P4EST_F90_QLEVEL), allocatable :: quad_level(:)
    integer(ip)              , allocatable :: lst_vefs_lids(:)    
  contains
    procedure, non_overridable          :: create                          => p4est_serial_triangulation_create
    procedure, non_overridable          :: free                            => p4est_serial_triangulation_free
    procedure, non_overridable          :: refine_and_coarsen              => p4est_serial_triangulation_refine_and_coarsen
    procedure, private, non_overridable :: update_p4est_mesh               => p4est_serial_triangulation_update_p4est_mesh
    procedure, private, non_overridable :: update_topology_from_p4est_mesh => p4est_serial_triangulation_update_topology_from_p4est_mesh
    procedure, private, non_overridable :: ptr_vefs_per_cell               => p4est_serial_triangulation_ptr_vefs_per_cell
    procedure, private, non_overridable :: update_lst_vefs_lids            => p4est_serial_triangulation_update_lst_vefs_lids
    procedure, private, non_overridable :: free_lst_vefs_lids              => p4est_serial_triangulation_free_lst_vefs_lids
#ifndef ENABLE_P4EST
    procedure, non_overridable :: not_enabled_error => p4est_serial_triangulation_not_enabled_error
#endif
  end type p4est_serial_triangulation_t
  
  public :: p4est_serial_triangulation_t
  
contains

subroutine p4est_serial_triangulation_create (this, parameters)
  implicit none
  class(p4est_serial_triangulation_t), intent(inout) :: this
  type(ParameterList_t)              , intent(in)    :: parameters
  
#ifdef ENABLE_P4EST
  call this%free()
  this%num_cells = 1
  
  ! TODO: Extract num_dimensions out of parameters
  this%num_dimensions = 2
  
  if ( this%num_dimensions == 2 ) then
    call F90_p4est_connectivity_new_unitsquare(this%p4est_connectivity)
    call F90_p4est_new(this%p4est_connectivity, this%p4est)
    call this%update_p4est_mesh()
    call this%update_topology_from_p4est_mesh()
    call this%update_lst_vefs_lids()
  else if ( this%num_dimensions == 3 ) then
    check(.false.)
  end if  
#else
  call this%not_enabled_error()
#endif
end subroutine p4est_serial_triangulation_create  

subroutine p4est_serial_triangulation_refine_and_coarsen(this)
  implicit none
  class(p4est_serial_triangulation_t), intent(inout) :: this
  
#ifdef ENABLE_P4EST
  if ( this%num_dimensions == 2 ) then
    call F90_p4est_refine(this%p4est)
    call this%update_p4est_mesh()
    call this%update_topology_from_p4est_mesh()
    ! Update the number of triangulation cells
    this%num_cells = size(this%quad_level)
    call this%update_lst_vefs_lids()
  else if ( this%num_dimensions == 3 ) then
    check(.false.)
  end if
#else
  call this%not_enabled_error()
#endif  
  
end subroutine p4est_serial_triangulation_refine_and_coarsen

function p4est_serial_triangulation_ptr_vefs_per_cell(this, icell)
  implicit none
  class(p4est_serial_triangulation_t), intent(in) :: this
  integer(ip) :: p4est_serial_triangulation_ptr_vefs_per_cell
  integer(ip) :: icell
  integer(ip) :: num_vefs_per_cell

#ifdef ENABLE_P4EST
  assert (icell>= 1 .and. icell <= this%num_cells+1)
  if ( this%num_dimensions == 2 ) then
    num_vefs_per_cell = NUM_VEFS_2D
  else if ( this%num_dimensions == 3 ) then
  end if
  p4est_serial_triangulation_ptr_vefs_per_cell = (icell-1)*num_vefs_per_cell+1
#else
  call this%not_enabled_error()
#endif  
  
end function p4est_serial_triangulation_ptr_vefs_per_cell

subroutine p4est_serial_triangulation_update_lst_vefs_lids(this)
  implicit none
  class(p4est_serial_triangulation_t), intent(inout) :: this
  integer(ip) :: num_corners_per_cell, num_edges_per_cell, num_faces_per_cell
  integer(ip) :: num_face_corners, num_faces_at_corner, num_subfaces_face
  integer(ip) :: icell, icell_iface, icell_icorner
  integer(ip) :: jcell, jcell_iface, jcell_icorner
  integer(ip) :: min_cell, min_icorner, min_iface, icorner, iedge, iface
  integer(ip) :: iface_at_corner
  integer(ip) :: face_corner, flip, mortar
  integer(P4EST_F90_QLEVEL) :: jcell_iconn 
  logical :: is_proper
  integer(ip) :: isubface
  
  call this%free_lst_vefs_lids()
  
  if ( this%num_dimensions == 2 ) then
     num_corners_per_cell = NUM_CORNERS_2D
     num_edges_per_cell   = 0 
     num_faces_per_cell   = NUM_FACES_2D
     num_face_corners     = NUM_FACE_CORNERS_2D
     num_faces_at_corner  = NUM_FACES_AT_CORNER_2D
     num_subfaces_face    = NUM_SUBFACES_FACE_2D
  else if ( this%num_dimensions == 3 ) then
     check(.false.)
  end if
 

  call memalloc(this%ptr_vefs_per_cell(this%num_cells+1)-1, &
                this%lst_vefs_lids, __FILE__, __LINE__)


  this%num_proper_vefs   = 0
  this%num_improper_vefs = 0
  this%num_vefs          = 0
  
  do icell=1, this%num_cells
     do icorner=1, num_corners_per_cell
       is_proper   = .true.
       min_cell    = icell
       min_icorner = icorner 

       ! Find face neighbours
       do iface_at_corner=1, num_faces_at_corner
         icell_iface = P4EST_FACES_AT_CORNER_2D(iface_at_corner,icorner)
         jcell_iconn = this%quad_to_face(icell_iface,icell)         
         
         call p4est_eval_connectivity(jcell_iconn, jcell_iface, flip, mortar)
         assert (flip==1) ! All cells we are working with MUST be aligned with each other

         if (mortar == -1) then ! Conformal neighbour
            jcell      = this%quad_to_quad(icell_iface,icell)+1 
            ! Check whether icell across current face is at the boundary
            if ( icell == jcell ) cycle 
            min_cell   = min(min_cell,jcell)
            if (min_cell == jcell) then
               min_icorner=p4est_get_jcell_icorner(icell_iface,jcell_iface,icorner)
            end if
         else if ( mortar >= 1 .and. mortar <= num_subfaces_face )  then ! Double-size neighbour 
            jcell      = this%quad_to_quad(icell_iface,icell)+1
             
            ! Determine whether this corner is improper
            ! 1. Go to coarser neighbour and find across which subface am I neighbour
            do isubface = 1, num_subfaces_face
              if (this%quad_to_half(isubface,this%quad_to_quad(jcell_iface, jcell)+1)+1==icell) then
                exit
              end if
            end do
            assert(isubface<=num_subfaces_face)
            
            ! 2. Determine which face_corner of my face am I
            do face_corner=1, num_face_corners
              if (P4EST_FACE_CORNERS_2D(face_corner,icell_iface) == icorner) then
                exit
              end if
            end do
            assert(face_corner<=num_face_corners)
           
            ! 3. I am improper if am either corner 1 of subface 0 or corner 0 of subface 1
            !    (this works at least for 2D)
            if ( face_corner /= isubface ) then
              is_proper = .false.
            else
              min_cell   = min(min_cell,jcell)
              if (min_cell == jcell) then
                min_icorner=p4est_get_jcell_icorner(icell_iface,jcell_iface,icorner)
              end if
            end if

         else ! Half-side neighbour 
            assert (mortar == 3)
            ! Determine which face_corner of my face am I
            do face_corner=1, num_face_corners
              if (P4EST_FACE_CORNERS_2D(face_corner,icell_iface) == icorner) then
                exit
              end if
            end do
            assert(face_corner<=num_face_corners)
            jcell       = this%quad_to_half(face_corner,this%quad_to_quad(icell_iface,icell)+1)+1
            min_cell   = min(min_cell,jcell)
            if (min_cell == jcell) then
               min_icorner=p4est_get_jcell_icorner(icell_iface,jcell_iface,icorner)
            end if
         end if
       end do  
       
       ! A corner cannot become improper by a corner neighbour which is not a face neighbour
       jcell          = this%quad_to_corner(icorner,icell)+1
       jcell_icorner  = P4EST_OPPOSITE_CORNER(icorner)

       if (jcell /= 0) then
         min_cell   = min(min_cell,jcell)
         if (min_cell == jcell) then
            min_icorner=jcell_icorner
         end if
       end if  
       
       ! If am owner of this corner
       if (icell == min_cell) then
         if (is_proper) then
           this%num_proper_vefs = this%num_proper_vefs+1
           this%lst_vefs_lids(this%ptr_vefs_per_cell(icell)+icorner-1) = this%num_proper_vefs
         else 
          this%num_improper_vefs = this%num_improper_vefs+1
          this%lst_vefs_lids(this%ptr_vefs_per_cell(icell)+icorner-1) = -this%num_improper_vefs
         end if
       else
         this%lst_vefs_lids(this%ptr_vefs_per_cell(icell)+icorner-1) = this%lst_vefs_lids(this%ptr_vefs_per_cell(min_cell)+min_icorner-1)
       end if
     end do
     
     do iedge=1, num_edges_per_cell
     end do
     
     do iface=1, num_faces_per_cell
       is_proper   = .true.
       min_cell    = icell
       min_iface   = iface 
       jcell_iconn = this%quad_to_face(iface,icell)         
       call p4est_eval_connectivity(jcell_iconn, jcell_iface, flip, mortar)
       assert (flip==1) ! All cells we are working with MUST be aligned with each other
       if (mortar == -1) then ! Conformal neighbour
         jcell      = this%quad_to_quad(iface,icell)+1 
         min_cell = min(min_cell,jcell)
         if (min_cell == jcell) then
            min_iface=this%quad_to_face(iface,icell)+1 
         end if
       else if ( mortar >= 1 .and. mortar <= num_subfaces_face )  then ! Double-size neighbour 
         is_proper = .false. 
       end if

       ! If am owner of this corner
       if (icell == min_cell) then
         if (is_proper) then
           this%num_proper_vefs=this%num_proper_vefs+1
           this%lst_vefs_lids(this%ptr_vefs_per_cell(icell)+num_corners_per_cell+P4EST_2_FEMPAR_FACE(iface)-1) = this%num_proper_vefs
         else 
          this%num_improper_vefs=this%num_improper_vefs+1
          this%lst_vefs_lids(this%ptr_vefs_per_cell(icell)+num_corners_per_cell+P4EST_2_FEMPAR_FACE(iface)-1) = -this%num_improper_vefs
         end if
       else ! Borrow vef gid from owner
         this%lst_vefs_lids(this%ptr_vefs_per_cell(icell)+num_corners_per_cell+P4EST_2_FEMPAR_FACE(iface)-1) = & 
               this%lst_vefs_lids(this%ptr_vefs_per_cell(min_cell)+num_corners_per_cell+P4EST_2_FEMPAR_FACE(min_iface)-1)
       end if
     end do
  end do
  this%num_vefs = this%num_proper_vefs + this%num_improper_vefs 
end subroutine p4est_serial_triangulation_update_lst_vefs_lids

subroutine p4est_serial_triangulation_free_lst_vefs_lids(this)
  implicit none
  class(p4est_serial_triangulation_t), intent(inout) :: this
  if (allocated(this%lst_vefs_lids)) &
    call memfree(this%lst_vefs_lids, __FILE__, __LINE__)
end subroutine p4est_serial_triangulation_free_lst_vefs_lids

subroutine p4est_serial_triangulation_update_p4est_mesh(this)
  implicit none
  class(p4est_serial_triangulation_t), intent(inout) :: this
  
#ifdef ENABLE_P4EST
  if ( this%num_dimensions == 2 ) then
    call F90_p4est_mesh_new(this%p4est, this%p4est_mesh)
  else if ( this%num_dimensions == 3 ) then
    check(.false.)
  end if
#else
  call this%not_enabled_error()
#endif   
end subroutine p4est_serial_triangulation_update_p4est_mesh

subroutine p4est_serial_triangulation_update_topology_from_p4est_mesh(this)
 implicit none 
 class(p4est_serial_triangulation_t), intent(inout) :: this
 integer(P4EST_F90_LOCIDX) :: local_num_quadrants
 integer(P4EST_F90_GLOIDX) :: global_num_quadrants
 integer(P4EST_F90_GLOIDX) :: global_first_quadrant
 integer(P4EST_F90_LOCIDX) :: num_half_faces
 type(c_ptr) :: QQ, QF, QH, QC
 
#ifdef ENABLE_P4EST
 if ( this%num_dimensions == 2 ) then
  call F90_p4est_get_mesh_info(this%p4est, &
                               this%p4est_mesh, &
                               local_num_quadrants, &
                               global_num_quadrants, &
                               global_first_quadrant, &
                               num_half_faces)
 
  if (allocated(this%quad_coords)) &
     call memfree(this%quad_coords, __FILE__, __LINE__)
  
  if (allocated(this%quad_level)) &
    call memfree(this%quad_level, __FILE__, __LINE__)
  
  call memalloc(2, local_num_quadrants, this%quad_coords, __FILE__, __LINE__)
  call memalloc(local_num_quadrants, this%quad_level, __FILE__, __LINE__ )
  
  call F90_p4est_get_mesh_topology_arrays(this%p4est, &
                                          this%p4est_mesh, &
                                          QQ, &
                                          QF, &
                                          QH, &
                                          QC, &
                                          this%quad_coords, &
                                          this%quad_level)
  
  call c_f_pointer(qq,this%quad_to_quad,[NUM_FACES_2D,local_num_quadrants])
  call c_f_pointer(qf,this%quad_to_face,[NUM_FACES_2D,local_num_quadrants])
  if(num_half_faces>0) call c_f_pointer(qh,this%quad_to_half,[NUM_SUBFACES_FACE_2D,num_half_faces])
  call c_f_pointer(qc,this%quad_to_corner,[NUM_CORNERS_2D,local_num_quadrants])
 else if ( this%num_dimensions == 3 ) then
   check(.false.)
 end if 
  
#else
  call this%not_enabled_error()
#endif
end subroutine p4est_serial_triangulation_update_topology_from_p4est_mesh

subroutine p4est_serial_triangulation_free ( this)
  implicit none
  class(p4est_serial_triangulation_t), intent(inout) :: this

#ifdef ENABLE_P4EST
  if ( this%num_dimensions == 2 ) then
    call F90_p4est_destroy(this%p4est)
    call F90_p4est_connectivity_destroy(this%p4est_connectivity)
    call F90_p4est_mesh_destroy(this%p4est_mesh)
  
    this%p4est_connectivity = c_null_ptr
    this%p4est              = c_null_ptr
    this%p4est_mesh         = c_null_ptr
  else if ( this%num_dimensions == 3 ) then
    check(.false.)
  end if
  
  call this%free_lst_vefs_lids()
  
  nullify(this%quad_to_quad)
  nullify(this%quad_to_face)
  nullify(this%quad_to_half)
  
  if (allocated(this%quad_coords)) &
     call memfree(this%quad_coords, __FILE__, __LINE__)
  
  if (allocated(this%quad_level)) &
    call memfree(this%quad_level, __FILE__, __LINE__)
  
  this%num_dimensions  = -1
  this%num_cells = -1
  this%num_vefs = -1
  this%num_proper_vefs = -1
  this%num_improper_vefs = -1
#else
  call this%not_enabled_error()
#endif     
end subroutine p4est_serial_triangulation_free


SUBROUTINE p4est_eval_connectivity(Conn,nbSide,Flip,Mortar)
  IMPLICIT NONE
  INTEGER(P4EST_F90_QLEVEL),INTENT(IN)   :: Conn   ! p4est Side,Flip,Mortar encoding
  INTEGER(ip)              ,INTENT(OUT)  :: nbSide ! Neighbour side in p4est convention: 1..4
  INTEGER(ip)              ,INTENT(OUT)  :: Flip   ! Flip in p4est convention: 1..2
  INTEGER(ip)              ,INTENT(OUT)  :: Mortar ! Mortar in p4est convention: 1..2,
                                                   ! -1 if conformal, 3 if half-size neighbour
  INTEGER(ip) :: tmp
  !------------------------------------------------------------------------------------------
  ! The quad_to_quad list stores one value for each local quadrant's face.
  ! This value is in 0..local_num_quadrants-1 for local quadrants, or in
  ! local_num_quadrants + (0..ghost_num_quadrants-1) for ghost quadrants.
  ! The quad_to_face list has equally many entries which are either:
  ! 1. A value of v = 0..7 indicates one same-size neighbor.
  !    This value is decoded as v = r * 4 + nf, where nf = 0..3 is the
  !    neigbbor's connecting face number and r = 0..1 is the relative
  !    orientation of the neighbor's face, see p4est_connectivity.h.
  ! 2. A value of v = 8..23 indicates a double-size neighbor.
  !    This value is decoded as v = 8 + h * 8 + r * 4 + nf, where
  !    r and nf are as above and h = 0..1 is the number of the subface.
  ! 3. A value of v = -8..-1 indicates two half-size neighbors.
  !    In this case the corresponding quad_to_quad index points into the
  !    quad_to_half array which stores two quadrant numbers per index,
  !    and the orientation of the smaller faces follows from 8 + v.
  !    The entries of quad_to_half encode between local and ghost quadrant
  !    in the same way as the quad_to_quad values described above.
  ! A quadrant on the boundary of the forest sees itself and its face number.

  SELECT CASE(Conn)
  CASE(0:7)   ! 1. conformal neighbour
    nbSide = MOD(Conn,4)+1     ! 1..4
    Flip   = Conn/4+1          ! 1..2
    Mortar = -1
  CASE(8:23) ! 2. double-size neighbour
    tmp    = MOD(Conn,8)       ! 0..7
    nbSide = MOD(tmp,4)+1      ! 1..4 
    Flip   = tmp/4+1           ! 1..2
    Mortar = (Conn-tmp-8)/8+1  ! 1..2 
  CASE(-8:-1) ! 3. half-size neighbour
    tmp    = Conn+8
    nbSide = MOD(tmp,4)+1     ! 1..4
    Flip   = tmp/4+1          ! 1..2
    Mortar = 3 
  CASE DEFAULT
    ! This type of face connectivity does not exist
    assert(.false.)
  END SELECT

END SUBROUTINE p4est_eval_connectivity

function p4est_get_jcell_icorner(icell_iface,jcell_iface,icell_icorner)
  implicit none
  integer(ip), intent(in) :: icell_iface 
  integer(ip), intent(in) :: jcell_iface 
  integer(ip), intent(in) :: icell_icorner 
  integer(ip) :: p4est_get_jcell_icorner

  p4est_get_jcell_icorner = -1
  SELECT CASE(icell_icorner)
  CASE(1) 
    if (icell_iface == 3 .and. jcell_iface == 4) then
      p4est_get_jcell_icorner = 3 
    else if (icell_iface == 1 .and. jcell_iface == 2) then
      p4est_get_jcell_icorner = 2 
    end if    
  CASE(2)
    if (icell_iface == 2 .and. jcell_iface == 1) then
      p4est_get_jcell_icorner = 1 
    else if (icell_iface == 3 .and. jcell_iface == 4) then
      p4est_get_jcell_icorner = 4 
    end if    
  CASE(3)
    if (icell_iface == 4 .and. jcell_iface == 3) then
      p4est_get_jcell_icorner = 1
    else if (icell_iface == 1 .and. jcell_iface == 2) then
      p4est_get_jcell_icorner = 4 
    end if    
  CASE(4)
    if (icell_iface == 2 .and. jcell_iface == 1) then
      p4est_get_jcell_icorner = 3 
    else if (icell_iface == 3 .and. jcell_iface == 4) then
      p4est_get_jcell_icorner = 2 
    end if    
  END SELECT 
  assert(p4est_get_jcell_icorner/=-1)
end function p4est_get_jcell_icorner


#ifndef ENABLE_P4EST
  subroutine p4est_serial_triangulation_not_enabled_error(this)
    class(p4est_serial_triangulation_t), intent(inout) :: this
    write (stderr,*) 'Error: FEMPAR was not compiled with -DENABLE_P4EST.'
    write (stderr,*) "Error: You must activate this CPP macro in order to use P4EST"
    check(.false.)
  end subroutine p4est_serial_triangulation_not_enabled_error
#endif

end module p4est_serial_triangulation_names
