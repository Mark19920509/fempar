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
module mesh_names
  use types_names
  use memor_names
  use sort_names
  use list_types_names
  use hash_table_names
  use stdio_names
  use reference_fe_names
  use mesh_distribution_names
  use mesh_distribution_parameters_names
  use metis_interface_names
  use rcm_renumbering_names
  use postpro_names
  use FPL
  use environment_names

  implicit none
# include "debug.i90"
  private

  integer(ip), parameter :: c_order = 0
  integer(ip), parameter :: z_order = 1
  integer(ip), parameter :: max_num_elem_types = 3

  integer(ip), target :: permu_2DP1(3) = (/ 1, 2, 3/)
  integer(ip), target :: permu_2DQ1(4) = (/ 1, 2, 4, 3/)
  integer(ip), target :: permu_3DP1(4) = (/ 1, 2, 3, 4/)
  integer(ip), target :: permu_3DPR(6) = (/ 1, 2, 3, 4, 5, 6/)
  integer(ip), target :: permu_3DQ1(8) = (/ 1, 2, 4, 3, 5, 6, 8, 7/)
  integer(ip), target :: permu_id  (8) = (/ 1, 2, 3, 4, 5, 6, 7, 8/)


  type mesh_t
     ! Sizes
     integer(ip)                :: &
          order=c_order,           &         ! GiD element order (c)
          nelty=1,                 &         ! Number of element types
          ndime,                   &         ! Number of space dimensions
          npoin,                   &         ! Number of nodes (vertices)
          nvefs,                   &         ! Number of vefs
          nelem,                   &         ! Number of elements
          nnode,                   &         ! Maximum number of nodes per element
          nboun,                   &         ! Number of boundary elements
          nnodb                              ! Maximum number of nodes per boundary element

     ! Elements
     integer(ip), allocatable ::  &
          pnods(:),               &         ! pointers to the lnods
          lnods(:),               &         ! list of vefs of each element
          legeo(:),               &         ! List of geometry (volume) each element lies in
          leset(:),               &         ! List of sets associated to each element
          pvefs(:),               &         ! pointers to the lvefs
          lvefs(:),               &         ! list of vefs of each element
          lvef_geo(:),            &         ! List of geometric entities (volume, surface, point) each vef lies in
          lvef_set(:)                       ! List of sets associated to each vef

     ! List of vefs over which a definition of a set and/or a geometry is relevant. Tipically used
     ! to set boundary conditions but also useful for other purposes, e.g. an internal interface 
     ! separating materials over which a force has to be computed.
     type(list_t)             ::  &
          given_vefs                        ! boundary elements (vefs)      
     integer(ip), allocatable ::  &
          lst_vefs_geo(:),        &         ! List of geometric entities (volume, surface, point) each vef lies in
          lst_vefs_set(:)                   ! List of sets associated to each boundary

     ! Dual mesh (elements around vertices)
     integer(ip)              ::  &
          nelpo = 0                         ! Nonzero when created
     integer(ip), allocatable ::  &
          pelpo(:),               &
          lelpo(:)

     real(rp), allocatable ::     &
          coord(:,:)                         ! Vertex coordinates

     type(p_reference_fe_t)   ::  ref_fe_list(max_num_elem_types)
    
    contains
     ! JP-TODO: program get and set for variables.
     procedure, non_overridable          :: to_dual                       => mesh_to_dual
     procedure, non_overridable          :: create_distribution           => create_mesh_distribution
     procedure, non_overridable          :: get_sizes                     => mesh_get_sizes
     procedure, non_overridable          :: move_cells                    => mesh_move_cells
     procedure, non_overridable          :: move_coordinates              => mesh_move_coordinates
     procedure, non_overridable          :: get_coordinates               => mesh_get_coordinates
     procedure, non_overridable          :: get_given_vefs                => mesh_get_given_vefs
     procedure, non_overridable          :: free                          => mesh_free
     procedure, non_overridable          :: read_from_unit                => mesh_read_from_unit
     procedure, non_overridable          :: read_from_file                => mesh_read_from_file
     generic                             :: read                          => read_from_file, read_from_unit
     procedure, non_overridable, nopass  :: compose_name                  => mesh_compose_name
     procedure, non_overridable, nopass  :: check_and_get_path_and_prefix_from_parameterlist
     procedure, non_overridable          :: write_file_for_postprocess    => mesh_write_file_for_postprocess
  end type mesh_t

  ! Types
  public :: mesh_t

  ! Constants
  public :: c_order, z_order

  ! Functions
  public :: mesh_write_file, mesh_write_files, mesh_write_files_for_postprocess
  public :: mesh_distribution_write_for_postprocess

contains

  !=============================================================================
  subroutine mesh_get_sizes(this,ndime,npoin,nnode,nelem)
    class(mesh_t), intent(inout) :: this
    integer(ip), intent(inout) :: ndime,npoin,nnode,nelem
    ndime=this%ndime  ! Number of space dimensions
    npoin=this%npoin  ! Number of nodes (vertices)
    nelem=this%nelem  ! Number of elements
    nnode=this%nnode  ! Maximum number of nodes per element
  end subroutine mesh_get_sizes
  !=============================================================================
  subroutine mesh_move_cells(this,pvefs,lvefs,cells_set)
    class(mesh_t)           , intent(inout) :: this
    integer(ip), allocatable, intent(inout) :: pvefs(:)
    integer(ip), allocatable, intent(inout) :: lvefs(:)
    integer(ip), allocatable, intent(inout) :: cells_set(:)
    call memmovealloc(this%pnods,pvefs,__FILE__,__LINE__)
    call memmovealloc(this%lnods,lvefs,__FILE__,__LINE__)
    call memmovealloc(this%leset,cells_set,__FILE__,__LINE__)
  end subroutine mesh_move_cells
  !=============================================================================
  subroutine mesh_move_coordinates(this,coord)
    class(mesh_t)        , intent(inout) :: this
    real(rp), allocatable, intent(inout) :: coord(:,:)
    call memmovealloc(this%coord,coord,__FILE__,__LINE__)
  end subroutine mesh_move_coordinates
  !=============================================================================
  function mesh_get_coordinates(this)
    class(mesh_t), target, intent(inout) :: this
    real(rp)     , pointer       :: mesh_get_coordinates(:,:)
    mesh_get_coordinates => this%coord
  end function mesh_get_coordinates
  !=============================================================================
  subroutine mesh_get_given_vefs(this,given_vefs,lst_vefs_geo,lst_vefs_set)
    class(mesh_t), target   , intent(inout) :: this
    type(list_t), pointer   , intent(inout) :: given_vefs
    integer(ip) , pointer   , intent(inout) :: lst_vefs_geo(:), lst_vefs_set(:)
    given_vefs => this%given_vefs
    lst_vefs_geo => this%lst_vefs_geo
    lst_vefs_set => this%lst_vefs_set
  end subroutine mesh_get_given_vefs

