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
module par_test_poisson_error_estimator_params_names
  use fempar_names
# include "debug.i90"

  implicit none
  private

  type par_test_poisson_error_estimator_params_t
     private 
     ! IO parameters
     character(len=:), allocatable :: default_dir_path 
     character(len=:), allocatable :: default_prefix
     character(len=:), allocatable :: default_dir_path_out
     character(len=:), allocatable :: default_fe_formulation
     character(len=:), allocatable :: default_reference_fe_geo_order
     character(len=:), allocatable :: default_reference_fe_order
     character(len=:), allocatable :: default_write_solution
     character(len=:), allocatable :: default_laplacian_type
     character(len=:), allocatable :: default_triangulation_type
     character(len=:), allocatable :: default_num_dims
     character(len=:), allocatable :: default_nx
     character(len=:), allocatable :: default_ny
     character(len=:), allocatable :: default_nz
     character(len=:), allocatable :: default_is_periodic_in_x
     character(len=:), allocatable :: default_is_periodic_in_y
     character(len=:), allocatable :: default_is_periodic_in_z
     character(len=:), allocatable :: default_use_void_fes
     character(len=:), allocatable :: default_use_void_fes_case
     character(len=:), allocatable :: default_refinement_strategy
     character(len=:), allocatable :: default_analytical_functions_type

     type(Command_Line_Interface):: cli 

     ! IO parameters
     character(len=str_cla_len) :: dir_path
     character(len=str_cla_len) :: prefix
     character(len=str_cla_len) :: dir_path_out
     character(len=str_cla_len) :: fe_formulation
     integer(ip)                :: reference_fe_geo_order
     integer(ip)                :: reference_fe_order
     logical                    :: write_solution
     character(len=str_cla_len) :: laplacian_type

     character(len=str_cla_len) :: triangulation_type
     integer(ip) :: num_dims
     integer(ip) :: num_cells_x_dir(0:SPACE_DIM-1)
     integer(ip) :: is_dir_periodic(0:SPACE_DIM-1)
     
     logical                    :: use_void_fes
     character(len=str_cla_len) :: use_void_fes_case
     character(len=str_cla_len) :: refinement_strategy
     character(len=str_cla_len) :: analytical_functions_type

   contains
     procedure, non_overridable             :: create       => par_test_poisson_create
     procedure, non_overridable, private    :: set_default  => par_test_poisson_set_default
     procedure, non_overridable, private    :: add_to_cli   => par_test_poisson_add_to_cli
     procedure, non_overridable             :: parse        => par_test_poisson_parse 
     procedure, non_overridable             :: free         => par_test_poisson_free
     procedure, non_overridable             :: get_dir_path
     procedure, non_overridable             :: get_prefix
     procedure, non_overridable             :: get_dir_path_out
     procedure, non_overridable             :: get_fe_formulation
     procedure, non_overridable             :: get_reference_fe_geo_order
     procedure, non_overridable             :: get_reference_fe_order
     procedure, non_overridable             :: get_write_solution
     procedure, non_overridable             :: get_laplacian_type
     procedure, non_overridable             :: get_triangulation_type
     procedure, non_overridable             :: get_num_dims
     procedure, non_overridable             :: get_use_void_fes
     procedure, non_overridable             :: get_use_void_fes_case
     procedure, non_overridable             :: get_refinement_strategy
     procedure, non_overridable             :: get_analytical_functions_type
     
  end type par_test_poisson_error_estimator_params_t  

  ! Types
  public :: par_test_poisson_error_estimator_params_t

