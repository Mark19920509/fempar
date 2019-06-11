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
module mesh_distribution_names
  use types_names
  use memor_names
  use stdio_names
  use metis_names
  use mesh_partitioner_parameters_names
  use FPL
  implicit none
# include "debug.i90"
  private

  !> Derived data type which describes on each MPI task its local 
  !> subdomain and its interface with neighbouring subdomains
  type mesh_distribution_t
     integer(ip) ::                &
        ipart  = 1,                &    ! Part identifier
        nparts = 1                      ! Number of parts

     integer(ip), allocatable ::   &
        pextn(:),                  &    ! Pointers to the lext*
        lextp(:)                        ! List of parts of external neighbors
     
     integer(igp), allocatable ::  &
        lextn(:)                        ! List of (GIDs of) external neighbors

     integer(ip) ::                &
        nebou=0,                   &    ! Number of boundary elements
        nnbou=0                         ! Number of boundary nodes 

     integer(ip), allocatable  ::  & 
        lebou(:),                  &  ! List of boundary elements 
        lnbou(:)                      ! List of boundary nodes
        
     integer(ip)               :: num_local_vertices=0     ! Number of local vertices
     integer(igp)              :: num_global_vertices=0    ! Number of global vertices
     integer(igp), allocatable :: l2g_vertices(:)          ! Local 2 global array of vertices
     
     integer(ip)               :: num_local_cells=0     ! Number of local cells
     integer(igp)              :: num_global_cells=0    ! Number of global cells
     integer(igp), allocatable :: l2g_cells(:)          ! Local 2 global array of cells

   contains
     procedure, non_overridable :: free  => mesh_distribution_free
     procedure, non_overridable :: print => mesh_distribution_print
     procedure, non_overridable :: read  => mesh_distribution_read
     procedure, non_overridable :: write => mesh_distribution_write
     procedure, non_overridable :: read_file    => mesh_distribution_read_file
     procedure, non_overridable :: create_empty => mesh_distribution_create_empty
     procedure, non_overridable :: get_sizes    => mesh_distribution_get_sizes
     procedure, non_overridable :: move_gids    => mesh_distribution_move_gids
     procedure, non_overridable :: move_external_elements_info => mesh_distribution_move_external_elements_info
  end type mesh_distribution_t


  type mesh_distribution_params_t
     integer(ip) :: nparts         = 2    ! nparts
     integer(ip) :: num_levels     = 1    ! nlevels
     integer(ip), allocatable :: num_parts_x_level (:)

     integer(ip) :: debug       = 1    ! Print info partition

     integer(ip) :: strat = part_kway  ! Partitioning algorithm (part_kway,
                                       ! part_recursive,part_strip,part_rcm_strip)

     ! Only applicable to metis 5.0 for both part_kway and part_recursive
     ! Use METIS defaults (i.e., == -1) 30 for part_kway, and 1 for part_recursive
     integer(ip) :: metis_option_ufactor = -1 ! Imbalance tol of x/1000 + 1

     ! Only applicable to metis 5.0 and part_kway
     integer(ip) :: metis_option_minconn = 1 ! (Try to) Minimize maximum degree 
                                             ! of subdomain graph
     integer(ip) :: metis_option_contig  = 1 ! (Try to) Produce partitions 
                                             ! that are contiguous
     
     integer(ip) :: metis_option_ctype  = METIS_CTYPE_RM    ! Random matching
     integer(ip) :: metis_option_iptype = METIS_IPTYPE_GROW ! Grow bisection greedy

     ! Applicable to both metis 4.0 and metis 5.0
     integer(ip) :: metis_option_debug  =  0 
     contains
       procedure, non_overridable :: get_parameters_from_fpl =>  mesh_distribution_get_parameters_from_fpl
       procedure, non_overridable :: free => mesh_distribution_parameters_free
  end type mesh_distribution_params_t

  ! Types
  public :: mesh_distribution_t, mesh_distribution_params_t

  ! Functions
  public :: mesh_distribution_write_files
  public :: mesh_distribution_read_files
  public :: mesh_distribution_compose_name