!=============================================================================
  subroutine mesh_to_dual(this)
    class(mesh_t), intent(inout)     :: this
    
    ! Local variables
    integer(ip)              :: inode, ipoin, ielem, size_lnods

    if(this%nelpo>0) return

    call memalloc (this%npoin+1, this%pelpo, __FILE__,__LINE__)
    size_lnods = this%pnods(this%nelem+1)-1 
    
    ! Compute the number of elements around each point
    this%pelpo=0
    do inode=1, size_lnods
       ipoin=this%lnods(inode)
       this%pelpo(ipoin+1)=this%pelpo(ipoin+1)+1
    end do
    
    ! Find the maximum number of elements around a point
    this%nelpo=0
    do ipoin=1,this%npoin
       this%nelpo=max(this%nelpo,this%pelpo(ipoin+1))
    end do
    
    ! Compute pointers to the starting position of the list
    ! of elements around each point
    this%pelpo(1)=1
    do ipoin=1,this%npoin
       this%pelpo(ipoin+1)=this%pelpo(ipoin+1)+this%pelpo(ipoin)
    end do

    ! Allocate lelpo and fill it
    call memalloc (this%pelpo(this%npoin+1), this%lelpo, __FILE__,__LINE__)

    ! Compute the list of elements around each point.
    ! pelpo is used instead of auxiliary work space.
    do ielem=1,this%nelem 
       do inode=this%pnods(ielem),this%pnods(ielem+1)-1 
          ipoin=this%lnods(inode)
          this%lelpo(this%pelpo(ipoin))=ielem
          this%pelpo(ipoin)=this%pelpo(ipoin)+1
       end do
    end do
    
    ! Recover pelpo
    do ipoin=this%npoin+1, 2, -1
       this%pelpo(ipoin)=this%pelpo(ipoin-1)
    end do
    this%pelpo(1) = 1

  end subroutine mesh_to_dual

  !=============================================================================
  subroutine mesh_free (msh)
    !-----------------------------------------------------------------------
    ! This routine generates deallocates a mesh
    !-----------------------------------------------------------------------
    implicit none
    class(mesh_t), intent(inout)  :: msh

    if (allocated(msh%pnods)) call memfree (msh%pnods,__FILE__,__LINE__)
    if (allocated(msh%lnods)) call memfree (msh%lnods,__FILE__,__LINE__)
    if (allocated(msh%legeo)) call memfree (msh%legeo,__FILE__,__LINE__)
    if (allocated(msh%leset)) call memfree (msh%leset,__FILE__,__LINE__)
    if (allocated(msh%pvefs)) call memfree (msh%pvefs,__FILE__,__LINE__)
    if (allocated(msh%lvefs)) call memfree (msh%lvefs,__FILE__,__LINE__)
    if (allocated(msh%lvef_geo)) call memfree (msh%lvef_geo,__FILE__,__LINE__)
    if (allocated(msh%lvef_set)) call memfree (msh%lvef_set,__FILE__,__LINE__)
    if (allocated(msh%coord))    call memfree (msh%coord,__FILE__,__LINE__)

    msh%ndime=0
    msh%npoin=0
    msh%nvefs=0
    msh%nelem=0
    msh%nnode=0
    msh%order=c_order
    msh%nelty=1

    call msh%given_vefs%free()
    if (allocated(msh%lst_vefs_geo)) call memfree (msh%lst_vefs_geo,__FILE__,__LINE__)
    if (allocated(msh%lst_vefs_set)) call memfree (msh%lst_vefs_set,__FILE__,__LINE__)
    msh%nnodb=0

    if (allocated(msh%pelpo)) call memfree (msh%pelpo,__FILE__,__LINE__)
    if (allocated(msh%lelpo)) call memfree (msh%lelpo,__FILE__,__LINE__)
    msh%nelpo = 0

  end subroutine mesh_free

  !===============================================================================================
  subroutine mesh_copy(msh_old,msh_new)
    implicit none
    type(mesh_t), intent(in)    :: msh_old
    type(mesh_t), intent(inout) :: msh_new

    msh_new%ndime = msh_old%ndime
    msh_new%npoin = msh_old%npoin
    msh_new%nelem = msh_old%nelem
    msh_new%nnode = msh_old%nnode
    
    call memalloc(msh_new%nelem+1,msh_new%pnods,__FILE__,__LINE__)
    msh_new%pnods = msh_old%pnods

    call memalloc(msh_new%pnods(msh_new%nelem+1)-1,msh_new%lnods,__FILE__,__LINE__)
    msh_new%lnods = msh_old%lnods

    if (allocated(msh_old%coord)) then
       call memalloc(SPACE_DIM,msh_new%npoin,msh_new%coord,__FILE__,__LINE__)
       msh_new%coord = msh_old%coord
    end if

  end subroutine mesh_copy
  
  !=============================================================================
  subroutine mesh_read_from_unit(msh,lunio)
    !------------------------------------------------------------------------
    !
    ! This routine reads a mesh writen by GiD according to fempar problem type.
    !
    !------------------------------------------------------------------------
    implicit none
    integer(ip)      , intent(in)  :: lunio
    class(mesh_t)     , intent(out) :: msh
    !logical, optional, intent(in)  :: permute_c2z
    integer(ip)     :: idime,ipoin,inode,ielem,nboun,iboun,vbound,nnode,nnodb ! ,istat,jpoin,jelem,iboun
    character(14)   :: dum1
    character(7)    :: dum2
    character(7)    :: dum3
    character(10)   :: dum4
    character(10)   :: dum5
    character(6)   :: dum6
    character(1000) :: tel
    integer(ip), allocatable :: lnods_aux(:)
 integer(ip), allocatable :: sorted_nodes(:) 
    integer(ip), allocatable :: bound_list_aux(:)
    type(list_iterator_t)    :: bound_iterator
    integer(ip), pointer     :: permu(:)
    logical                  :: permute_c2z_

    ! Read first line: "MESH dimension  2  order  0  types  1  elements          1  vertices          4  vefs          8
    read(lunio,'(a14,1x,i2, a7,1x,i2, a7,1x,i2, a10,1x,i10, a10,1x,i10, a6,1x,i10)') &
         & dum1,msh%ndime,dum2,msh%order,dum3,msh%nelty,dum4,msh%nelem, dum5,msh%npoin,dum6,nboun

    !write(*,*) 'Read mesh with parameters:',msh%ndime,msh%order,msh%nelty,msh%nelem,msh%npoin,nboun

    ! Read nodes
    call memalloc(SPACE_DIM,msh%npoin,msh%coord,__FILE__,__LINE__)
    ! In case of 2D domains (num_dims=2) when SPACE_DIM is used, it is necessary to initialize the
    ! coordinates array to zero in order to guarantee that the third component is initialized to zero.
    ! The use of SPACE_DIM instead num_dims is based on the fact that this variable is known in
    ! compilation time, allowing the compiler to perform additional optimizations.
    msh%coord = 0.0_rp
    do while(tel(1:5).ne.'coord')
       read(lunio,'(a)') tel
    end do
    read(lunio,'(a)') tel
    do while(tel(1:5).ne.'end c')
       read(tel,*) ipoin,(msh%coord(idime,ipoin),idime=1,msh%ndime)
       read(lunio,'(a)') tel
    end do

    ! Read elements' size (pnods)
    call memalloc(msh%nelem+1,msh%pnods,__FILE__,__LINE__)
    do while(tel(1:5).ne.'eleme')
       read(lunio,'(a)') tel
    end do
    read(lunio,'(a)') tel
    do while(tel(1:5).ne.'end e')
       read(tel,*) ielem,msh%pnods(ielem+1)
       read(lunio,'(a)') tel
    end do
    ! Transform length to header and get mesh%nnode
    msh%pnods(1) = 1
    msh%nnode    = 0
    do ielem = 2, msh%nelem+1
       msh%nnode = max(msh%nnode,msh%pnods(ielem))
       msh%pnods(ielem) = msh%pnods(ielem)+msh%pnods(ielem-1)
    end do

    ! Read elements
    call memalloc(msh%pnods(msh%nelem+1)-1,msh%lnods,__FILE__,__LINE__)
    call memalloc(msh%nelem,msh%legeo,__FILE__,__LINE__)
    call memalloc(msh%nelem,msh%leset,__FILE__,__LINE__)
    call io_rewind(lunio)
    do while(tel(1:5).ne.'eleme')
       read(lunio,'(a)') tel
    end do
    read(lunio,'(a)') tel
    do while(tel(1:5).ne.'end e')
       read(tel,*) ielem,nnode,(msh%lnods(msh%pnods(ielem)-1+inode),inode=1,nnode),msh%leset(ielem),msh%legeo(ielem)
       read(lunio,'(a)') tel
    end do

    ! Read boundary elements' size (pnodb)
    !write(*,*) 'Reading boundaries sizes'
    call msh%given_vefs%create(nboun)
    do while(tel(1:5).ne.'vefs')
       read(lunio,'(a)') tel
    end do
    read(lunio,'(a)') tel
    do while(tel(1:5).ne.'end v')
       read(tel,*) iboun, vbound
       !write(*,*) 'iboun bound', iboun, vbound
       call msh%given_vefs%sum_to_pointer_index(iboun, vbound)
       read(lunio,'(a)') tel
    end do
    ! Transform length to header and get mesh%nnodb
    call msh%given_vefs%calculate_header()
    msh%nnodb    = 0
    do iboun = 1, msh%given_vefs%get_num_pointers()
       msh%nnodb = max(msh%nnodb,msh%given_vefs%get_sublist_size(iboun))
    end do

    ! Read boundary elements
    !write(*,*) 'Reading boundaries'
    call msh%given_vefs%allocate_list_from_pointer()
    call memalloc(msh%given_vefs%get_num_pointers(),msh%lst_vefs_geo,__FILE__,__LINE__)
    call memalloc(msh%given_vefs%get_num_pointers(),msh%lst_vefs_set,__FILE__,__LINE__)
    call io_rewind(lunio)
    do while(tel(1:5).ne.'vefs')
       read(lunio,'(a)') tel
    end do
    read(lunio,'(a)') tel
    do while(tel(1:5).ne.'end v')
       read(tel,*) iboun,nnodb
       !write(*,*) 'iboun nnodb',iboun, nnodb
       allocate(bound_list_aux(msh%given_vefs%get_sublist_size(iboun)))
       read(tel,*) iboun,nnodb, (bound_list_aux(inode),inode=1,nnodb),msh%lst_vefs_set(iboun),msh%lst_vefs_geo(iboun)
       bound_iterator = msh%given_vefs%create_iterator(iboun)
       do inode=1, nnodb
          call bound_iterator%set_current(bound_list_aux(inode))
          call bound_iterator%next()
       enddo
       deallocate(bound_list_aux)
       read(lunio,'(a)') tel
    end do

    ! Reordering (c to z) the nodes of the mesh, if needed
    !if(permute_c2z_) then
    if(msh%order==c_order) then
       msh%order= z_order
       call memalloc(msh%nnode, lnods_aux, __FILE__, __LINE__)
       do ielem = 1,msh%nelem
          nnode = msh%pnods(ielem+1) - msh%pnods(ielem)
          lnods_aux(1:nnode) = msh%lnods(msh%pnods(ielem):msh%pnods(ielem+1)-1)
          if(msh%ndime == 2) then
             if(nnode == 3)  then    ! Linear triangles (2DP1)
                permu => permu_2DP1
             elseif(nnode == 4) then ! Linear quadrilaterals(2DQ1)
                permu => permu_2DQ1
             end if
          elseif(msh%ndime == 3) then
             if(nnode == 4) then     ! Linear tetrahedra (3DP1)
                permu => permu_3DP1
             elseif(nnode == 8) then ! Linear hexahedra (3DQ1)
                permu => permu_3DQ1
             end if
          end if
          do inode = 1, nnode
             msh%lnods(msh%pnods(ielem)+inode-1) = lnods_aux(permu(inode))
          end do
       end do
       call memfree(lnods_aux,__FILE__,__LINE__)
    end if

  end subroutine mesh_read_from_unit

  !=============================================================================
  subroutine mesh_write_file (msh,lunio,title)
    !------------------------------------------------------------------------
    !
    ! This routine writes a mesh in the format defined by GiD fempar problem type.
    !
    !------------------------------------------------------------------------
    implicit none
    integer(ip)  , intent(in)           :: lunio
    class(mesh_t) , intent(in)          :: msh
    character(*) , intent(in), optional :: title

    integer(ip)                         :: ielem, idime, ipoin, inode, iboun, jboun
    integer(ip), allocatable            :: bound_list_aux(:)
    type(list_iterator_t)               :: bound_iterator

    ! Read first line: "MESH dimension  2  order  0  types  1  elements          1  vertices          4  vefs          8
    write(lunio,'(a14,1x,i2, a7,1x,i2, a7,1x,i2, a10,1x,i10, a10,1x,i10, a6,1x,i10)') &
         & 'MESH dimension',msh%ndime,'  order',msh%order,'  types',msh%nelty,'  elements', &
         & msh%nelem,'  vertices',msh%npoin,'  vefs',msh%given_vefs%get_num_pointers()
         
    ! Coordinates
    write(lunio,'(a)')'coordinates'
    assert(allocated(msh%coord))
    do ipoin=1,msh%npoin
       write(lunio,'(i10,3(1x,e16.8e3))') ipoin,(msh%coord(idime,ipoin),idime=1,msh%ndime)
    end do
    write(lunio,'(a)')'end coordinates'

    ! Elements
    write(lunio,'(a)')'elements'
    do ielem=1,msh%nelem
       write(lunio,'(i10,65(1x,i10))') ielem, msh%pnods(ielem+1)-msh%pnods(ielem),&
            &  msh%lnods(msh%pnods(ielem):msh%pnods(ielem+1)-1),msh%leset(ielem),msh%legeo(ielem)
    end do
    write(lunio,'(a)') 'end elements'

    ! Boundary elements
    write(lunio,'(a)')'vefs'
    do iboun=1,msh%given_vefs%get_num_pointers()
       allocate(bound_list_aux(msh%given_vefs%get_sublist_size(iboun)))
       bound_iterator = msh%given_vefs%create_iterator(iboun)
       do jboun=1, msh%given_vefs%get_sublist_size(iboun)
          bound_list_aux(jboun) = bound_iterator%get_current()
          call bound_iterator%next()
       enddo
       write(lunio,'(i10,65(1x,i10))') iboun, bound_iterator%get_size(), &
            &  bound_list_aux ,msh%lst_vefs_set(iboun),msh%lst_vefs_geo(iboun)
       deallocate(bound_list_aux)
    end do
    write(lunio,'(a)') 'end v'

  end subroutine mesh_write_file

  !=============================================================================
  subroutine mesh_write_post_file (msh,lunio,title)
    !------------------------------------------------------------------------
    !
    ! This routine writes a mesh in GiD format (only works for linear elements).
    !
    !------------------------------------------------------------------------
    implicit none
    integer(ip)      , intent(in)           :: lunio
    class(mesh_t)     , intent(in)           :: msh
    character(*)     , intent(in), optional :: title

    integer(ip)                    :: ielem, idime, ipoin, inode, nnode
    character(13)                  :: elemt
    character(len=:), allocatable  :: title_

    integer(ip)     , pointer      :: permu(:)

    permu => permu_id
    if(msh%ndime==2) then
       if(msh%nnode==3) then
          elemt='Triangle' 
          if(msh%order==z_order) permu => permu_2DP1
       else
          elemt='Quadrilateral'
          if(msh%order==z_order) permu => permu_2DQ1
       end if
    else
       if(msh%nnode==4) then 
          elemt='Tetrahedra'
          if(msh%order==z_order) permu => permu_3DP1
       else if(msh%nnode==6) then 
          elemt='Prism'
          if(msh%order==z_order) permu => permu_3DPR
       else if(msh%nnode==8) then 
          elemt='Hexahedra'
          if(msh%order==z_order) permu => permu_3DQ1
       end if
    end if

    ! Header
    title_ = 'TITLE'
    if(present(title)) title_=title
    write(lunio,1) adjustl(trim(title_)),msh%ndime,adjustl(trim(elemt)),msh%nnode

    ! Coordinates
    write(lunio,2)'coordinates'
    if (allocated(msh%coord)) then
       do ipoin=1,msh%npoin
          write(lunio,3) ipoin,(msh%coord(idime,ipoin),idime=1,msh%ndime)
       end do
    end if
    write(lunio,2)'end coordinates'

    ! Connectivity
    if(msh%nelty==1) then
       write(lunio,2)'elements'
       do ielem=1,msh%nelem
          nnode = msh%pnods(ielem+1)-msh%pnods(ielem)
          write(lunio,4) ielem, (msh%lnods(msh%pnods(ielem)-1+permu(inode)),inode=1,nnode),1
       end do
       write(lunio,2) 'end elements'
    else
       ! Write hexahedra or prismas (3D) or quads(2)
       write(lunio,2)'elements'
       do ielem=1,msh%nelem
          nnode = msh%pnods(ielem+1)-msh%pnods(ielem)
          if(nnode == msh%nnode) &
               write(lunio,4) ielem, (msh%lnods(msh%pnods(ielem)-1+permu(inode)),inode=1,nnode),1
       end do
       write(lunio,2) 'end elements'
       ! Now write tetrahedra (3D) or triangles (2D)
       if(msh%ndime==2) then
          nnode = 3
          elemt = 'Triangle' 
          if(msh%order==z_order) permu => permu_2DP1
       else if(msh%ndime==3) then
          nnode = 4
          elemt='Tetrahedra'
          if(msh%order==z_order) permu => permu_3DP1
       end if
       write(lunio,1) adjustl(trim(title_)),msh%ndime,adjustl(trim(elemt)),nnode
       write(lunio,2)'coordinates'
       write(lunio,2)'end coordinates'
       write(lunio,2)'elements'
       do ielem=1,msh%nelem
          if(msh%pnods(ielem+1)-msh%pnods(ielem) == nnode) &
               write(lunio,4) ielem, (msh%lnods(msh%pnods(ielem)-1+permu(inode)),inode=1,nnode),1
       end do
       write(lunio,2) 'end elements'
       ! Eventually write prismas (3D)
       if(msh%ndime==3.and.msh%nnode==8) then
          nnode = 4
          elemt='Prism'
          if(msh%order==z_order) permu => permu_3DPR
          write(lunio,1) adjustl(trim(title_)),msh%ndime,adjustl(trim(elemt)),nnode
          write(lunio,2)'coordinates'
          write(lunio,2)'end coordinates'
          write(lunio,2)'elements'
          do ielem=1,msh%nelem
             if(msh%pnods(ielem+1)-msh%pnods(ielem) == nnode) &
                  write(lunio,4) ielem, (msh%lnods(msh%pnods(ielem)-1+permu(inode)),inode=1,nnode),1
          end do
          write(lunio,2) 'end elements'
       end if
    end if

