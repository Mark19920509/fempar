module par_test_h_adaptive_poisson_params_names
  use fempar_names

  implicit none
#include "debug.i90" 
  private
  
  character(len=*), parameter :: even_cells     = 'even_cells'       
  character(len=*), parameter :: inner_region   = 'inner_region' 
  character(len=*), parameter :: uniform        = 'uniform' 
  
  character(len=*), parameter :: reference_fe_geo_order_key     = 'reference_fe_geo_order'
  character(len=*), parameter :: reference_fe_order_key         = 'reference_fe_order'    
  character(len=*), parameter :: write_solution_key             = 'write_solution'        
  character(len=*), parameter :: triangulation_type_key         = 'triangulation_type'
  character(len=*), parameter :: use_void_fes_key               = 'use_void_fes'
  character(len=*), parameter :: use_void_fes_case_key          = 'use_void_fes_case'
  character(len=*), parameter :: coupling_criteria_key          = 'coupling_criteria'
  character(len=*), parameter :: preconditioner_type_key        = 'preconditioner_type'
  
  ! Meshing parameters 
  character(len=*), parameter :: refinement_pattern_case_key   = 'refinement_pattern_case'
  character(len=*), parameter :: domain_limits_key             = 'domain_limits'
  character(len=*), parameter :: inner_region_size_key         = 'inner_region_size '
  character(len=*), parameter :: num_refinements_key           = 'num_refinements'
  character(len=*), parameter :: min_num_refinements_key       = 'min_num_refinements'
  

  type :: par_test_h_adaptive_poisson_params_t
     private
     contains
       procedure, non_overridable             :: process_parameters
       procedure, non_overridable             :: get_parameter_list
       procedure, non_overridable             :: get_dir_path
       procedure, non_overridable             :: get_prefix
       procedure, non_overridable             :: get_reference_fe_geo_order
       procedure, non_overridable             :: get_reference_fe_order
       procedure, non_overridable             :: get_write_solution
       procedure, non_overridable             :: get_triangulation_type
       procedure, non_overridable             :: get_use_void_fes
       procedure, non_overridable             :: get_use_void_fes_case
       procedure, non_overridable             :: get_refinement_pattern_case 
       procedure, non_overridable             :: get_domain_limits
       procedure, non_overridable             :: get_inner_region_size 
       procedure, non_overridable             :: get_num_refinements 
       procedure, non_overridable             :: get_min_num_refinements
       procedure, non_overridable             :: get_subparts_coupling_criteria 
       procedure, non_overridable             :: get_preconditioner_type
       !procedure, non_overridable             :: get_num_dims
  end type par_test_h_adaptive_poisson_params_t

  ! Parameters 
  public :: even_cells, inner_region, uniform   
  
  ! Types
  public :: par_test_h_adaptive_poisson_params_t