contains

  subroutine par_test_poisson_create(this)
    implicit none
    class(par_test_poisson_error_estimator_params_t), intent(inout) :: this
    
    call this%free()
    
     ! Initialize Command Line Interface
    call this%cli%init(progname    = 'par_test_poisson',                                                     &
         &        version     = '',                                                                 &
         &        authors     = '',                                                                 &
         &        license     = '',                                                                 &
         &        description =  'FEMPAR test to solve the 2D Poisson PDE with known analytical solution. &
                                  Boundary set ID 1 MUST BE ASSIGNED to the whole boundary.', &
         &        examples    = ['par_test_poisson -h  ', 'par_test_poisson -h  ' ])
    
    call this%set_default()
    call this%add_to_cli()
  end subroutine par_test_poisson_create
  
  subroutine par_test_poisson_set_default(this)
    implicit none
    class(par_test_poisson_error_estimator_params_t), intent(inout) :: this
    ! IO parameters
    this%default_dir_path       = 'data/'
    this%default_prefix         = 'square'
    this%default_dir_path_out   = 'output/'
    this%default_fe_formulation = 'cG'
    this%default_reference_fe_geo_order = '1'
    this%default_reference_fe_order = '1'
    this%default_write_solution = '.false.'
    this%default_laplacian_type = 'scalar'
    
    this%default_triangulation_type = 'structured'
    this%default_num_dims = '2'
    this%default_nx = '1'
    this%default_ny = '1'
    this%default_nz = '1'
    this%default_is_periodic_in_x = '0'
    this%default_is_periodic_in_y = '0'
    this%default_is_periodic_in_z = '0'
    
    this%default_use_void_fes = '.false.'
    this%default_use_void_fes_case = 'popcorn'
    this%default_refinement_strategy = 'uniform'
    this%default_analytical_functions_type = 'polynomial'
    
  end subroutine par_test_poisson_set_default
  
  !==================================================================================================
  subroutine par_test_poisson_add_to_cli(this)
    implicit none
    class(par_test_poisson_error_estimator_params_t) , intent(inout) :: this

    ! Locals
    integer(ip) :: error

    ! IO parameters
    call this%cli%add(switch='--dir-path',switch_ab='-d',                              &
         &            help='Directory of the source files',required=.false., act='store',                &
         &            def=trim(this%default_dir_path),error=error)
    check(error==0)
    call this%cli%add(switch='--prefix',switch_ab='-p',help='Name of the GiD files',  &
         &            required=.false.,act='store',def=trim(this%default_prefix),error=error) 
    check(error==0)
    call this%cli%add(switch='--dir-path-out',switch_ab='-o',help='Output Directory',&
         &            required=.false.,act='store',def=trim(this%default_dir_path_out),error=error)
    check(error==0)  
    call this%cli%add(switch='--fe-formulation',switch_ab='-f',help='cG or dG FE formulation for Poisson problem',&
         &            required=.false.,act='store',def=trim(this%default_fe_formulation), choices='cG,dG', error=error)
    check(error==0)  
    call this%cli%add(switch='--reference-fe-geo-order',switch_ab='-gorder',help='Order of the triangulation reference fe',&
         &            required=.false.,act='store',def=trim(this%default_reference_fe_geo_order),error=error)
    check(error==0)  
    call this%cli%add(switch='--reference-fe-order',switch_ab='-order',help='Order of the fe space reference fe',&
         &            required=.false.,act='store',def=trim(this%default_reference_fe_order),error=error) 
    check(error==0) 
    call this%cli%add(switch='--write-solution',switch_ab='-wsolution',help='Write solution in VTK format',&
         &            required=.false.,act='store',def=trim(this%default_write_solution),error=error) 
    check(error==0) 
    call this%cli%add(switch='--laplacian-type',switch_ab='-lt',help='Scalar or Vector-Valued Laplacian PDE?',&
         &            required=.false.,act='store',def=trim(this%default_laplacian_type),choices='scalar,vector',error=error) 
    check(error==0) 
    
    call this%cli%add(switch='--triangulation-type',switch_ab='-tt',help='Structured or unstructured (GiD) triangulation?',&
         &            required=.false.,act='store',def=trim(this%default_triangulation_type),choices='structured,unstructured',error=error) 
    check(error==0) 
    call this%cli%add(switch='--num_dims',switch_ab='-dim',help='Number of space dimensions',&
         &            required=.false.,act='store',def=trim(this%default_num_dims),error=error) 
    check(error==0) 
    call this%cli%add(switch='--num_cells_in_x',switch_ab='-nx',help='Number of cells in x',&
         &            required=.false.,act='store',def=trim(this%default_nx),error=error) 
    check(error==0) 
    call this%cli%add(switch='--num_cells_in_y',switch_ab='-ny',help='Number of cells in y',&
         &            required=.false.,act='store',def=trim(this%default_ny),error=error) 
    check(error==0) 
    call this%cli%add(switch='--num_cells_in_z',switch_ab='-nz',help='Number of cells in z',&
         &            required=.false.,act='store',def=trim(this%default_nz),error=error) 
    check(error==0) 
    call this%cli%add(switch='--periodic_in_x',switch_ab='-px',help='Is the mesh periodic in x',&
         &            required=.false.,act='store',def=trim(this%default_is_periodic_in_x),error=error) 
    check(error==0) 
    call this%cli%add(switch='--periodic_in_y',switch_ab='-py',help='Is the mesh periodic in y',&
         &            required=.false.,act='store',def=trim(this%default_is_periodic_in_y),error=error) 
    check(error==0) 
    call this%cli%add(switch='--periodic_in_z',switch_ab='-pz',help='Is the mesh periodic in z',&
         &            required=.false.,act='store',def=trim(this%default_is_periodic_in_z),error=error) 
    check(error==0) 
    
    call this%cli%add(switch='--use-void-fes',switch_ab='-use-voids',help='Use a hybrid FE space formed by full and void FEs',&
         &            required=.false.,act='store',def=trim(this%default_use_void_fes),error=error) 
    check(error==0) 
    
    call this%cli%add(switch='--use-void-fes-case',switch_ab='-use-voids-case',help='Select where to put void fes using one of the predefined patterns. Possible values: `popcorn`, `half`, `quarter`',&
         &            required=.false.,act='store',def=trim(this%default_use_void_fes_case),error=error) 
    check(error==0) 
    
    call this%cli%add(switch='--refinement_strategy',switch_ab='-rs',help='uniform or error_objective refinement strategy?',&
         &            required=.false.,act='store',def=trim(this%default_refinement_strategy),error=error) 
    check(error==0) 
    call this%cli%add(switch='--analytical_functions_type',switch_ab='-af',help='polynomial or shock analytical functions?',&
         &            required=.false.,act='store',def=trim(this%default_analytical_functions_type),error=error) 
    check(error==0) 
    
  end subroutine par_test_poisson_add_to_cli
  
  subroutine par_test_poisson_parse(this,parameter_list)
    implicit none
    class(par_test_poisson_error_estimator_params_t), intent(inout) :: this
    type(ParameterList_t)       , intent(inout) :: parameter_list
    integer(ip) :: istat
    
    call this%cli%parse(error=istat); check(istat==0)
    
    ! IO parameters
    call this%cli%get(switch='-d',val=this%dir_path    ,error=istat); check(istat==0)
    call this%cli%get(switch='-p',val=this%prefix       ,error=istat); check(istat==0)
    call this%cli%get(switch='-o',val=this%dir_path_out,error=istat); check(istat==0)
    call this%cli%get(switch='-f',val=this%fe_formulation,error=istat); check(istat==0)
    call this%cli%get(switch='-gorder',val=this%reference_fe_geo_order,error=istat); check(istat==0)
    call this%cli%get(switch='-order',val=this%reference_fe_order,error=istat); check(istat==0)
    call this%cli%get(switch='-wsolution',val=this%write_solution,error=istat); check(istat==0)
    call this%cli%get(switch='-lt',val=this%laplacian_type,error=istat); check(istat==0)

    call this%cli%get(switch='-tt',val=this%triangulation_type,error=istat); check(istat==0)
    call this%cli%get(switch='-dim',val=this%num_dims,error=istat); check(istat==0)
    call this%cli%get(switch='-nx',val=this%num_cells_x_dir(0),error=istat); check(istat==0)
    call this%cli%get(switch='-ny',val=this%num_cells_x_dir(1),error=istat); check(istat==0)
    call this%cli%get(switch='-nz',val=this%num_cells_x_dir(2),error=istat); check(istat==0)
    call this%cli%get(switch='-px',val=this%is_dir_periodic(0),error=istat); check(istat==0)
    call this%cli%get(switch='-py',val=this%is_dir_periodic(1),error=istat); check(istat==0)
    call this%cli%get(switch='-pz',val=this%is_dir_periodic(2),error=istat); check(istat==0)

    call this%cli%get(switch='-use-voids',val=this%use_void_fes,error=istat); check(istat==0)
    call this%cli%get(switch='-use-voids-case',val=this%use_void_fes_case,error=istat); check(istat==0)

    call this%cli%get(switch='-rs',val=this%refinement_strategy,error=istat); check(istat==0)
    call this%cli%get(switch='-af',val=this%analytical_functions_type,error=istat); check(istat==0)

    call parameter_list%init()
    istat = 0
    istat = istat + parameter_list%set(key = dir_path_key, value = this%dir_path)
    istat = istat + parameter_list%set(key = prefix_key  , value = this%prefix)
    istat = istat + parameter_list%set(key = triang_geometric_interpolation_order_key  , value = this%reference_fe_geo_order)
    check(istat==0)

    if(trim(this%triangulation_type)=='unstructured') then
       istat = parameter_list%set(key = triang_generate_key, value = triangulation_generate_from_mesh)
    else if(trim(this%triangulation_type)=='structured') then
       istat = parameter_list%set(key = triang_generate_key         , value = triangulation_generate_structured)
       istat = istat + parameter_list%set(key = struct_hex_triang_num_dims_key   , value = this%num_dims)
       istat = istat + parameter_list%set(key = struct_hex_triang_num_cells_dir_key, value = this%num_cells_x_dir)
       istat = istat + parameter_list%set(key = struct_hex_triang_is_dir_periodic_key        , value = this%is_dir_periodic)
    end if
    check(istat==0)
  end subroutine par_test_poisson_parse  

  subroutine par_test_poisson_free(this)
    implicit none
    class(par_test_poisson_error_estimator_params_t), intent(inout) :: this
    if(allocated(this%default_dir_path)) deallocate(this%default_dir_path)              
    if(allocated(this%default_prefix)) deallocate(this%default_prefix)                    
    if(allocated(this%default_dir_path_out)) deallocate(this%default_dir_path_out)
    if(allocated(this%default_reference_fe_geo_order)) deallocate(this%default_reference_fe_geo_order)
    if(allocated(this%default_reference_fe_order)) deallocate(this%default_reference_fe_order)
    if(allocated(this%default_write_solution)) deallocate(this%default_write_solution)
    if(allocated(this%default_laplacian_type)) deallocate(this%default_laplacian_type)
    if(allocated(this%default_use_void_fes)) deallocate(this%default_use_void_fes) 
    if(allocated(this%default_use_void_fes_case)) deallocate(this%default_use_void_fes_case)
    if(allocated(this%default_analytical_functions_type)) deallocate(this%default_analytical_functions_type)
    call this%cli%free()
  end subroutine par_test_poisson_free

  ! GETTERS *****************************************************************************************
  function get_dir_path(this)
    implicit none
    class(par_test_poisson_error_estimator_params_t) , intent(in) :: this
    character(len=:), allocatable :: get_dir_path
    get_dir_path = trim(this%dir_path)
  end function get_dir_path

  !==================================================================================================
  function get_prefix(this)
    implicit none
    class(par_test_poisson_error_estimator_params_t) , intent(in) :: this
    character(len=:), allocatable :: get_prefix
    get_prefix = trim(this%prefix)
  end function get_prefix

  !==================================================================================================
  function get_dir_path_out(this)
    implicit none
    class(par_test_poisson_error_estimator_params_t) , intent(in) :: this
    character(len=:), allocatable :: get_dir_path_out
    get_dir_path_out = trim(this%dir_path_out)
  end function get_dir_path_out
  
  !==================================================================================================
  function get_fe_formulation(this)
    implicit none
    class(par_test_poisson_error_estimator_params_t) , intent(in) :: this
    character(len=:), allocatable :: get_fe_formulation
    get_fe_formulation = trim(this%fe_formulation)
  end function get_fe_formulation
  
  !==================================================================================================
  function get_reference_fe_geo_order(this)
    implicit none
    class(par_test_poisson_error_estimator_params_t) , intent(in) :: this
    integer(ip) :: get_reference_fe_geo_order
    get_reference_fe_geo_order = this%reference_fe_geo_order
  end function get_reference_fe_geo_order
  
  !==================================================================================================
  function get_reference_fe_order(this)
    implicit none
    class(par_test_poisson_error_estimator_params_t) , intent(in) :: this
    integer(ip) :: get_reference_fe_order
    get_reference_fe_order = this%reference_fe_order
  end function get_reference_fe_order
  
  !==================================================================================================
  function get_write_solution(this)
    implicit none
    class(par_test_poisson_error_estimator_params_t) , intent(in) :: this
    logical :: get_write_solution
    get_write_solution = this%write_solution
  end function get_write_solution
  
  !==================================================================================================
  function get_laplacian_type(this)
    implicit none
    class(par_test_poisson_error_estimator_params_t) , intent(in) :: this
    character(len=:), allocatable :: get_laplacian_type
    get_laplacian_type = trim(this%laplacian_type)
  end function get_laplacian_type 

  !==================================================================================================
  function get_triangulation_type(this)
    implicit none
    class(par_test_poisson_error_estimator_params_t) , intent(in) :: this
    character(len=:), allocatable :: get_triangulation_type
    get_triangulation_type = trim(this%triangulation_type)
  end function get_triangulation_type 
  
  !==================================================================================================
  function get_num_dims(this)
    implicit none
    class(par_test_poisson_error_estimator_params_t) , intent(in) :: this
    integer(ip) :: get_num_dims
    get_num_dims = this%num_dims
  end function get_num_dims
  
  !==================================================================================================
  function get_use_void_fes(this)
    implicit none
    class(par_test_poisson_error_estimator_params_t) , intent(in) :: this
    logical :: get_use_void_fes
    get_use_void_fes = this%use_void_fes
  end function get_use_void_fes

  !==================================================================================================
  function get_use_void_fes_case(this)
    implicit none
    class(par_test_poisson_error_estimator_params_t) , intent(in) :: this
    character(len=:), allocatable :: get_use_void_fes_case
    get_use_void_fes_case = trim(this%use_void_fes_case)
  end function get_use_void_fes_case
  
  !==================================================================================================
  function get_refinement_strategy(this)
    implicit none
    class(par_test_poisson_error_estimator_params_t) , intent(in) :: this
    character(len=:), allocatable :: get_refinement_strategy
    get_refinement_strategy = trim(this%refinement_strategy)
  end function get_refinement_strategy 
  
  !==================================================================================================
  function get_analytical_functions_type(this)
    implicit none
    class(par_test_poisson_error_estimator_params_t) , intent(in) :: this
    character(len=:), allocatable :: get_analytical_functions_type
    get_analytical_functions_type = trim(this%analytical_functions_type)
  end function get_analytical_functions_type
  
end module par_test_poisson_error_estimator_params_names