1   format('MESH ',a,' dimension ',i1,' Elemtype ',a,' Nnode ',i2)
2   format(a)
3   format(i10, 3(1x,e16.8e3))
4   format(i10,65(1x,i10))
5   format('BOUNDARY ',a,' Nnodb ',i2)
6   format(i6,10(1x,i6))

  end subroutine mesh_write_post_file

  !=============================================================================
  subroutine mesh_compose_name ( prefix, name ) 
    implicit none
    character(len=*)             , intent(in)    :: prefix 
    character(len=:), allocatable, intent(inout) :: name
    name = trim(prefix) // '.mesh'
  end subroutine mesh_compose_name


  !=============================================================================
   subroutine check_and_get_path_and_prefix_from_parameterlist( parameter_list, dir_path, prefix ) 
     type(ParameterList_t),         intent(in)    :: parameter_list
     character(len=:), allocatable, intent(inout) :: dir_path
     character(len=:), allocatable, intent(inout) :: prefix
     ! Locals
     integer(ip)                                  :: error

     ! Mandatory parameters
     assert(parameter_list%isAssignable(dir_path_key, 'string'))
     error = parameter_list%GetAsString(key = dir_path_key, string = dir_path)
     assert(error==0)

     assert(parameter_list%isAssignable(prefix_key, 'string'))
     error = parameter_list%GetAsString(key = prefix_key, string = prefix)
     assert(error==0)
  end subroutine check_and_get_path_and_prefix_from_parameterlist

  !=============================================================================
  subroutine mesh_compose_post_name ( prefix, name ) 
    implicit none
    character(len=*)             , intent(in)    :: prefix 
    character(len=:), allocatable, intent(inout) :: name
    name = trim(prefix) // '.post.msh'
  end subroutine mesh_compose_post_name

  !=============================================================================
  subroutine mesh_write_files ( parameter_list, lmesh )   ! dir_path, prefix, nparts, lmesh )
     implicit none
     ! Parameters 
     type(ParameterList_t), intent(in) :: parameter_list
     type(mesh_t)         , intent(in) :: lmesh (:)

     ! Locals
     integer(ip)          :: nparts
     character(len=:), allocatable  :: dir_path
     character(len=:), allocatable  :: prefix
     character(len=:), allocatable  :: name, rename
     integer(ip)                    :: lunio
     integer(ip)                    :: i

     nparts = size(lmesh)

     ! Mandatory parameters
     call check_and_get_path_and_prefix_from_parameterlist(parameter_list, dir_path, prefix)

     call mesh_compose_name ( prefix, name )

     do i=nparts, 1, -1  
        rename=name
        call numbered_filename_compose(i,nparts,rename)
        lunio = io_open( trim(dir_path) // '/' // trim(rename), 'write' ); check(lunio>0)
        call mesh_write_file(lmesh(i),lunio)
        call io_close(lunio)
     end do
     
     ! name, and rename should be automatically deallocated by the compiler when they
     ! go out of scope. Should we deallocate them explicitly for safety reasons?
   end subroutine mesh_write_files

  !=============================================================================
  subroutine mesh_write_files_for_postprocess ( parameter_list, lmesh ) ! dir_path, prefix, nparts, lmesh )
     implicit none
     ! Parameters 
     type(ParameterList_t), intent(in) :: parameter_list
     type(mesh_t)         , intent(in) :: lmesh (:)

     ! Locals
     integer(ip)                     :: nparts
     character(len=:), allocatable   :: dir_path
     character(len=:), allocatable   :: prefix
     character(len=:), allocatable   :: name, rename
     integer(ip)                     :: lunio
     integer(ip)                     :: i

     nparts = size(lmesh)

     ! Mandatory parameters
     call check_and_get_path_and_prefix_from_parameterlist(parameter_list, dir_path, prefix)

     do i=nparts, 1, -1  
        name=prefix
        call numbered_filename_compose(i,nparts,name)
        call mesh_compose_post_name (name, rename)
        lunio = io_open( trim(dir_path) // '/' // trim(rename), 'write' ); check(lunio>0)
        call mesh_write_post_file(lmesh(i),lunio)
        call io_close(lunio)
     end do
     
   end subroutine mesh_write_files_for_postprocess


  !=============================================================================
  subroutine mesh_distribution_write_for_postprocess ( parameter_list, gmesh, parts )
    implicit none
    ! Parameters
    type(ParameterList_t)    , intent(in) :: parameter_list
    type(mesh_t)             , intent(in) :: gmesh
    type(mesh_distribution_t), intent(in) :: parts(:)

    ! Locals
    integer(ip)                     :: nparts
    character(len=:), allocatable   :: dir_path
    character(len=:), allocatable   :: prefix
    character(len=:), allocatable   :: name, rename
    integer(ip)                     :: lunio
    integer(ip)                     :: i,j
    integer(ip),      allocatable   :: ldome(:)
    type(post_file_t)               :: lupos

    nparts = size(parts)

     ! Mandatory parameters
     call check_and_get_path_and_prefix_from_parameterlist(parameter_list, dir_path, prefix)


    ! Output domain partition to GiD file
    call memalloc (gmesh%nelem, ldome, __FILE__,__LINE__)
    do i=1, nparts
       do j=1, parts(i)%num_local_cells
          ldome(parts(i)%l2g_cells(j)) = i
       end do
    end do
    name = trim(dir_path)// '/' // trim(prefix) // '.post.res'
    call postpro_open_file(1,name,lupos)
    call postpro_gp_init(lupos,1,gmesh%nnode,gmesh%ndime)
    call postpro_gp(lupos,gmesh%ndime,gmesh%nnode,ldome,'EDOMS',1,1.0)
    call postpro_close_file(lupos)
    call memfree (ldome,__FILE__,__LINE__)
    
  end subroutine mesh_distribution_write_for_postprocess

  !=============================================================================
   subroutine mesh_read_files ( parameter_list, nparts, lmesh ) !    dir_path, prefix, nparts, lmesh )
     implicit none
     ! Parameters 
     type(ParameterList_t), intent(in)  :: parameter_list
     integer(ip)          , intent(in)  :: nparts
     type(mesh_t)         , intent(out) :: lmesh (nparts)

     ! Locals
     character(len=:), allocatable   :: dir_path
     character(len=:), allocatable   :: prefix
     character(len=:), allocatable   :: name, rename
     integer(ip)                     :: lunio
     integer(ip)                     :: i

     ! Mandatory parameters
     call check_and_get_path_and_prefix_from_parameterlist(parameter_list, dir_path, prefix)
    
     call mesh_compose_name ( prefix, name )
     do i=nparts, 1, -1  
        rename=name
        call numbered_filename_compose(i,nparts,rename)
        lunio = io_open( trim(dir_path) // '/' // trim(rename), 'read' ); check(lunio>0)
        call lmesh(i)%read(lunio)
        call io_close(lunio)
     end do
     
   end subroutine mesh_read_files

  !=============================================================================
   subroutine mesh_read_from_file (f_mesh, parameter_list)   ! ,  dir_path, prefix ) !, permute_c2z
     implicit none 
     class(mesh_t)        , intent(out) :: f_mesh
     type(ParameterList_t), intent(in)    :: parameter_list
     ! Locals
     character(len=:), allocatable   :: dir_path
     character(len=:), allocatable   :: prefix
     character(len=:), allocatable   :: name
     integer(ip)                     :: lunio

     ! Mandatory parameters
     call check_and_get_path_and_prefix_from_parameterlist(parameter_list, dir_path, prefix)

     ! Read mesh
     call mesh_compose_name ( prefix, name )
     lunio = io_open( trim(dir_path)//'/'//trim(name), 'read', status='old' ); check(lunio>0)
     call f_mesh%read(lunio)  !, permute_c2z
     call io_close(lunio)

   end subroutine mesh_read_from_file

   !=============================================================================
   subroutine mesh_write_file_for_postprocess ( f_mesh, parameter_list)   !  , dir_path, prefix)
     implicit none 
     ! Parameters
     !character (*)                , intent(in)  :: dir_path
     !character (*)                , intent(in)  :: prefix
     class(mesh_t)        , intent(in) :: f_mesh
     type(ParameterList_t), intent(in) :: parameter_list

     ! Locals
     character(len=:), allocatable   :: dir_path
     character(len=:), allocatable   :: prefix
     character(len=:), allocatable   :: name
     integer(ip)                     :: lunio

     ! Mandatory parameters
     call check_and_get_path_and_prefix_from_parameterlist(parameter_list, dir_path, prefix)

     call mesh_compose_post_name ( prefix, name )
     lunio = io_open( trim(dir_path)//'/'//trim(name), 'write' ); check(lunio>0)
     call mesh_write_post_file(f_mesh,lunio)
     call io_close(lunio)

   end subroutine mesh_write_file_for_postprocess

  !subroutine create_mesh_distribution( femesh, prt_pars, distr, lmesh)
  subroutine create_mesh_distribution( femesh, parameters, distr, env, lmesh)
    !-----------------------------------------------------------------------
    ! 
    !-----------------------------------------------------------------------
    implicit none

    ! Parameters
    class(mesh_t)             , intent(inout)      :: femesh
    type(ParameterList_t)     , intent(in)         :: parameters
    type(mesh_distribution_t) , allocatable, intent(out) :: distr(:) ! Mesh distribution instances
    type(environment_t)   , allocatable, intent(out) :: env(:) ! Environments
    type(mesh_t)              , allocatable, intent(out) :: lmesh(:) ! Local mesh instances

    ! Local variables
    type(mesh_distribution_params_t) :: prt_pars
    type(list_t)                     :: fe_graph         ! Dual graph (to be partitioned)
    type(list_t)                     :: parts_graph      ! Parts graph (to be partitioned)
    integer(ip), allocatable, target :: ldome(:)         ! Part of each element
    type(i1p_t), allocatable         :: ldomp(:)         ! Part of each part (recursively)
    integer(ip), allocatable         :: parts_mapping(:) ! Part of each element
    integer(ip) :: istat, ilevel, jlevel, ipart, itask, num_tasks

    ! Get parameters from fpl
    call prt_pars%get_parameters_from_fpl(parameters)

    ! Generate dual mesh (i.e., list of elements around points)
    call femesh%to_dual()

    ! Create dual (i.e. list of elements around elements)
    call create_dual_graph(femesh,fe_graph)
   
    ! Partition dual graph to assign a domain to each element (in ldome)
    call memalloc (femesh%nelem, ldome, __FILE__,__LINE__)   
    
    call graph_pt_renumbering(prt_pars,fe_graph,ldome)

    allocate(ldomp(prt_pars%num_levels), stat=istat); check(istat==0);
    ldomp(1)%p => ldome
    do ilevel=1,prt_pars%num_levels-1
       call memallocp(prt_pars%num_parts_x_level(ilevel),ldomp(ilevel+1)%p, __FILE__,__LINE__)
       if(prt_pars%num_parts_x_level(ilevel+1)>1) then  ! Typically in the last level there is onle one part
          call build_parts_graph (prt_pars%num_parts_x_level(ilevel), ldomp(ilevel)%p, fe_graph, parts_graph)
          call fe_graph%free()
          fe_graph = parts_graph
          prt_pars%nparts = prt_pars%num_parts_x_level(ilevel+1)
          call graph_pt_renumbering(prt_pars,parts_graph,ldomp(ilevel+1)%p)
       else
          ldomp(ilevel+1)%p = 1
       end if
       call parts_graph%free()
    end do
    prt_pars%nparts = prt_pars%num_parts_x_level(1)
    call fe_graph%free()

    num_tasks = 0
    do ilevel=1,prt_pars%num_levels
       num_tasks = num_tasks + prt_pars%num_parts_x_level(ilevel)
    end do
    allocate(env(num_tasks), stat=istat); check(istat==0) 
    itask = 0
    call memalloc(prt_pars%num_levels,parts_mapping,__FILE__,__LINE__)
    do ilevel=1,prt_pars%num_levels
       do ipart = 1, prt_pars%num_parts_x_level(ilevel)
          itask = itask+1
          do jlevel = 1 , ilevel - 1 
             parts_mapping(jlevel) = 0
          end do
          parts_mapping(ilevel) = ipart
          do jlevel = ilevel+1 , prt_pars%num_levels
             parts_mapping(jlevel) = ldomp(jlevel)%p( parts_mapping(jlevel-1) )
          end do
          call env(itask)%assign_parts_to_tasks(prt_pars%num_levels,prt_pars%num_parts_x_level,parts_mapping)
       end do
    end do
    call memfree(parts_mapping,__FILE__,__LINE__)

    prt_pars%nparts = prt_pars%num_parts_x_level(1)
    do ilevel=1,prt_pars%num_levels-1
       call memfreep(ldomp(ilevel+1)%p, __FILE__,__LINE__)
    end do
    deallocate(ldomp, stat=istat); check(istat==0);

    allocate(distr(prt_pars%nparts), stat=istat); check(istat==0)
    allocate(lmesh(prt_pars%nparts), stat=istat); check(istat==0) 

    call build_maps(prt_pars%nparts, ldome, femesh, distr)

    ! Build local meshes and their duals and generate partition adjacency
    do ipart=1,prt_pars%nparts
       ! Generate Local mesh
       call mesh_g2l(distr(ipart)%num_local_vertices,  &
                     distr(ipart)%l2g_vertices,        &
                     distr(ipart)%num_local_cells,     &
                     distr(ipart)%l2g_cells,           &
                     femesh,                           &
                     lmesh(ipart))
       call build_adjacency_new (femesh, ldome,             &
            &                    ipart,                     &
            &                    lmesh(ipart),              &
            &                    distr(ipart)%l2g_vertices, &
            &                    distr(ipart)%l2g_cells,    &
            &                    distr(ipart)%nebou,        &
            &                    distr(ipart)%nnbou,        &
            &                    distr(ipart)%lebou,        &
            &                    distr(ipart)%lnbou,        &
            &                    distr(ipart)%pextn,        &
            &                    distr(ipart)%lextn,        &
            &                    distr(ipart)%lextp )
    end do
    call memfree(ldome,__FILE__,__LINE__)

    call prt_pars%free()

  end subroutine create_mesh_distribution

  !================================================================================================
  subroutine create_dual_graph(mesh,graph)
    ! Parameters
    type(mesh_t) , intent(in)  :: mesh
    type(list_t),  intent(out) :: graph
    ! Locals
    integer(ip), allocatable :: lelem(:)
    integer(ip), allocatable :: keadj(:)

    call memalloc(           mesh%nelem,lelem,__FILE__,__LINE__)
    call memalloc(mesh%nelpo*mesh%nnode,keadj,__FILE__,__LINE__)
    lelem=0
    !call graph%create(mesh%nelem)

    call count_elemental_graph(mesh%ndime,mesh%npoin,mesh%nelem, &
         &                     mesh%pnods,mesh%lnods,mesh%nnode,mesh%nelpo, &
         &                     mesh%pelpo,mesh%lelpo,lelem,keadj,graph)

    call graph%allocate_list_from_pointer()

    call list_elemental_graph(mesh%ndime,mesh%npoin,mesh%nelem, &
         &                    mesh%pnods,mesh%lnods,mesh%nnode,mesh%nelpo, &
         &                    mesh%pelpo,mesh%lelpo,lelem,keadj,graph)

    call memfree(lelem,__FILE__,__LINE__)
    call memfree(keadj,__FILE__,__LINE__)

  end subroutine create_dual_graph

  !-----------------------------------------------------------------------
  subroutine count_elemental_graph(ncomm,npoin,nelem,pnods,lnods,nnode, &
       &                           nelpo,pelpo,lelpo,lelem,keadj,graph)
    implicit none
    integer(ip),  intent(in)    :: ncomm,npoin,nelem
    integer(ip),  intent(in)    :: pnods(nelem+1),lnods(pnods(nelem+1))
    integer(ip),  intent(in)    :: nnode             ! Number of nodes of each element (max.)
    integer(ip),  intent(in)    :: nelpo             ! Number of elements around points (max.)
    integer(ip),  intent(in)    :: pelpo(npoin+1)    ! Number of elements around points
    integer(ip),  intent(in)    :: lelpo(pelpo(npoin+1))    ! List of elements around points
    type(list_t), intent(inout) :: graph                    ! Number of edges on each element (list_t)
    integer(ip),  intent(out)   :: lelem(nelem)             ! Auxiliar array
    integer(ip),  intent(out)   :: keadj(nelpo*nnode)       ! Auxiliar array
    integer(ip)                 :: ielem,jelem,inode,knode  ! Indices
    integer(ip)                 :: ipoin,ielpo,index        ! Indices
    integer(ip)                 :: neadj,ielel,jelel,nelel  ! Indices

    lelem=0
    knode=nnode
    call graph%create(nelem)
    do ielem=1,nelem
       !call graph%sum_to_pointer_index(ielem-1, neadj)
       ! Loop over nodes and their surrounding elements and count
       ! how many times they are repeated as neighbors of ielem
       nelel=0
       keadj=0
       index=pnods(ielem)-1
       knode=pnods(ielem+1)-pnods(ielem)
       do inode=1,knode
          ipoin=lnods(index+inode)
          do ielpo=pelpo(ipoin),pelpo(ipoin+1)-1
             jelem=lelpo(ielpo)
             if(lelem(jelem)==0) then
                nelel=nelel+1
                keadj(nelel)=jelem
             end if
             lelem(jelem)=lelem(jelem)+1
          end do
       end do

       ! Now we loop over the elements around ielem and define neighbors
       ! as those sharing ncomm nodes. The smaller this number is the
       ! higher the connectivity of elemental graph is. Note that prisms,
       ! for example, could share 3 or 4 nodes depending on the face, so
       ! ndime (the number of space dimensions) is a good choice.
       jelel=0
       do ielel=1,nelel
          jelem=keadj(ielel)
          if(lelem(jelem)>=ncomm) jelel=jelel+1
       end do
       call graph%sum_to_pointer_index(ielem, jelel)

       ! Reset lelem
       do ielel=1,nelel
          jelem=keadj(ielel)
          lelem(jelem)=0
       end do
    end do
    
    call graph%calculate_header()

  end subroutine count_elemental_graph
  !-----------------------------------------------------------------------
  subroutine list_elemental_graph(ncomm,npoin,nelem,pnods,lnods,nnode, &
       &                          nelpo,pelpo,lelpo,lelem,keadj,graph)
    implicit none
    integer(ip),  intent(in)    :: ncomm,npoin,nelem
    integer(ip),  intent(in)    :: pnods(nelem+1),lnods(pnods(nelem+1))
    integer(ip),  intent(in)    :: nnode             ! Number of nodes of each element (max.)
    integer(ip),  intent(in)    :: nelpo             ! Number of elements around points (max.)
    integer(ip),  intent(in)    :: pelpo(npoin+1)    ! Number of elements around points
    integer(ip),  intent(in)    :: lelpo(pelpo(npoin+1))    ! List of elements around points
    type(list_t), intent(inout) :: graph                    ! List of edges on each element (list_t)
    integer(ip),  intent(out)   :: lelem(nelem)             ! Auxiliar array
    integer(ip),  intent(out)   :: keadj(nelpo*nnode)       ! Auxiliar array
    integer(ip)                 :: ielem,jelem,inode,knode  ! Indices
    integer(ip)                 :: ipoin,ielpo,index        ! Indices
    integer(ip)                 :: neadj,ielel,jelel,nelel  ! Indices
    type(list_iterator_t)       :: graph_iterator

    lelem=0
    knode=nnode
    do ielem=1,nelem
       ! Loop over nodes and their surrounding elements and count
       ! how many times they are repeated as neighbors of ielem
       nelel=0
       keadj=0
       index=pnods(ielem)-1
       knode=pnods(ielem+1)-pnods(ielem)
       do inode=1,knode
          ipoin=lnods(index+inode)
          do ielpo=pelpo(ipoin),pelpo(ipoin+1)-1
             jelem=lelpo(ielpo)
             if(lelem(jelem)==0) then
                nelel=nelel+1
                keadj(nelel)=jelem
             end if
             lelem(jelem)=lelem(jelem)+1
          end do
       end do

       ! Now we loop over the elements around ielem and define neighbors
       graph_iterator = graph%create_iterator(ielem)
       do ielel=1,nelel
          jelem=keadj(ielel)
          if(lelem(jelem)>=ncomm) then
             call graph_iterator%set_current(jelem)
             call graph_iterator%next()
          end if
       end do

       ! Reset lelem
       do ielel=1,nelel
          jelem=keadj(ielel)
          lelem(jelem)=0
       end do
    end do

  end subroutine list_elemental_graph

  !================================================================================================
  subroutine build_adjacency_new ( gmesh, ldome, my_part, lmesh, l2gn, l2ge, &
       &                           nebou, nnbou, lebou, lnbou, pextn, lextn, lextp)
    implicit none
    integer(ip)   , intent(in)  :: my_part
    type(mesh_t)  , intent(in)  :: gmesh,lmesh
    integer(ip)   , intent(in)  :: ldome(gmesh%nelem)
    integer(igp)  , intent(in)  :: l2gn(lmesh%npoin)
    integer(igp)  , intent(in)  :: l2ge(lmesh%nelem)
    integer(ip)   , intent(out) :: nebou
    integer(ip)   , intent(out) :: nnbou
    integer(ip)   , allocatable, intent(out) ::  lebou(:)    ! List of boundary elements
    integer(ip)   , allocatable, intent(out) ::  lnbou(:)    ! List of boundary nodes
    integer(ip)   , allocatable, intent(out) ::  pextn(:)    ! Pointers to the lextn
    integer(igp)  , allocatable, intent(out) ::  lextn(:)    ! List of (GID of) external neighbors
    integer(ip)   , allocatable, intent(out) ::  lextp(:)    ! List of parts of external neighbors

    integer(ip) :: lelem, ielem, jelem, pelem, pnode, inode1, inode2, ipoin, lpoin, jpart, iebou, istat, touch
    integer(ip) :: nextn, nexte, nepos
    integer(ip), allocatable :: local_visited(:)
    type(hash_table_ip_ip_t)   :: external_visited

    if(my_part==0) then
       write(*,*)  'Parts:'
       do ielem=1,gmesh%nelem
          write(*,*)  ielem, ldome(ielem)
       end do
       write(*,*)  'Global mesh:',gmesh%npoin,gmesh%nelem
       do ielem=1,gmesh%nelem
          write(*,*)  ielem, gmesh%lnods(gmesh%pnods(ielem):gmesh%pnods(ielem+1)-1)
       end do
       write(*,*)  'Global dual mesh:',gmesh%nelpo
       do ipoin=1,gmesh%npoin
          write(*,*)  ipoin, gmesh%lelpo(gmesh%pelpo(ipoin):gmesh%pelpo(ipoin+1)-1)
       end do
       write(*,*)  'Local mesh:',lmesh%npoin,lmesh%nelem
       do lelem=1,lmesh%nelem
          write(*,*)  lelem, l2ge(lelem),lmesh%lnods(lmesh%pnods(lelem):lmesh%pnods(lelem+1)-1)
       end do
       write(*,*)  'Local2Global (nodes)'
       do lpoin=1,lmesh%npoin
          write(*,*)  lpoin, l2gn(lpoin)
       end do
    end if

    ! Count boundary nodes
    nnbou = 0 
    do lpoin=1, lmesh%npoin
       ipoin = l2gn(lpoin)
       do pelem = gmesh%pelpo(ipoin), gmesh%pelpo(ipoin+1) - 1
          ielem = gmesh%lelpo(pelem)
          jpart = ldome(ielem)
          if ( jpart /= my_part ) then 
             nnbou = nnbou +1
             exit
          end if
       end do
    end do

    ! List boundary nodes
    call memalloc ( nnbou, lnbou, __FILE__, __LINE__ ) 
    nnbou = 0
    do lpoin=1, lmesh%npoin
       ipoin = l2gn(lpoin)
       do pelem = gmesh%pelpo(ipoin), gmesh%pelpo(ipoin+1) - 1
          ielem = gmesh%lelpo(pelem)
          jpart = ldome(ielem)
          if ( jpart /= my_part ) then 
             lnbou(nnbou+1) = ipoin
             nnbou = nnbou +1
             exit
          end if
       end do
    end do

    ! As the dual mesh is given with global IDs we need a hash table to do the touch.
    call memalloc(lmesh%nelem, local_visited,__FILE__,__LINE__)
    local_visited = 0
    call external_visited%init(20)

    ! 1) Count boundary elements and external edges
    touch = 1
    nebou = 0 ! number of boundary elements
    nextn = 0 ! number of external edges
    do lelem = 1, lmesh%nelem
       nexte = 0   ! number of external neighbours of this element
       ielem = l2ge(lelem)
       inode1 = gmesh%pnods(ielem)
       inode2 = gmesh%pnods(ielem+1)-1
       do pnode = inode1, inode2
          ipoin = gmesh%lnods(pnode)
          do pelem = gmesh%pelpo(ipoin), gmesh%pelpo(ipoin+1) - 1
             jelem = gmesh%lelpo(pelem)
             if(jelem/=ielem) then
                jpart = ldome(jelem)
                if(jpart/=my_part) then                                   ! This is an external element
                   if(local_visited(lelem) == 0 ) nebou = nebou +1        ! Count it
                   !call external_visited%put(key=jelem,val=1, stat=istat) ! Touch jelem as external neighbor of lelem.
                   call external_visited%put(key=jelem,val=touch, stat=istat) ! Touch jelem as external neighbor of lelem.
                   if(istat==now_stored) nexte = nexte + 1                ! Count external neighbours of lelem
                   local_visited(lelem) = nexte                           ! Touch lelem also storing the number
                end if                                                    ! of external neighbours it has
             end if
          end do
       end do
       nextn = nextn + nexte
       ! Clean hash table
       if(local_visited(lelem) /= 0 ) then 
          do pnode = inode1, inode2
             ipoin = gmesh%lnods(pnode)
             do pelem = gmesh%pelpo(ipoin), gmesh%pelpo(ipoin+1) - 1
                jelem = gmesh%lelpo(pelem)
                if(jelem/=ielem) then
                   jpart = ldome(jelem)
                   if(jpart/=my_part) then
                      call external_visited%del(key=jelem, stat=istat)
                   end if
                end if
             end do
          end do
       end if
       call external_visited%print
    end do

    if(my_part==0) then
       write(*,*)  'Visited (boundary) elements:'
       do lelem=1,lmesh%nelem
          write(*,*)  local_visited(lelem)
       end do
    end if

    ! 2) Allocate arrays and store list and pointers to externals
    call memalloc(nebou  , lebou,__FILE__,__LINE__)
    call memalloc(nebou+1, pextn,__FILE__,__LINE__)
    call memalloc(nextn  , lextn,__FILE__,__LINE__)
    call memalloc(nextn  , lextp,__FILE__,__LINE__)

    iebou = 0
    pextn(1) = 1
    do lelem = 1, lmesh%nelem
       if(local_visited(lelem) /= 0 ) then
          iebou = iebou +1
          lebou(iebou) = lelem
          pextn(iebou+1) = local_visited(lelem) + pextn(iebou)
       end if
    end do

    if(my_part==0) then
       write(*,*)  'Boundary elements:'
       do iebou=1,nebou
          write(*,*)  lebou(iebou)
       end do
    end if

    ! 3) Store boundary elements and external edges
    do iebou = 1, nebou
       lelem = lebou(iebou)
       ielem = l2ge(lelem)
       nexte = 0   ! number of external neighbours of this element
       inode1 = gmesh%pnods(ielem)
       inode2 = gmesh%pnods(ielem+1)-1
       do pnode = inode1, inode2
          ipoin = gmesh%lnods(pnode)
          do pelem = gmesh%pelpo(ipoin), gmesh%pelpo(ipoin+1) - 1
             jelem = gmesh%lelpo(pelem)
             if(jelem/=ielem) then
                jpart = ldome(jelem)
                if(jpart/=my_part) then                                   ! This is an external element
                   call external_visited%put(key=jelem,val=touch, stat=istat) ! Touch jelem as external neighbor of lelem.
                   if(istat==now_stored) then
                      lextn(pextn(iebou)+nexte) = jelem
                      lextp(pextn(iebou)+nexte) = jpart
                      nexte = nexte + 1
                   end if
                end if
             end if
          end do
       end do
       ! Clean hash table
       do pnode = inode1, inode2
          ipoin = gmesh%lnods(pnode)
          do pelem = gmesh%pelpo(ipoin), gmesh%pelpo(ipoin+1) - 1
             jelem = gmesh%lelpo(pelem)
             if(jelem/=ielem) then
                jpart = ldome(jelem)
                if(jpart/=my_part) then                                   ! This is an external element
                   call external_visited%del(key=jelem, stat=istat)
                end if
             end if
          end do
       end do
    end do

    call external_visited%free
    call memfree(local_visited,__FILE__,__LINE__)

  end subroutine build_adjacency_new

  !================================================================================================
  subroutine build_maps( nparts, ldome, femesh, distr )
    ! This routine builds (node and element) partition maps without using the objects
    ! and (unlike parts_sizes, parts_maps, etc.) does not generate a new global numbering.
    implicit none
    integer(ip)                , intent(in)    :: nparts
    type(mesh_t)               , intent(in)    :: femesh
    integer(ip)                , intent(in)    :: ldome(femesh%nelem)
    type(mesh_distribution_t), intent(inout) :: distr(nparts)

    integer(ip)   , allocatable  :: nedom(:) ! Number of points per part (here is not header!)
    integer(ip)   , allocatable  :: npdom(:) ! Number of elements per part (here is not header!)
    integer(ip)   , allocatable  :: work1(:)
    integer(ip)   , allocatable  :: work2(:)
    integer(ip) :: ielem, ipart, inode, iboun

    ! Number of elements of each part and global to local element map (is one to one)
    call memalloc (nparts, nedom,__FILE__,__LINE__)
    nedom=0
    do ielem=1,femesh%nelem
       ipart = ldome(ielem)
       nedom(ipart)=nedom(ipart)+1
    end do
    ! Allocate local to global maps
    do ipart=1,nparts
       distr(ipart)%num_local_cells  = nedom(ipart)
       distr(ipart)%num_global_cells = int(femesh%nelem,igp)
       call memalloc(distr(ipart)%num_local_cells, distr(ipart)%l2g_cells, __FILE__, __LINE__)
    end do
    nedom = 0
    do ielem=1,femesh%nelem
       ipart = ldome(ielem)
       nedom(ipart)=nedom(ipart)+1
       distr(ipart)%l2g_cells(nedom(ipart)) = ielem
    end do

    call memfree ( nedom,__FILE__,__LINE__)

    ! Number of nodes of each part and global to local node map (is NOT one to one)
    call memalloc ( nparts, npdom,__FILE__,__LINE__)
    call memalloc ( femesh%npoin, work1,__FILE__,__LINE__)
    call memalloc ( femesh%npoin, work2,__FILE__,__LINE__)
    npdom=0
    do ipart = 1, nparts
       work1 = 0
       work2 = 0
       do ielem=1,femesh%nelem
          if(ldome(ielem)==ipart) then
             do inode = femesh%pnods(ielem), femesh%pnods(ielem+1) - 1 
                if(work1(femesh%lnods(inode)) == 0 ) then
                   npdom(ipart) = npdom(ipart)+1
                   work1(femesh%lnods(inode)) = 1
                   work2(npdom(ipart)) = femesh%lnods(inode)
                end if
             end do
          end if
       end do
       distr(ipart)%num_local_vertices  = npdom(ipart)
       distr(ipart)%num_global_vertices = int(femesh%npoin,igp)
       call memalloc(distr(ipart)%num_local_vertices, distr(ipart)%l2g_vertices, __FILE__, __LINE__)
       distr(ipart)%l2g_vertices = work2(1:npdom(ipart))
    end do
    call memfree ( work1,__FILE__,__LINE__)
    call memfree ( work2,__FILE__,__LINE__)
    call memfree ( npdom,__FILE__,__LINE__)
  end subroutine build_maps

  ! Inspired on http://en.wikipedia.org/wiki/Breadth-first_search.
  ! Given a mesh (m) and its dual graph (g), it computes the list 
  ! of nodes (lconn) of each connected component in m. Can be very
  ! useful as a tool to determine whether the mesh partitioning process
  ! leads to disconnected subdomains or not.
  subroutine mesh_graph_compute_connected_components (m, g, lconn)
    implicit none

    ! Parameters
    type(mesh_t) , intent(in)   :: m   
    type(list_t),  intent(in)   :: g
    type(list_t),  intent(out)  :: lconn

    ! Locals
    integer(ip), allocatable :: auxv(:), auxe(:), e(:)
    integer(ip), allocatable :: emarked(:), vmarked(:)
    integer(ip), allocatable :: q(:)
    integer(ip)              :: head, tail, i, esize, vsize, current, & 
         j, l, k, inods1d, inods2d, p_ipoin, ipoin, graph_num_rows, lconnn
    type(list_iterator_t)    :: graph_column_iterator
    type(list_iterator_t)    :: lconn_iterator

    graph_num_rows = g%get_num_pointers()
    call memalloc ( graph_num_rows   , auxe     , __FILE__,__LINE__)
    call memalloc ( graph_num_rows   , auxv     , __FILE__,__LINE__)
    call memalloc ( graph_num_rows   , q        , __FILE__,__LINE__)
    call memalloc ( graph_num_rows   , emarked  , __FILE__,__LINE__)
    call memalloc ( m%npoin          , vmarked  , __FILE__,__LINE__)
    call memalloc ( graph_num_rows   ,  e       , __FILE__,__LINE__)

    lconnn  = 0
    emarked  = 0
    current  = 1 

    do i=1, graph_num_rows
       if (emarked(i) == 0) then
          ! New connected component
          lconnn = lconnn +1
          esize   = 0
          vsize   = 0
          vmarked = 0 