contains

  !==================================================================================================
  subroutine par_test_h_adaptive_poisson_params_define_parameters()
    implicit none

    ! Common
    call parameter_handler%add(reference_fe_geo_order_key, '--reference-fe-geo-order', 1, 'Order of the triangulation reference fe', switch_ab='-gorder')
    call parameter_handler%add(reference_fe_order_key, '--reference-fe-order', 1, 'Order of the fe space reference fe', switch_ab='-order')
    call parameter_handler%add(write_solution_key, '--write-solution', .false., 'Write solution in VTK format', switch_ab='-wsolution')

    ! Specific
    call parameter_handler%add(use_void_fes_key, '--use-void-fes', .false., 'Use a hybrid FE space formed by full and void FEs', switch_ab='-use-voids')
    call parameter_handler%add(use_void_fes_case_key, '--use-void-fes-case', 'popcorn', &
                 'Select where to put void fes using one of the predefined patterns. Possible values: `popcorn`, `half`, `quarter`', &
                 switch_ab='-use-voids-case')
    call parameter_handler%add(preconditioner_type_key, '--preconditioner-type', 'mlbddc', &
                'Select preconditioner type. Possible values: `identity`, `jacobi`, `mlbddc`.', &
                switch_ab='-prec-type')
    call parameter_handler%add(refinement_pattern_case_key, '--refinement_pattern_case', inner_region, &
                'Select refinement pattern. Possible values: even_cells, centered_refinement', &
                switch_ab='-refinement-pattern-case' )
    call parameter_handler%add(domain_limits_key, '--domain_limits', [0.0,1.0,0.0,1.0,0.0,1.0], 'Domain limits of the mesh', switch_ab='-dl')
    call parameter_handler%add(inner_region_size_key, '--inner_region_size', [0.1,0.1,0.1], 'Concentric with the domain refined area length)', switch_ab='-ir_size')
    call parameter_handler%add(num_refinements_key, '--num_refinements', 3, 'Number of adaptive mesh refinements from a plain cell', switch_ab='-num_refs')
    call parameter_handler%add(min_num_refinements_key, '--min_num_refinements', 1, 'Minimum number of adaptive mesh refinements for any cell', switch_ab='-min_num_refs')
    call parameter_handler%add(coupling_criteria_key, '--subparts_coupling_criteria', loose_coupling, &
                  'Criteria to decide whether two subparts are connected or not and identify disconnected parts accordingly', &
                  switch_ab='-subparts_coupling')    

  end subroutine par_test_h_adaptive_poisson_params_define_parameters

  !==================================================================================================

  subroutine process_parameters(this)
    implicit none
    class(par_test_h_adaptive_poisson_params_t) , intent(in)  :: this
    call parameter_handler%process_parameters(par_test_h_adaptive_poisson_params_define_parameters)
  end subroutine process_parameters

  !==================================================================================================

  function get_parameter_list(this)
    implicit none
    class(par_test_h_adaptive_poisson_params_t) , intent(in) :: this
    type(ParameterList_t), pointer                      :: get_parameter_list
    get_parameter_list  => parameter_handler%get_values()
  end function get_parameter_list

  ! GETTERS *****************************************************************************************
  function get_dir_path(this)
    implicit none
    class(par_test_h_adaptive_poisson_params_t) , intent(in) :: this
    character(len=:),      allocatable            :: get_dir_path
    type(ParameterList_t), pointer                :: list
    integer(ip)                                   :: error
    list  => parameter_handler%get_values()
    assert(list%isAssignable(dir_path_key, 'string'))
    error = list%GetAsString(key = dir_path_key, string = get_dir_path)
    assert(error==0)
  end function get_dir_path

  !==================================================================================================
  function get_prefix(this)
    implicit none
    class(par_test_h_adaptive_poisson_params_t) , intent(in) :: this
    character(len=:),      allocatable            :: get_prefix
    type(ParameterList_t), pointer                :: list
    integer(ip)                                   :: error
    list  => parameter_handler%get_values()
    assert(list%isAssignable(prefix_key, 'string'))
    error = list%GetAsString(key = prefix_key, string = get_prefix)
    assert(error==0)
  end function get_prefix

    !==================================================================================================
  function get_reference_fe_geo_order(this)
    implicit none
    class(par_test_h_adaptive_poisson_params_t) , intent(in) :: this
    integer(ip)                                   :: get_reference_fe_geo_order
    type(ParameterList_t), pointer                :: list
    integer(ip)                                   :: error
    list  => parameter_handler%get_values()
    assert(list%isAssignable(reference_fe_geo_order_key, get_reference_fe_geo_order))
    error = list%Get(key = reference_fe_geo_order_key, Value = get_reference_fe_geo_order)
    assert(error==0)
  end function get_reference_fe_geo_order
  
  !==================================================================================================
  function get_reference_fe_order(this)
    implicit none
    class(par_test_h_adaptive_poisson_params_t) , intent(in) :: this
    integer(ip)                                   :: get_reference_fe_order
    type(ParameterList_t), pointer                :: list
    integer(ip)                                   :: error
    list  => parameter_handler%get_values()
    assert(list%isAssignable(reference_fe_order_key, get_reference_fe_order))
    error = list%Get(key = reference_fe_order_key, Value = get_reference_fe_order)
    assert(error==0)
  end function get_reference_fe_order
  
  !==================================================================================================
  function get_write_solution(this)
    implicit none
    class(par_test_h_adaptive_poisson_params_t) , intent(in) :: this
    logical                                       :: get_write_solution
    type(ParameterList_t), pointer                :: list
    integer(ip)                                   :: error
    logical                                       :: is_present
    logical                                       :: same_data_type
    integer(ip), allocatable                      :: shape(:)
    list  => parameter_handler%get_values()
    assert(list%isAssignable(write_solution_key, get_write_solution))
    error = list%Get(key = write_solution_key, Value = get_write_solution)
    assert(error==0)
  end function get_write_solution

  !==================================================================================================
  function get_triangulation_type(this)
    implicit none
    class(par_test_h_adaptive_poisson_params_t) , intent(in) :: this
    integer(ip)                                   :: get_triangulation_type
    type(ParameterList_t), pointer                :: list
    integer(ip)                                   :: error
    list  => parameter_handler%get_values()
    assert(list%isAssignable(triang_generate_key, get_triangulation_type))
    error = list%Get(key = triang_generate_key, Value = get_triangulation_type)
    assert(error==0)
  end function get_triangulation_type 

  !==================================================================================================
  function get_use_void_fes(this)
    implicit none
    class(par_test_h_adaptive_poisson_params_t) , intent(in) :: this
    logical                                       :: get_use_void_fes
    type(ParameterList_t), pointer                :: list
    integer(ip)                                   :: error
    list  => parameter_handler%get_values()
    assert(list%isAssignable(use_void_fes_key, get_use_void_fes))
    error = list%Get(key = use_void_fes_key, Value = get_use_void_fes)
    assert(error==0)
  end function get_use_void_fes

  !==================================================================================================
  function get_use_void_fes_case(this)
    implicit none
    class(par_test_h_adaptive_poisson_params_t) , intent(in) :: this
    character(len=:), allocatable                 :: get_use_void_fes_case
    type(ParameterList_t), pointer                :: list
    integer(ip)                                   :: error
    list  => parameter_handler%get_values()
    assert(list%isAssignable(use_void_fes_case_key, 'string'))
    error = list%GetAsString(key = use_void_fes_case_key, string = get_use_void_fes_case)
    assert(error==0)
  end function get_use_void_fes_case
  
    !==================================================================================================
  function get_refinement_pattern_case(this)
    implicit none
    class(par_test_h_adaptive_poisson_params_t) , intent(in) :: this
    character(len=:), allocatable                            :: get_refinement_pattern_case
    type(ParameterList_t), pointer                           :: list
    integer(ip)                                              :: error
    character(1) :: dummy_string
    list  => parameter_handler%get_values()
    assert(list%isAssignable(refinement_pattern_case_key, dummy_string))
    error = list%GetAsString(key = refinement_pattern_case_key, string = get_refinement_pattern_case)
    assert(error==0)
  end function get_refinement_pattern_case
    
  !==================================================================================================
  function get_domain_limits(this)
    implicit none
    class(par_test_h_adaptive_poisson_params_t) , intent(in) :: this
    real(rp)                                  :: get_domain_limits(6)
    type(ParameterList_t), pointer            :: list
    integer(ip)                               :: error
    list  => parameter_handler%get_values()
    assert(list%isAssignable(domain_limits_key, get_domain_limits))
    error = list%Get(key = domain_limits_key, Value = get_domain_limits)
    assert(error==0)
  end function get_domain_limits

  !==================================================================================================
  function get_inner_region_size(this)
    implicit none
    class(par_test_h_adaptive_poisson_params_t) , intent(in) :: this
    real(rp)                                  :: get_inner_region_size(0:SPACE_DIM-1)
    type(ParameterList_t), pointer            :: list
    integer(ip)                               :: error
    list  => parameter_handler%get_values()
    assert(list%isAssignable(inner_region_size_key , get_inner_region_size ))
    error = list%Get(key = inner_region_size_key , Value = get_inner_region_size )
    assert(error==0)
  end function get_inner_region_size

  !==================================================================================================
  function get_num_refinements(this)
    implicit none
    class(par_test_h_adaptive_poisson_params_t) , intent(in) :: this
    integer(ip)                                   :: get_num_refinements
    type(ParameterList_t), pointer                :: list
    integer(ip)                                   :: error
    list  => parameter_handler%get_values()
    assert(list%isAssignable(num_refinements_key, get_num_refinements))
    error = list%Get(key = num_refinements_key, Value = get_num_refinements)
    assert(error==0)
  end function get_num_refinements

  !==================================================================================================
  function get_min_num_refinements(this)
    implicit none
    class(par_test_h_adaptive_poisson_params_t) , intent(in) :: this
    integer(ip)                                   :: get_min_num_refinements
    type(ParameterList_t), pointer                :: list
    integer(ip)                                   :: error
    list  => parameter_handler%get_values()
    assert(list%isAssignable(min_num_refinements_key, get_min_num_refinements))
    error = list%Get(key = min_num_refinements_key, Value = get_min_num_refinements)
    assert(error==0)
  end function get_min_num_refinements
  
  !==================================================================================================
  function get_subparts_coupling_criteria(this)
    implicit none
    class(par_test_h_adaptive_poisson_params_t) , intent(in) :: this
    character(len=:), allocatable                            :: get_subparts_coupling_criteria
    type(ParameterList_t), pointer                           :: list
    integer(ip)                                              :: error
    character(1) :: dummy_string
    list  => parameter_handler%get_values()
    assert(list%isAssignable(coupling_criteria_key, dummy_string))
    error = list%GetAsString(key = coupling_criteria_key, string = get_subparts_coupling_criteria)
    assert(error==0)
  end function get_subparts_coupling_criteria

  !==================================================================================================
  function get_preconditioner_type(this)
    implicit none
    class(par_test_h_adaptive_poisson_params_t) , intent(in) :: this
    character(len=:), allocatable                            :: get_preconditioner_type
    type(ParameterList_t), pointer                           :: list
    integer(ip)                                              :: error
    list  => parameter_handler%get_values()
    assert(list%isAssignable(preconditioner_type_key, 'string'))
    error = list%GetAsString(key = preconditioner_type_key, string = get_preconditioner_type)
    assert(error==0)
  end function get_preconditioner_type
  
end module par_test_h_adaptive_poisson_params_names