contains

  subroutine mesh_distribution_get_parameters_from_fpl(this,parameter_list)
    !-----------------------------------------------------------------------------------------------!
    !   This subroutine generates geometry data to construct a structured mesh                      !
    !-----------------------------------------------------------------------------------------------!
    implicit none
    class(mesh_distribution_params_t), intent(inout) :: this
    type(ParameterList_t)            , intent(in)    :: parameter_list
    ! Locals
    integer(ip)              :: istat
    integer(ip), allocatable :: param_size(:), param(:)

    ! Mandatory parameters: either nparts or num_levels
    assert(parameter_list%isPresent(key = num_parts_key).or.parameter_list%isPresent(key = num_levels_distribution_key))
    if( parameter_list%isPresent(num_parts_key)) then
       assert(parameter_list%isAssignable(num_parts_key, this%nparts))
       istat = parameter_list%get(key = num_parts_key , value = this%nparts)
       assert(istat==0)
    end if
    if( parameter_list%isPresent(num_levels_distribution_key) ) then
       assert(parameter_list%isAssignable(num_levels_distribution_key, this%num_levels))
       istat = parameter_list%get(key = num_levels_distribution_key  , value = this%num_levels)
       assert(istat==0)
       
       assert(parameter_list%isPresent(key = num_parts_x_level_key ))
       assert( parameter_list%GetDimensions(key = num_parts_x_level_key) == 1)

       ! Get the array using the local variable
       istat =  parameter_list%GetShape(key = num_parts_x_level_key, shape = param_size ); check(istat==0)
       call memalloc(param_size(1), param,__FILE__,__LINE__)
       assert(parameter_list%isAssignable(num_parts_x_level_key, param))
       istat = parameter_list%get(key = num_parts_x_level_key, value = param)
       assert(istat==0)

       call memalloc(this%num_levels, this%num_parts_x_level,__FILE__,__LINE__)
       this%num_parts_x_level = param(1:this%num_levels)
       call memfree(param,__FILE__,__LINE__)

       this%nparts = this%num_parts_x_level(1)
    else
       this%num_levels=1
       call memalloc(this%num_levels, this%num_parts_x_level,__FILE__,__LINE__)
       this%num_parts_x_level(1)=this%nparts
    end if

    ! Optional paramters
    if( parameter_list%isPresent(debug_key) ) then
       assert(parameter_list%isAssignable(debug_key, this%debug))
       istat = parameter_list%get(key = debug_key  , value = this%debug)
       assert(istat==0)
    end if

    if( parameter_list%isPresent(strategy_key) ) then
       assert(parameter_list%isAssignable(strategy_key, this%strat))
       istat = parameter_list%get(key = strategy_key  , value = this%strat)
       assert(istat==0)
       assert(this%strat==part_kway.or.this%strat==part_recursive.or.this%strat==part_strip.or.this%strat==part_rcm_strip)
    end if

    if( parameter_list%isPresent(metis_option_debug_key) ) then
       assert(parameter_list%isAssignable(metis_option_debug_key, this%metis_option_debug))
       istat = parameter_list%get(key = metis_option_debug_key  , value = this%metis_option_debug)
       check(istat==0)
    end if

    if( parameter_list%isPresent(metis_option_ufactor_key) ) then
       assert(parameter_list%isAssignable(metis_option_ufactor_key, this%metis_option_ufactor))
       istat = parameter_list%get(key = metis_option_ufactor_key, value = this%metis_option_ufactor)
       assert(istat==0)
    end if

    if( parameter_list%isPresent(metis_option_minconn_key) ) then
       assert(parameter_list%isAssignable(metis_option_minconn_key, this%metis_option_minconn))
       istat = parameter_list%get(key = metis_option_minconn_key, value = this%metis_option_minconn)
       check(istat==0)
    end if

    if( parameter_list%isPresent(metis_option_contig_key) ) then
       assert(parameter_list%isAssignable(metis_option_contig_key, this%metis_option_contig))
       istat = parameter_list%get(key = metis_option_contig_key , value = this%metis_option_contig)
       assert(istat==0)
    end if

    if( parameter_list%isPresent(metis_option_ctype_key) ) then
       assert(parameter_list%isAssignable(metis_option_ctype_key, this%metis_option_ctype))
       istat = parameter_list%get(key = metis_option_ctype_key  , value = this%metis_option_ctype)
       assert(istat==0)
    end if

  end subroutine mesh_distribution_get_parameters_from_fpl

  !=============================================================================
  subroutine mesh_distribution_parameters_free(this)
    implicit none
    class(mesh_distribution_params_t), intent(inout) :: this
    call memfree(this%num_parts_x_level,__FILE__,__LINE__)
  end subroutine mesh_distribution_parameters_free

  !=============================================================================
  subroutine mesh_distribution_get_sizes(this,ipart,nparts)
    class(mesh_distribution_t), intent(inout) :: this
    integer(ip), intent(inout) :: ipart,nparts
    ipart=this%ipart
    nparts=this%nparts
  end subroutine mesh_distribution_get_sizes
  !=============================================================================
  subroutine mesh_distribution_move_gids(this,cells_gid,vefs_gid)
    class(mesh_distribution_t), intent(inout) :: this
    integer(igp), intent(inout), allocatable :: vefs_gid(:)
    integer(igp), intent(inout), allocatable :: cells_gid(:)
    call memmovealloc(this%l2g_vertices,vefs_gid,__FILE__,__LINE__)
    call memmovealloc(this%l2g_cells,cells_gid,__FILE__,__LINE__)
  end subroutine mesh_distribution_move_gids
  !=============================================================================
  subroutine mesh_distribution_move_external_elements_info(this,nebou,lebou,pextn,lextn,lextp)
    class(mesh_distribution_t), intent(inout) :: this
    integer(ip), intent(inout)   :: nebou
    integer(ip), intent(inout), allocatable :: lebou(:)
    integer(ip), intent(inout), allocatable :: pextn(:)
    integer(igp), intent(inout), allocatable :: lextn(:)
    integer(ip), intent(inout), allocatable :: lextp(:)
    nebou=this%nebou
    call memmovealloc(this%lebou,lebou,__FILE__,__LINE__)
    call memmovealloc(this%pextn,pextn,__FILE__,__LINE__)
    call memmovealloc(this%lextn,lextn,__FILE__,__LINE__)
    call memmovealloc(this%lextp,lextp,__FILE__,__LINE__)
  end subroutine mesh_distribution_move_external_elements_info
  !=============================================================================
  subroutine mesh_distribution_create_empty(this)
    class(mesh_distribution_t), intent(inout) :: this
    call memalloc ( 1, this%pextn ,__FILE__,__LINE__  )
    this%pextn(1) = 1
  end subroutine mesh_distribution_create_empty
  !=============================================================================
  subroutine mesh_distribution_free (f_msh_dist)
    !-----------------------------------------------------------------------
    ! This subroutine deallocates a mesh_distribution object
    !-----------------------------------------------------------------------
    implicit none

    ! Parameters
    class(mesh_distribution_t), intent(inout)  :: f_msh_dist
    if(allocated(f_msh_dist%lebou)) call memfree ( f_msh_dist%lebou,__FILE__,__LINE__)
    if(allocated(f_msh_dist%lnbou)) call memfree ( f_msh_dist%lnbou,__FILE__,__LINE__)
    if(allocated(f_msh_dist%pextn)) call memfree ( f_msh_dist%pextn ,__FILE__,__LINE__)
    if(allocated(f_msh_dist%lextn)) call memfree ( f_msh_dist%lextn ,__FILE__,__LINE__)
    if(allocated(f_msh_dist%lextp)) call memfree ( f_msh_dist%lextp ,__FILE__,__LINE__)
    if(allocated(f_msh_dist%l2g_vertices)) call memfree ( f_msh_dist%l2g_vertices, __FILE__,__LINE__)
    if(allocated(f_msh_dist%l2g_cells)) call memfree ( f_msh_dist%l2g_cells, __FILE__,__LINE__)
  end subroutine mesh_distribution_free

  !=============================================================================
  subroutine mesh_distribution_print (msh_dist, lu_out)
    !-----------------------------------------------------------------------
    ! This subroutine prints a mesh_distribution object
    !-----------------------------------------------------------------------
    implicit none

    ! Parameters
    integer(ip)              , intent(in)  :: lu_out
    class(mesh_distribution_t), intent(in)  :: msh_dist

    ! Local variables
    integer (ip) :: i, j

    if(lu_out>0) then

       write(lu_out,'(a)') '*** begin mesh_distribution data structure ***'

       write(lu_out,'(a,i10)') 'Number of parts:', &
           &  msh_dist%nparts

       write(lu_out,'(a,i10)') 'Number of elements on the boundary:', &
          &  msh_dist%nebou

       write(lu_out,'(a,i10)') 'Number of neighbours:', &
          &  msh_dist%pextn(msh_dist%nebou+1)-msh_dist%pextn(1)

       write(lu_out,'(a)') 'GEIDs of boundary elements:'
       do i=1,msh_dist%nebou
          write(lu_out,'(10i10)') msh_dist%l2g_cells(msh_dist%lebou(i))
       end do

       write(lu_out,'(a)') 'GEIDs of neighbors:'
       do i=1,msh_dist%nebou
          write(lu_out,'(10i10)') (msh_dist%lextn(j),j=msh_dist%pextn(i),msh_dist%pextn(i+1)-1)
       end do

       write(lu_out,'(a)') 'Parts of neighbours:'
       do i=1,msh_dist%nebou
          write(lu_out,'(10i10)') (msh_dist%lextp(j),j=msh_dist%pextn(i),msh_dist%pextn(i+1)-1)
       end do

       write(lu_out,'(a)') '*** end mesh_distribution data structure ***'

    end if
 
  end subroutine mesh_distribution_print

  !=============================================================================
  subroutine mesh_distribution_write (f_msh_dist, lunio)
    ! Parameters
    integer                  , intent(in) :: lunio
    class(mesh_distribution_t), intent(in) :: f_msh_dist
    !-----------------------------------------------------------------------
    ! This subroutine writes a mesh_distribution to lunio
    !-----------------------------------------------------------------------

    write ( lunio, '(10i10)' ) f_msh_dist%ipart, f_msh_dist%nparts

    write ( lunio, '(10i10)' ) f_msh_dist%nebou
    write ( lunio, '(10i10)' ) f_msh_dist%lebou
    write ( lunio, '(10i10)' ) f_msh_dist%nnbou
    write ( lunio, '(10i10)' ) f_msh_dist%lnbou
    write ( lunio, '(10i10)' ) f_msh_dist%pextn
    write ( lunio, '(10i10)' ) f_msh_dist%lextn
    write ( lunio, '(10i10)' ) f_msh_dist%lextp

    write ( lunio, '(10i10)' ) f_msh_dist%num_local_vertices, &
                               f_msh_dist%num_global_vertices
    if(f_msh_dist%num_local_vertices>0) write ( lunio,'(10i10)') f_msh_dist%l2g_vertices
    
    write ( lunio, '(10i10)' ) f_msh_dist%num_local_cells, &
                               f_msh_dist%num_global_cells
    if(f_msh_dist%num_local_cells>0) write ( lunio,'(10i10)') f_msh_dist%l2g_cells


  end subroutine mesh_distribution_write

   subroutine mesh_distribution_read (f_msh_dist,  dir_path, prefix)
     implicit none 
     ! Parameters
     character(*)         , intent(in)    :: dir_path
     character(*)         , intent(in)    :: prefix
     class(mesh_distribution_t), intent(inout) :: f_msh_dist
     ! Locals
     integer(ip)                    :: lunio
     character(len=:), allocatable  :: name

     ! Read mesh
     call mesh_distribution_compose_name ( prefix, name )
     lunio = io_open( trim(dir_path)//'/'//trim(name), 'read', status='old' ); check(lunio>0)
     call f_msh_dist%read_file(lunio)
     call io_close(lunio)
   end subroutine mesh_distribution_read


   subroutine mesh_distribution_read_file (f_msh_dist, lunio)
    ! Parameters
    integer(ip)               , intent(in)    :: lunio
    class(mesh_distribution_t), intent(inout) :: f_msh_dist
    !-----------------------------------------------------------------------
    ! This subroutine reads a mesh_distribution object
    !-----------------------------------------------------------------------

    read ( lunio, '(10i10)' ) f_msh_dist%ipart, f_msh_dist%nparts

    read ( lunio, '(10i10)' ) f_msh_dist%nebou       
    call memalloc ( f_msh_dist%nebou, f_msh_dist%lebou,__FILE__,__LINE__  )
    read ( lunio, '(10i10)' ) f_msh_dist%lebou
        
    read ( lunio, '(10i10)' ) f_msh_dist%nnbou      
    call memalloc ( f_msh_dist%nnbou, f_msh_dist%lnbou,__FILE__,__LINE__  )
    read ( lunio, '(10i10)' ) f_msh_dist%lnbou
    
    
    call memalloc ( f_msh_dist%nebou+1, f_msh_dist%pextn ,__FILE__,__LINE__  )
    read ( lunio, '(10i10)' ) f_msh_dist%pextn
    
    call memalloc ( f_msh_dist%pextn(f_msh_dist%nebou+1)-1, f_msh_dist%lextn ,__FILE__,__LINE__  )
    call memalloc ( f_msh_dist%pextn(f_msh_dist%nebou+1)-1, f_msh_dist%lextp ,__FILE__,__LINE__  )
    read ( lunio, '(10i10)' ) f_msh_dist%lextn
    read ( lunio, '(10i10)' ) f_msh_dist%lextp

    read ( lunio, '(10i10)' ) f_msh_dist%num_local_vertices, &
                              f_msh_dist%num_global_vertices
    if(f_msh_dist%num_local_vertices>0) then
       if(allocated(f_msh_dist%l2g_vertices)) call memfree(f_msh_dist%l2g_vertices, __FILE__, __LINE__)
       call memalloc(f_msh_dist%num_local_vertices, f_msh_dist%l2g_vertices, __FILE__, __LINE__)
       read ( lunio,'(10i10)') f_msh_dist%l2g_vertices
    end if

    read ( lunio, '(10i10)' ) f_msh_dist%num_local_cells, &
                              f_msh_dist%num_global_cells
    if(f_msh_dist%num_local_cells>0) then
       if(allocated(f_msh_dist%l2g_cells)) call memfree(f_msh_dist%l2g_cells, __FILE__, __LINE__)
       call memalloc(f_msh_dist%num_local_cells, f_msh_dist%l2g_cells, __FILE__, __LINE__)
       read ( lunio,'(10i10)') f_msh_dist%l2g_cells
    end if

  end subroutine mesh_distribution_read_file

  !=============================================================================
  subroutine mesh_distribution_compose_name ( prefix, name ) 
    implicit none
    character (len=*), intent(in)    :: prefix 
    character (len=:), allocatable, intent(inout) :: name
    name = trim(prefix) // '.prt'
  end subroutine 

  !=============================================================================
  subroutine mesh_distribution_write_files ( parameter_list, parts )
    implicit none
    ! Parameters
    type(ParameterList_t)    , intent(in) :: parameter_list
    type(mesh_distribution_t), intent(in)  :: parts(:)

    ! Locals
    integer(ip)                   :: nparts
    integer(ip)                   :: istat
    logical                       :: is_present
    character(len=:), allocatable :: dir_path
    character(len=:), allocatable :: prefix
    character(len=:), allocatable :: name, rename
    integer(ip)                   :: lunio
    integer(ip)                   :: i

    nparts = size(parts)

    ! Mandatory parameters
    assert(parameter_list%isAssignable(dir_path_out_key, 'string'))
    istat = parameter_list%GetAsString(key = dir_path_out_key, String = dir_path)
    assert(istat == 0)
    
    assert(parameter_list%isAssignable(prefix_key, 'string'))
    istat = istat + parameter_list%GetAsString(key = prefix_key, String = prefix)
    assert(istat==0)

    call mesh_distribution_compose_name ( prefix, name )
    
    do i=1,nparts
       rename=name
       call numbered_filename_compose(i,nparts,rename)
       lunio = io_open (trim(dir_path) // '/' // trim(rename)); check(lunio>0)
       call parts(i)%write (lunio)
       call io_close (lunio)
    end do

    ! name, and rename should be automatically deallocated by the compiler when they
    ! go out of scope. Should we deallocate them explicitly for safety reasons?
  end subroutine  mesh_distribution_write_files

  !=============================================================================
  subroutine mesh_distribution_read_files ( dir_path, prefix, nparts, parts )
    implicit none
    ! Parameters 
    character(*), intent(in)    :: dir_path 
    character(*), intent(in)    :: prefix
    integer(ip)     , intent(in)    :: nparts
    type(mesh_distribution_t), intent(inout)  :: parts(nparts)

    ! Locals 
    integer (ip)                        :: i
    character(len=:), allocatable       :: name,rename ! Deferred-length allocatable character arrays
    integer(ip)                         :: lunio

    call mesh_distribution_compose_name ( prefix, name )

    do i=1,nparts
       rename=name
       call numbered_filename_compose(i,nparts,rename)
       lunio = io_open (trim(dir_path) // '/' // trim(rename)); check(lunio>0)
       call parts(i)%read_file (lunio)
       call io_close (lunio)
    end do

    ! name, and rename should be automatically deallocated by the compiler when they
    ! go out of scope. Should we deallocate them explicitly for safety reasons?
  end subroutine  mesh_distribution_read_files

end module mesh_distribution_names