!!$1  procedure BFS(G,v):
!!$2      create a queue Q
          head=1
          tail=1
!!$3      enqueue v onto Q
          q(tail)=i
          tail=tail+1
!!$4      mark v
          emarked(i)=1
          e(current)=i
          esize  = esize + 1
          current = current + 1  

!!$5      while Q is not empty:
          do while (head/=tail)
!!$6         t ← Q.dequeue()
             j=q(head)
             head = head + 1

             ! Traverse the nodes of the element number j
             inods1d = m%pnods(j)
             inods2d = m%pnods(j+1)-1

             do p_ipoin = inods1d, inods2d
                ipoin = m%lnods(p_ipoin)
                if (vmarked(ipoin)==0) then
                   vmarked(ipoin)=1
                   vsize = vsize+1
                end if
             end do

!!$9         for all edges e in G.adjacentEdges(t) do
             graph_column_iterator = g%create_iterator(j)
             do while(.not. graph_column_iterator%is_upper_bound())
!!$12           u ← G.adjacentVertex(t,e)
                l=graph_column_iterator%get_current()
!!$13           if u is not emarked:
                if (emarked(l)==0) then
!!$14              mark u
                   emarked(l)=1
                   e(current)=l
                   esize  = esize + 1
                   current = current + 1  

!!$15              enqueue u onto Q
                   q(tail)=l
                   tail=tail+1
                end if
                call graph_column_iterator%next()
             end do
          end do
          auxe(lconnn) = esize
          auxv(lconnn) = vsize
       end if
    end do

    call lconn%create(lconnn)

    do i=1, lconnn
       call lconn%sum_to_pointer_index(i, auxv(i))
    end do

    call memfree( auxv   ,__FILE__,__LINE__)
    call memfree( q      ,__FILE__,__LINE__)
    call memfree( emarked,__FILE__,__LINE__)

    call lconn%calculate_header()
    call lconn%allocate_list_from_pointer()

    current=1
    lconn_iterator = lconn%create_iterator()
    do i=1, lconn_iterator%get_size()
       vmarked = 0
       ! Traverse elements of current connected component  
       do current=current,current+auxe(i)-1
          j=e(current)

          ! Traverse the nodes of the element number j
          inods1d = m%pnods(j)
          inods2d = m%pnods(j+1)-1

          do p_ipoin = inods1d, inods2d
             ipoin = m%lnods(p_ipoin)
             if (vmarked(ipoin)==0) then
                vmarked(ipoin)=1
                call lconn_iterator%set_current(ipoin)
                call lconn_iterator%next()
             end if
          end do

       end do
    end do

    call memfree( auxe,__FILE__,__LINE__)
    call memfree( e,__FILE__,__LINE__)
    call memfree( vmarked,__FILE__,__LINE__)

  end subroutine mesh_graph_compute_connected_components

  !=================================================================================================
  subroutine graph_nd_renumbering(prt_parts, gp, iperm, lperm)
    !-----------------------------------------------------------------------
    !-----------------------------------------------------------------------
    implicit none
    type(mesh_distribution_params_t), intent(in)         :: prt_parts
    type(list_t)                    , target, intent(inout) :: gp
    integer(ip)                     , target, intent(out):: iperm(gp%get_size())
    integer(ip)                     , target, intent(out):: lperm(gp%get_size())

#ifdef ENABLE_METIS
    integer(c_int),target :: options(0:METIS_NOPTIONS-1)
    integer(c_int)        :: ierr
#endif
    
    if ( gp%get_num_pointers() == 1 ) then
       lperm(1) = 1
       iperm(1) = 1
    else
#ifdef ENABLE_METIS
       ierr = metis_setdefaultoptions(c_loc(options))
       assert(ierr == METIS_OK) 
       
       options(METIS_OPTION_NUMBERING) = 1
       options(METIS_OPTION_DBGLVL)    = prt_parts%metis_option_debug
       
       ierr = metis_nodend ( gp%get_num_pointers_c_loc() ,gp%get_pointers_c_loc() , gp%get_list_c_loc(), &
            &                C_NULL_PTR, c_loc(options), c_loc(iperm),c_loc(lperm))
       
       assert(ierr == METIS_OK)
#else
       call enable_metis_error_message
#endif
    end if
  end subroutine graph_nd_renumbering

  !=================================================================================================
  subroutine graph_pt_renumbering(prt_parts,gp,ldomn,weight)
    !-----------------------------------------------------------------------
    ! This routine computes a nparts-way-partitioning of the input graph gp
    !-----------------------------------------------------------------------
    implicit none
    type(mesh_distribution_params_t), target, intent(in)    :: prt_parts
    type(list_t)                    , target, intent(inout) :: gp
    integer(ip)                     , target, intent(out)   :: ldomn(gp%get_num_pointers())
    integer(ip)                     , target, optional, intent(in)  :: weight(gp%get_size())

    ! Local variables 
    integer(ip), target      :: kedge
    integer(ip)              :: idumm,iv
    integer(ip), allocatable :: lwork(:)
    integer(ip)              :: i, j, m, k, ipart
    integer(ip), allocatable :: iperm(:)
#ifdef ENABLE_METIS
    integer(c_int),target :: options(0:METIS_NOPTIONS-1)
    integer(c_int),target :: ncon 
    integer(c_int)        :: ierr
#endif    
   
#ifdef ENABLE_METIS
    ierr = metis_setdefaultoptions(c_loc(options))
    assert(ierr == METIS_OK) 

!!$      From METIS 5.0 manual:
!!$
!!$      The following options are valid for METIS PartGraphRecursive:
!!$      
!!$      METIS_OPTION_CTYPE, METIS_OPTION_IPTYPE, METIS_OPTION_RTYPE,
!!$      METIS_OPTION_NO2HOP, METIS_OPTION_NCUTS, METIS_OPTION_NITER,
!!$      METIS_OPTION_SEED, METIS_OPTION_UFACTOR, METIS_OPTION_NUMBERING,
!!$      METIS_OPTION_DBGLVL
!!$     
!!$      The following options are valid for METIS PartGraphKway:
!!$ 
!!$      METIS_OPTION_OBJTYPE, METIS_OPTION_CTYPE, METIS_OPTION_IPTYPE,
!!$      METIS_OPTION_RTYPE, METIS_OPTION_NO2HOP, METIS_OPTION_NCUTS,
!!$      METIS_OPTION_NITER, METIS_OPTION_UFACTOR, METIS_OPTION_MINCONN,
!!$      METIS_OPTION_CONTIG, METIS_OPTION_SEED, METIS_OPTION_NUMBERING,
!!$      METIS_OPTION_DBGLVL

    if ( prt_parts%strat == part_kway ) then
       options(METIS_OPTION_NUMBERING) = 1
       options(METIS_OPTION_DBGLVL)    = prt_parts%metis_option_debug
       
       ! Enforce contiguous partititions
       options(METIS_OPTION_CONTIG)    = prt_parts%metis_option_contig
       
       ! Explicitly minimize the maximum degree of the subdomain graph
       options(METIS_OPTION_MINCONN)   = prt_parts%metis_option_minconn
       options(METIS_OPTION_UFACTOR)   = prt_parts%metis_option_ufactor

       ! Select random (default) or sorted heavy edge matching
       options(METIS_OPTION_CTYPE)     = prt_parts%metis_option_ctype
       options(METIS_OPTION_IPTYPE)     = prt_parts%metis_option_iptype
       
       ncon = 1 
       
       if(present(weight)) then
          options(METIS_OPTION_NITER) = 100

          ierr = metis_partgraphkway( gp%get_num_pointers_c_loc(), c_loc(ncon), gp%get_pointers_c_loc(), gp%get_list_c_loc() , & 
!                                    vw             vsize       adjw
                                      C_NULL_PTR  , C_NULL_PTR , c_loc(weight) , c_loc(prt_parts%nparts), &
                                      C_NULL_PTR  , C_NULL_PTR , c_loc(options), c_loc(kedge), c_loc(ldomn) )
       else
          ierr = metis_partgraphkway( gp%get_num_pointers_c_loc(), c_loc(ncon), gp%get_pointers_c_loc(), gp%get_list_c_loc() , & 
                                      C_NULL_PTR  , C_NULL_PTR , C_NULL_PTR    , c_loc(prt_parts%nparts), &
                                      C_NULL_PTR  , C_NULL_PTR , c_loc(options), c_loc(kedge), c_loc(ldomn) )
       end if

       assert(ierr == METIS_OK) 
       
    else if ( prt_parts%strat == part_recursive ) then
       options(METIS_OPTION_NUMBERING) = 1
       options(METIS_OPTION_DBGLVL)    = prt_parts%metis_option_debug
       options(METIS_OPTION_UFACTOR)   = prt_parts%metis_option_ufactor

       ncon = 1 
       ierr = metis_partgraphrecursive( gp%get_num_pointers_c_loc(), c_loc(ncon), gp%get_pointers_c_loc(), gp%get_list_c_loc() , & 
                                        C_NULL_PTR  , C_NULL_PTR , C_NULL_PTR    , c_loc(prt_parts%nparts), &
                                        C_NULL_PTR  , C_NULL_PTR , c_loc(options), c_loc(kedge), c_loc(ldomn) )
    end if    
#else
    call enable_metis_error_message
#endif

    if ( prt_parts%strat == part_strip ) then
       j = gp%get_num_pointers()
       m = 0
       do ipart=1,prt_parts%nparts
          k = j / (prt_parts%nparts-ipart+1)
          do i = 1, k
             ldomn(m+i) = ipart
          end do
          m = m + k
          j = j - k
       end do
    else if ( prt_parts%strat == part_rcm_strip ) then
       call memalloc ( gp%get_num_pointers(), iperm, __FILE__,__LINE__ )
       call genrcm ( gp, iperm )
       j = gp%get_num_pointers()
       m = 0
       do ipart=1,prt_parts%nparts
          k = j / (prt_parts%nparts-ipart+1)
          do i = 1, k
             ldomn(iperm(m+i)) = ipart
          end do
          m = m + k
          j = j - k
       end do
       call memfree ( iperm,__FILE__,__LINE__)
    end if

  end subroutine graph_pt_renumbering


  !================================================================================================
  subroutine mesh_g2l(num_local_vertices, l2g_vertices, num_local_cells, l2g_cells, gmesh, lmesh)
    implicit none
    integer(ip),     intent(in)    :: num_local_vertices
    integer(igp),    intent(in)    :: l2g_vertices(num_local_vertices)
    integer(ip),     intent(in)    :: num_local_cells
    integer(igp),    intent(in)    :: l2g_cells(num_local_cells)
    type(mesh_t)   , intent(in)    :: gmesh
    type(mesh_t)   , intent(inout) :: lmesh
    type(hash_table_igp_ip_t)      :: ws_inmap
    type(hash_table_igp_ip_t)      :: el_inmap
    integer(ip)    , allocatable   :: node_list(:)
    integer(ip)                    :: aux, ipoin,inode,knode,kvef_size,lvef_size,istat
    integer(ip)                    :: ielem_lmesh,ielem_gmesh,ivef_lmesh,ivef_gmesh
    integer(ip)                    :: p_ielem_gmesh,p_ipoin_lmesh,p_ipoin_gmesh
    type(list_iterator_t)          :: given_vefs_iterator
    logical :: count_it


    lmesh%order=gmesh%order
    lmesh%nelty=gmesh%nelty
    lmesh%ndime=gmesh%ndime
    lmesh%npoin=num_local_vertices
    lmesh%nelem=num_local_cells

    call ws_inmap%init(max(int(num_local_vertices*0.25,ip),10))
    do ipoin=1,num_local_vertices
       ! aux is used to avoid compiler warning related to val being an intent(inout) argument
       aux = ipoin
       call ws_inmap%put(key=l2g_vertices(ipoin),val=aux,stat=istat) 
    end do

    call el_inmap%init(max(int(num_local_cells*0.25,ip),10))
    do ipoin=1,num_local_cells
       ! aux is used to avoid compiler warning related to val being an intent(inout) argument
       aux = ipoin
       call el_inmap%put(key=l2g_cells(ipoin),val=aux,stat=istat) 
    end do

    ! Elements
    call memalloc(lmesh%nelem+1, lmesh%pnods, __FILE__,__LINE__)
    call memalloc(lmesh%nelem  , lmesh%legeo, __FILE__,__LINE__)
    call memalloc(lmesh%nelem  , lmesh%leset, __FILE__,__LINE__)
    lmesh%nnode=0
    lmesh%pnods=0
    lmesh%pnods(1)=1
    do ielem_lmesh=1,lmesh%nelem
       ielem_gmesh = l2g_cells(ielem_lmesh)
       knode = gmesh%pnods(ielem_gmesh+1)-gmesh%pnods(ielem_gmesh)
       lmesh%pnods(ielem_lmesh+1)=lmesh%pnods(ielem_lmesh)+knode
       lmesh%nnode=max(lmesh%nnode,knode)
       lmesh%legeo(ielem_lmesh)=gmesh%legeo(ielem_gmesh)
       lmesh%leset(ielem_lmesh)=gmesh%leset(ielem_gmesh)
    end do
    call memalloc (lmesh%pnods(lmesh%nelem+1), lmesh%lnods, __FILE__,__LINE__)
    do ielem_lmesh=1,lmesh%nelem
       ielem_gmesh = l2g_cells(ielem_lmesh)
       p_ipoin_gmesh = gmesh%pnods(ielem_gmesh)-1
       p_ipoin_lmesh = lmesh%pnods(ielem_lmesh)-1
       knode = gmesh%pnods(ielem_gmesh+1)-gmesh%pnods(ielem_gmesh)
       do inode=1,knode
          call ws_inmap%get(key=int(gmesh%lnods(p_ipoin_gmesh+inode),igp),val=lmesh%lnods(p_ipoin_lmesh+inode),stat=istat) 
       end do
    end do

    ! Boundary elements
    ivef_lmesh=0
    lmesh%nnodb=0
    lvef_size=0
    do ivef_gmesh=1,gmesh%given_vefs%get_num_pointers()
       given_vefs_iterator = gmesh%given_vefs%create_iterator(ivef_gmesh)
       kvef_size = given_vefs_iterator%get_size()
       count_it=.true.
       do while(.not. given_vefs_iterator%is_upper_bound())
          call ws_inmap%get(key=int(given_vefs_iterator%get_current(),igp),val=knode,stat=istat)
          call given_vefs_iterator%next()
          if(istat==key_not_found) then
             count_it=.false.
             exit
          end if
       end do
       if(count_it) then
          lvef_size=lvef_size+kvef_size
          lmesh%nnodb=max(lmesh%nnodb,kvef_size)
          ivef_lmesh=ivef_lmesh+1
       end if
    end do

    if(ivef_lmesh>0) then

       call memalloc (  lmesh%nnodb,   node_list, __FILE__,__LINE__)
       call memalloc(   ivef_lmesh, lmesh%lst_vefs_geo, __FILE__,__LINE__)
       call memalloc(   ivef_lmesh, lmesh%lst_vefs_set, __FILE__,__LINE__)

       call lmesh%given_vefs%create(ivef_lmesh)

       ivef_lmesh=1
       do ivef_gmesh=1,gmesh%given_vefs%get_num_pointers()
          given_vefs_iterator = gmesh%given_vefs%create_iterator(ivef_gmesh)
          kvef_size = given_vefs_iterator%get_size()
          count_it=.true.
          do inode=1,kvef_size
             call ws_inmap%get(key=int(given_vefs_iterator%get_current(),igp),val=node_list(inode),stat=istat)
             call given_vefs_iterator%next()
             if(istat==key_not_found) then
                count_it=.false.
                exit
             end if
          end do
          if(count_it) then
             call lmesh%given_vefs%sum_to_pointer_index(ivef_lmesh, kvef_size)
             lmesh%lst_vefs_geo(ivef_lmesh)=gmesh%lst_vefs_geo(ivef_gmesh)
             lmesh%lst_vefs_set(ivef_lmesh)=gmesh%lst_vefs_set(ivef_gmesh)
             ivef_lmesh=ivef_lmesh+1
          end if
       end do

       call lmesh%given_vefs%calculate_header()
       call lmesh%given_vefs%allocate_list_from_pointer()

       ivef_lmesh=1
       do ivef_gmesh=1,gmesh%given_vefs%get_num_pointers()
          given_vefs_iterator = gmesh%given_vefs%create_iterator(ivef_gmesh)
          kvef_size = given_vefs_iterator%get_size()
          count_it=.true.
          do inode=1,kvef_size
             call ws_inmap%get(key=int(given_vefs_iterator%get_current(),igp),val=node_list(inode),stat=istat)
             call given_vefs_iterator%next()
             if(istat==key_not_found) then
                count_it=.false.
                exit
             end if
          end do
          if(count_it) then
             given_vefs_iterator = lmesh%given_vefs%create_iterator(ivef_lmesh)
             do inode=1,kvef_size
                call given_vefs_iterator%set_current(node_list(inode))
                call given_vefs_iterator%next()
             enddo
             ivef_lmesh=ivef_lmesh+1
          end if
       end do
       call memfree (node_list, __FILE__,__LINE__)
    end if
    
    call ws_inmap%free
    call el_inmap%free

    call memalloc(SPACE_DIM, lmesh%npoin, lmesh%coord, __FILE__,__LINE__)
    do ipoin=1,num_local_vertices
       lmesh%coord(:,ipoin)=gmesh%coord(:,l2g_vertices(ipoin))
    end do

  end subroutine mesh_g2l

  subroutine build_parts_graph (nparts, ldome, fe_graph, parts_graph)
    implicit none
    integer(ip)             , intent(in)  :: nparts
    type(list_t)            , intent(in)  :: fe_graph
    integer(ip)             , intent(in)  :: ldome(:)
    type(list_t)            , intent(out) :: parts_graph

    integer(ip)              :: istat,ielem,jelem,ipart,jpart
    integer(ip)              :: num_parts_around, touched
    type(list_iterator_t)                    :: fe_graph_iterator
    type(list_iterator_t)                    :: parts_graph_iterator
    type(position_hash_table_t), allocatable :: visited_parts_touched(:)
    type(hash_table_ip_ip_t)   , allocatable :: visited_parts_numbers(:)

    call parts_graph%create(nparts)

    ! The maximum number of parts around a part can be estimated from the
    ! maximum number of elements connected to an element, that is, by the 
    ! maximum degree of elements graph. Note, however, that it can be bigger.
    num_parts_around=0
    do ielem=1,fe_graph%get_num_pointers()
       fe_graph_iterator = fe_graph%create_iterator(ielem)
       num_parts_around = max(num_parts_around,fe_graph_iterator%get_size())
    end do
    allocate(visited_parts_touched(nparts),stat=istat); assert(istat==0);
    allocate(visited_parts_numbers(nparts),stat=istat); assert(istat==0);
    do ipart=1,nparts
       call visited_parts_touched(ipart)%init(num_parts_around)
       call visited_parts_numbers(ipart)%init(num_parts_around)
    end do

    ! Now compute graph pointers and fill tables
    do ielem=1,fe_graph%get_num_pointers()
       ipart = ldome(ielem)
       fe_graph_iterator = fe_graph%create_iterator(ielem)
       do while(.not.fe_graph_iterator%is_upper_bound())
          jelem = fe_graph_iterator%get_current()
          jpart = ldome(jelem)
          call visited_parts_touched(ipart)%get(key=jpart,val=num_parts_around,stat=istat) ! Touch it (jpart is around ipart)
          if(istat==new_index) then
             call visited_parts_numbers(ipart)%put(key=num_parts_around,val=jpart,stat=istat) ! Store it
             assert(istat==now_stored)
          end if
          call fe_graph_iterator%next()
       end do
    end do
    do ipart=1,nparts
       call parts_graph%sum_to_pointer_index(ipart,visited_parts_touched(ipart)%last())
    end do

    ! Fill graph from tables
    call parts_graph%calculate_header()
    call parts_graph%allocate_list_from_pointer()
    do ipart=1,nparts
       num_parts_around = 0
       parts_graph_iterator = parts_graph%create_iterator(ipart)
       do while(.not.parts_graph_iterator%is_upper_bound())
          num_parts_around = num_parts_around + 1
          call visited_parts_numbers(ipart)%get(key=num_parts_around,val=jpart,stat=istat) 
          assert(istat==key_found)
          call parts_graph_iterator%set_current(jpart)
          call parts_graph_iterator%next()
       end do
       assert(num_parts_around==visited_parts_touched(ipart)%last())
       call visited_parts_touched(ipart)%free() ! This could be done before, as far as the assert is eliminated
       call visited_parts_numbers(ipart)%free()
    end do

    deallocate(visited_parts_touched,stat=istat)
    deallocate(visited_parts_numbers,stat=istat)
  end subroutine build_parts_graph

end module mesh_names
