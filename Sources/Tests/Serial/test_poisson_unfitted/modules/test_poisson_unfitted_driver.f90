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
module test_poisson_unfitted_driver_names
  use fempar_names
  use unfitted_triangulations_names
  use unfitted_fe_spaces_names
  use level_set_functions_gallery_names
  use unfitted_vtk_writer_names
  use unfitted_solution_checker_names
  use test_poisson_unfitted_params_names
  use poisson_unfitted_cG_discrete_integration_names
  use poisson_unfitted_dG_discrete_integration_names
  use poisson_unfitted_conditions_names
  use poisson_unfitted_analytical_functions_names
  use uniform_hex_mesh_generator_names

  use vector_poisson_unfitted_discrete_integration_names
  use vector_poisson_unfitted_conditions_names
  use vector_poisson_unfitted_analytical_functions_names
  use piecewise_cell_map_names

# include "debug.i90"

  implicit none
  private

  integer(ip), parameter :: SERIAL_UNF_POISSON_SET_ID_FULL = 1
  integer(ip), parameter :: SERIAL_UNF_POISSON_SET_ID_VOID = 2

  type test_poisson_unfitted_driver_t
     private

     ! Place-holder for parameter-value set provided through command-line interface
     type(test_poisson_unfitted_params_t)   :: test_params

     ! Cells and lower dimension objects container
     type(serial_unfitted_triangulation_t)              :: triangulation
     integer(ip), allocatable                  :: cell_set_ids(:)

     ! Level set funciton describing the gemetry
     class(level_set_function_t), allocatable :: level_set_function

     ! Discrete weak problem integration-related data type instances
     type(serial_unfitted_fe_space_t)             :: fe_space
     type(p_reference_fe_t), allocatable          :: reference_fes(:)
     type(poisson_unfitted_cG_discrete_integration_t)      :: poisson_unfitted_cG_integration
     type(poisson_unfitted_dG_discrete_integration_t)      :: poisson_unfitted_dG_integration
     type(poisson_unfitted_conditions_t)                   :: poisson_unfitted_conditions
     type(poisson_unfitted_analytical_functions_t)         :: poisson_unfitted_analytical_functions

     type(vector_poisson_unfitted_discrete_integration_t)  :: vector_poisson_unfitted_integration
     type(vector_poisson_unfitted_analytical_functions_t)  :: vector_poisson_unfitted_analytical_functions
     type(vector_poisson_unfitted_conditions_t)            :: vector_poisson_unfitted_conditions

     ! Place-holder for the coefficient matrix and RHS of the linear system
     type(fe_affine_operator_t)                   :: fe_affine_operator

     ! Direct and Iterative linear solvers data type
     type(environment_t)                       :: serial_environment
#ifdef ENABLE_MKL
     type(direct_solver_t)                     :: direct_solver
#else
     type(iterative_linear_solver_t)           :: iterative_linear_solver
#endif

     ! poisson_unfitted problem solution FE function
     type(fe_function_t)                       :: solution
   contains
     procedure                  :: run_simulation
     procedure                  :: parse_command_line_parameters
     procedure                  :: setup_environment
     procedure                  :: free_environment
     procedure        , private :: setup_levelset
     procedure        , private :: setup_triangulation
     procedure        , private :: setup_reference_fes
     procedure        , private :: setup_fe_space
     procedure        , private :: setup_system
     procedure        , private :: setup_solver
     procedure        , private :: assemble_system
     procedure        , private :: solve_system
     procedure        , private :: check_solution
     procedure        , private :: check_solution_vector
     procedure        , private :: write_solution
     procedure        , private :: compute_domain_volume
     procedure        , private :: compute_domain_surface
     procedure        , private :: compute_fitted_boundary_surface
     procedure        , private :: free
  end type test_poisson_unfitted_driver_t

  ! Types
  public :: test_poisson_unfitted_driver_t

contains

  subroutine parse_command_line_parameters(this)
    implicit none
    class(test_poisson_unfitted_driver_t ), intent(inout) :: this
    call this%test_params%process_parameters()
  end subroutine parse_command_line_parameters
  
  subroutine setup_environment(this, world_context)
    implicit none
    class(test_poisson_unfitted_driver_t ), intent(inout) :: this
    class(execution_context_t)  , intent(in)    :: world_context
    integer(ip) :: ierr
    call this%serial_environment%create(world_context, this%test_params%get_parameter_list())
  end subroutine setup_environment
  
  subroutine free_environment(this)
    implicit none
    class(test_poisson_unfitted_driver_t ), intent(inout) :: this
    call this%serial_environment%free()
  end subroutine free_environment

  subroutine setup_levelset(this)
    implicit none
    class(test_poisson_unfitted_driver_t ), target, intent(inout) :: this

    integer(ip) :: num_dims
    integer(ip) :: istat
    class(level_set_function_t), pointer :: levset
    real(rp) :: dom3d(6)

    ! Get number of dimensions form input
    num_dims = this%test_params%get_num_dims()

    !TODO we assume it is a sphere
    select case ('sphere')
      case ('sphere')
        allocate( level_set_sphere_t:: this%level_set_function, stat= istat ); check(istat==0)
      case ('cylinder')
        allocate( level_set_cylinder_t:: this%level_set_function, stat= istat ); check(istat==0)
      case ('cheese_block')
        allocate( level_set_cheese_block_t:: this%level_set_function, stat= istat ); check(istat==0)
      case default
        check(.false.)
    end select

    ! Set options of the base class
    call this%level_set_function%set_num_dims(num_dims)
    call this%level_set_function%set_tolerance(1.0e-6)

    ! Set options of the derived classes
    levset => this%level_set_function
    select type ( levset )
      class is (level_set_sphere_t)
        call levset%set_radius( 0.9_rp )
        call levset%set_center([0.0_rp,0.0_rp,0.0_rp])
      class default
        check(.false.)
    end select

  end subroutine setup_levelset

  subroutine setup_triangulation(this)
    implicit none
    class(test_poisson_unfitted_driver_t), intent(inout) :: this

    class(vef_iterator_t), allocatable  :: vef
    class(cell_iterator_t), allocatable :: cell
    type(point_t), allocatable :: cell_coords(:)
    integer(ip) :: istat
    integer(ip) :: set_id
    real(rp) :: x, y
    integer(ip) :: num_void_neigs

    call this%triangulation%create(this%test_params%get_parameter_list(),this%level_set_function,this%serial_environment)

    ! Set the cell ids
    call memalloc(this%triangulation%get_num_local_cells(),this%cell_set_ids)
    call this%triangulation%create_cell_iterator(cell)
    do while( .not. cell%has_finished() )
      if (cell%is_exterior()) then
        set_id = SERIAL_UNF_POISSON_SET_ID_VOID
      else
        set_id = SERIAL_UNF_POISSON_SET_ID_FULL
      end if
      this%cell_set_ids(cell%get_gid()) = set_id
      call cell%next()
    end do
    call this%triangulation%fill_cells_set(this%cell_set_ids)
    call this%triangulation%free_cell_iterator(cell)
    
       call this%triangulation%create_vef_iterator(vef)
       do while ( .not. vef%has_finished() )
          if(vef%is_at_boundary()) then
             call vef%set_set_id(1)
          else
             call vef%set_set_id(0)
          end if
          call vef%next()
       end do
       call this%triangulation%free_vef_iterator(vef)
    !end if

  end subroutine setup_triangulation

  subroutine setup_reference_fes(this)
    implicit none
    class(test_poisson_unfitted_driver_t), intent(inout) :: this
    !
    !type(polytope_tree_t) :: poly, poly_old
    !integer(ip) :: topology

    ! Locals
    integer(ip) :: istat
    logical                                   :: continuity
    class(cell_iterator_t), allocatable       :: cell
    class(reference_fe_t), pointer :: reference_fe_geo
    character(:), allocatable :: field_type


    allocate(this%reference_fes(2), stat=istat)
    check(istat==0)

    continuity = .true.
    if ( trim(this%test_params%get_fe_formulation()) == 'dG' ) then
      continuity = .false.
    end if

    field_type = field_type_scalar
    if ( trim(this%test_params%get_laplacian_type()) == 'vector' ) then
      field_type = field_type_vector
    end if

    call this%triangulation%create_cell_iterator(cell)
    reference_fe_geo => cell%get_reference_fe()



    ! BEGIN Checking new polytope_tree_t
    !if ( reference_fe_geo%get_topology() == topology_hex ) then
    ! topology = 2**this%triangulation%get_num_dims()-1
    !elseif ( reference_fe_geo%get_topology() == topology_tet ) then
    ! topology = 0
    !end if
    !call poly_old%create_old(this%triangulation%get_num_dims(), topology )
    !call poly%create(this%triangulation%get_num_dims(), topology )
    !call poly_old%print()
    !call poly%print()
    ! END Checking ...

    this%reference_fes(SERIAL_UNF_POISSON_SET_ID_FULL) =  make_reference_fe ( topology = reference_fe_geo%get_topology(), &
                                                 fe_type = fe_type_lagrangian, &
                                                 num_dims = this%triangulation%get_num_dims(), &
                                                 order = this%test_params%get_reference_fe_order(), &
                                                 field_type = field_type, &
                                                 conformity = .true., &
                                                 continuity = continuity )

    this%reference_fes(SERIAL_UNF_POISSON_SET_ID_VOID) =  make_reference_fe ( topology = reference_fe_geo%get_topology(), &
                                                 fe_type = fe_type_void, &
                                                 num_dims = this%triangulation%get_num_dims(), &
                                                 order = -1, & ! this%test_params%get_reference_fe_order(), & 
                                                 field_type = field_type, &
                                                 conformity = .true., &
                                                 continuity = continuity ) 
    call this%triangulation%free_cell_iterator(cell)
  end subroutine setup_reference_fes

  subroutine setup_fe_space(this)
    implicit none
    class(test_poisson_unfitted_driver_t), intent(inout) :: this

    integer(ip) :: set_ids_to_reference_fes(1,2)

    set_ids_to_reference_fes(1,SERIAL_UNF_POISSON_SET_ID_FULL) = SERIAL_UNF_POISSON_SET_ID_FULL
    set_ids_to_reference_fes(1,SERIAL_UNF_POISSON_SET_ID_VOID) = SERIAL_UNF_POISSON_SET_ID_VOID

    if ( this%test_params%get_laplacian_type() == 'scalar' ) then
      call this%poisson_unfitted_analytical_functions%set_num_dims(this%triangulation%get_num_dims())
      call this%poisson_unfitted_analytical_functions%set_is_in_fe_space(this%test_params%is_in_fe_space())
      call this%poisson_unfitted_analytical_functions%set_degree(this%test_params%get_reference_fe_order())
      call this%poisson_unfitted_conditions%set_boundary_function(this%poisson_unfitted_analytical_functions%get_boundary_function())
      if (this%test_params%get_fe_formulation() == 'cG') then
        call this%fe_space%set_use_constraints(this%test_params%get_use_constraints())
        call this%fe_space%create( triangulation            = this%triangulation, &
                                   reference_fes            = this%reference_fes, &
                                   set_ids_to_reference_fes = set_ids_to_reference_fes, &
                                   conditions               = this%poisson_unfitted_conditions )
      else 
        mcheck(.false.,'Test only runs for continuous Galerkin')
      end if  
    else
      mcheck(.false.,'Test only runs for Scalar Problems')
    end if

    call this%fe_space%set_up_cell_integration()

  end subroutine setup_fe_space

  subroutine setup_system (this)
    implicit none
    class(test_poisson_unfitted_driver_t), intent(inout) :: this
    if ( this%test_params%get_laplacian_type() == 'scalar' ) then    
      if ( this%test_params%get_fe_formulation() == 'cG' ) then
         call this%poisson_unfitted_cG_integration%set_analytical_functions(this%poisson_unfitted_analytical_functions)
         call this%fe_affine_operator%create ( sparse_matrix_storage_format      = csr_format, &
                                               diagonal_blocks_symmetric_storage = [ .true. ], &
                                               diagonal_blocks_symmetric         = [ .true. ], &
                                               diagonal_blocks_sign              = [ SPARSE_MATRIX_SIGN_POSITIVE_DEFINITE ], &
                                               fe_space                          = this%fe_space, &
                                               discrete_integration              = this%poisson_unfitted_cG_integration )
      else
         mcheck(.false.,'Test only runs for continuous Galerkin')
      end if
    else
        mcheck(.false.,'Test only runs for Scalar Problems')
    end if
    call this%solution%create(this%fe_space)
    call this%fe_space%interpolate_dirichlet_values(this%solution)
    call this%poisson_unfitted_cG_integration%set_fe_function(this%solution)
  end subroutine setup_system

  subroutine setup_solver (this)
    implicit none
    class(test_poisson_unfitted_driver_t), intent(inout) :: this
    integer :: FPLError
    type(parameterlist_t) :: parameter_list
    integer :: iparm(64)
    class(matrix_t), pointer       :: matrix

    call parameter_list%init()
#ifdef ENABLE_MKL
    FPLError = parameter_list%set(key = dls_type_key,        value = pardiso_mkl)
    FPLError = FPLError + parameter_list%set(key = pardiso_mkl_matrix_type,   value = pardiso_mkl_spd)
    FPLError = FPLError + parameter_list%set(key = pardiso_mkl_message_level, value = 0)
    iparm = 0
    FPLError = FPLError + parameter_list%set(key = pardiso_mkl_iparm,         value = iparm)
    assert(FPLError == 0)

    call this%direct_solver%set_type_from_pl(parameter_list)
    call this%direct_solver%set_parameters_from_pl(parameter_list)

    matrix => this%fe_affine_operator%get_matrix()
    select type(matrix)
    class is (sparse_matrix_t)
       call this%direct_solver%set_matrix(matrix)
    class DEFAULT
       assert(.false.)
    end select
#else
    FPLError = parameter_list%set(key = ils_rtol_key, value = 1.0e-12_rp)
    !FPLError = FPLError + parameter_list%set(key = ils_output_frequency, value = 30)
    FPLError = parameter_list%set(key = ils_max_num_iterations_key, value = 5000)
    assert(FPLError == 0)
    call this%iterative_linear_solver%create(this%fe_space%get_environment())
    call this%iterative_linear_solver%set_type_from_string(cg_name)
    call this%iterative_linear_solver%set_parameters_from_pl(parameter_list)
    call this%iterative_linear_solver%set_operators(this%fe_affine_operator%get_tangent(), .identity. this%fe_affine_operator)
#endif
    call parameter_list%free()
  end subroutine setup_solver

  subroutine assemble_system (this)
    implicit none
    class(test_poisson_unfitted_driver_t), intent(inout) :: this
    class(matrix_t)                  , pointer       :: matrix
    class(vector_t)                  , pointer       :: rhs
    integer(ip) :: iounit
    call this%fe_affine_operator%compute()
    rhs                => this%fe_affine_operator%get_translation()
    matrix             => this%fe_affine_operator%get_matrix()

    select type(matrix)
    class is (sparse_matrix_t)
       !iounit = io_open(file='matrix.mm',action='write')
       !check(iounit>0)
       !call matrix%print_matrix_market(iounit)
    class DEFAULT
       assert(.false.)
    end select

    select type(rhs)
    class is (serial_scalar_array_t)
      !iounit = io_open(file='vector.mm',action='write')
      !check(iounit>0)
      !call rhs%print(iounit)
    class DEFAULT
       assert(.false.)
    end select
  end subroutine assemble_system


  subroutine solve_system(this)
    implicit none
    class(test_poisson_unfitted_driver_t), intent(inout) :: this
    class(matrix_t)                         , pointer       :: matrix
    class(vector_t)                         , pointer       :: rhs
    class(vector_t)                         , pointer       :: dof_values

    matrix     => this%fe_affine_operator%get_matrix()
    rhs        => this%fe_affine_operator%get_translation()
    dof_values => this%solution%get_free_dof_values()

#ifdef ENABLE_MKL
    call this%direct_solver%solve(this%fe_affine_operator%get_translation(), dof_values)
#else
    call this%iterative_linear_solver%solve(this%fe_affine_operator%get_translation(), &
                                            dof_values)
#endif
    call this%fe_space%update_hanging_dof_values(this%solution)
    !select type (dof_values)
    !class is (serial_scalar_array_t)
    !   call dof_values%print(6)
    !class DEFAULT
    !   assert(.false.)
    !end select

    !select type (matrix)
    !class is (sparse_matrix_t)
    !   call this%direct_solver%update_matrix(matrix, same_nonzero_pattern=.true.)
    !   call this%direct_solver%solve(rhs , dof_values )
    !class DEFAULT
    !   assert(.false.)
    !end select
  end subroutine solve_system

  subroutine check_solution(this)
    implicit none
    class(test_poisson_unfitted_driver_t), intent(inout) :: this

    type(unfitted_solution_checker_t) :: solution_checker
    real(rp) :: error_h1_semi_norm
    real(rp) :: error_l2_norm
    real(rp) :: h1_semi_norm
    real(rp) :: l2_norm
    real(rp) :: error_tolerance, tol

    call solution_checker%create(this%fe_space,this%solution,this%poisson_unfitted_analytical_functions%get_solution_function())
    call solution_checker%compute_error_norms(error_h1_semi_norm,error_l2_norm,h1_semi_norm,l2_norm)
    call solution_checker%free()

    write(*,'(a,e32.25)') 'l2_norm:               ', l2_norm
    write(*,'(a,e32.25)') 'h1_semi_norm:          ', h1_semi_norm
    write(*,'(a,e32.25)') 'error_l2_norm:         ', error_l2_norm
    write(*,'(a,e32.25)') 'error_h1_semi_norm:    ', error_h1_semi_norm
    write(*,'(a,e32.25)') 'rel_error_l2_norm:     ', error_l2_norm/l2_norm
    write(*,'(a,e32.25)') 'rel_error_h1_semi_norm:', error_h1_semi_norm/h1_semi_norm

#ifdef ENABLE_MKL
    error_tolerance = 1.0e-08
#else
    error_tolerance = 1.0e-06
#endif

    if ( this%test_params%are_checks_active() ) then
      tol = error_tolerance*l2_norm
      check( error_l2_norm < tol )
      tol = error_tolerance*h1_semi_norm
      check( error_h1_semi_norm < tol )
    end if

    !type(error_norms_scalar_t) :: error_norm
    !real(rp) :: mean, l1, l2, lp, linfty, h1, h1_s, w1p_s, w1p, w1infty_s, w1infty
    !real(rp) :: error_tolerance
    !
    !call error_norm%create(this%fe_space,1)
    !mean = error_norm%compute(this%poisson_unfitted_analytical_functions%get_solution_function(), this%solution, mean_norm)
    !l1 = error_norm%compute(this%poisson_unfitted_analytical_functions%get_solution_function(), this%solution, l1_norm)
    !l2 = error_norm%compute(this%poisson_unfitted_analytical_functions%get_solution_function(), this%solution, l2_norm)
    !lp = error_norm%compute(this%poisson_unfitted_analytical_functions%get_solution_function(), this%solution, lp_norm)
    !linfty = error_norm%compute(this%poisson_unfitted_analytical_functions%get_solution_function(), this%solution, linfty_norm)
    !h1_s = error_norm%compute(this%poisson_unfitted_analytical_functions%get_solution_function(), this%solution, h1_seminorm)
    !h1 = error_norm%compute(this%poisson_unfitted_analytical_functions%get_solution_function(), this%solution, h1_norm)
    !w1p_s = error_norm%compute(this%poisson_unfitted_analytical_functions%get_solution_function(), this%solution, w1p_seminorm)
    !w1p = error_norm%compute(this%poisson_unfitted_analytical_functions%get_solution_function(), this%solution, w1p_norm)
    !w1infty_s = error_norm%compute(this%poisson_unfitted_analytical_functions%get_solution_function(), this%solution, w1infty_seminorm)
    !w1infty = error_norm%compute(this%poisson_unfitted_analytical_functions%get_solution_function(), this%solution, w1infty_norm)

#ifdef ENABLE_MKL
    !error_tolerance = 1.0e-08
#else
    !error_tolerance = 1.0e-06
#endif
    !
    !write(*,'(a20,e32.25)') 'mean_norm:', mean; check ( abs(mean) < error_tolerance )
    !write(*,'(a20,e32.25)') 'l1_norm:', l1; check ( l1 < error_tolerance )
    !write(*,'(a20,e32.25)') 'l2_norm:', l2; check ( l2 < error_tolerance )
    !write(*,'(a20,e32.25)') 'lp_norm:', lp; check ( lp < error_tolerance )
    !write(*,'(a20,e32.25)') 'linfnty_norm:', linfty; check ( linfty < error_tolerance )
    !write(*,'(a20,e32.25)') 'h1_seminorm:', h1_s; check ( h1_s < error_tolerance )
    !write(*,'(a20,e32.25)') 'h1_norm:', h1; check ( h1 < error_tolerance )
    !write(*,'(a20,e32.25)') 'w1p_seminorm:', w1p_s; check ( w1p_s < error_tolerance )
    !write(*,'(a20,e32.25)') 'w1p_norm:', w1p; check ( w1p < error_tolerance )
    !write(*,'(a20,e32.25)') 'w1infty_seminorm:', w1infty_s; check ( w1infty_s < error_tolerance )
    !write(*,'(a20,e32.25)') 'w1infty_norm:', w1infty; check ( w1infty < error_tolerance )
    !call error_norm%free()
  end subroutine check_solution

  subroutine check_solution_vector(this)
    implicit none
    class(test_poisson_unfitted_driver_t), intent(inout) :: this
    type(error_norms_vector_t) :: error_norm
    real(rp) :: mean, l1, l2, lp, linfty, h1, h1_s, w1p_s, w1p, w1infty_s, w1infty
    real(rp) :: error_tolerance

    call error_norm%create(this%fe_space,1)
    mean = error_norm%compute(this%vector_poisson_unfitted_analytical_functions%get_solution_function(), this%solution, mean_norm)
    l1 = error_norm%compute(this%vector_poisson_unfitted_analytical_functions%get_solution_function(), this%solution, l1_norm)
    l2 = error_norm%compute(this%vector_poisson_unfitted_analytical_functions%get_solution_function(), this%solution, l2_norm)
    lp = error_norm%compute(this%vector_poisson_unfitted_analytical_functions%get_solution_function(), this%solution, lp_norm)
    linfty = error_norm%compute(this%vector_poisson_unfitted_analytical_functions%get_solution_function(), this%solution, linfty_norm)
    h1_s = error_norm%compute(this%vector_poisson_unfitted_analytical_functions%get_solution_function(), this%solution, h1_seminorm)
    h1 = error_norm%compute(this%vector_poisson_unfitted_analytical_functions%get_solution_function(), this%solution, h1_norm)
    w1p_s = error_norm%compute(this%vector_poisson_unfitted_analytical_functions%get_solution_function(), this%solution, w1p_seminorm)
    w1p = error_norm%compute(this%vector_poisson_unfitted_analytical_functions%get_solution_function(), this%solution, w1p_norm)
    w1infty_s = error_norm%compute(this%vector_poisson_unfitted_analytical_functions%get_solution_function(), this%solution, w1infty_seminorm)
    w1infty = error_norm%compute(this%vector_poisson_unfitted_analytical_functions%get_solution_function(), this%solution, w1infty_norm)

#ifdef ENABLE_MKL
    error_tolerance = 1.0e-08
#else
    error_tolerance = 1.0e-06
#endif

    write(*,'(a20,e32.25)') 'mean_norm:', mean; check ( abs(mean) < error_tolerance )
    write(*,'(a20,e32.25)') 'l1_norm:', l1; check ( l1 < error_tolerance )
    write(*,'(a20,e32.25)') 'l2_norm:', l2; check ( l2 < error_tolerance )
    write(*,'(a20,e32.25)') 'lp_norm:', lp; check ( lp < error_tolerance )
    write(*,'(a20,e32.25)') 'linfnty_norm:', linfty; check ( linfty < error_tolerance )
    write(*,'(a20,e32.25)') 'h1_seminorm:', h1_s; check ( h1_s < error_tolerance )
    write(*,'(a20,e32.25)') 'h1_norm:', h1; check ( h1 < error_tolerance )
    write(*,'(a20,e32.25)') 'w1p_seminorm:', w1p_s; check ( w1p_s < error_tolerance )
    write(*,'(a20,e32.25)') 'w1p_norm:', w1p; check ( w1p < error_tolerance )
    write(*,'(a20,e32.25)') 'w1infty_seminorm:', w1infty_s; check ( w1infty_s < error_tolerance )
    write(*,'(a20,e32.25)') 'w1infty_norm:', w1infty; check ( w1infty < error_tolerance )
    call error_norm%free()
  end subroutine check_solution_vector


  subroutine write_solution(this)
    implicit none
    class(test_poisson_unfitted_driver_t), target, intent(inout) :: this

    type(unfitted_vtk_writer_t) :: vtk_writer
    class(serial_fe_space_t), pointer :: fe_space_ptr
    class(scalar_function_t), pointer :: scal_fun
    integer(ip) :: fieldid

    if(this%test_params%get_write_solution()) then

      fieldid = 1
      fe_space_ptr => this%fe_space
      scal_fun => this%poisson_unfitted_analytical_functions%get_solution_function()
      !call this%solution%interpolate_function(fe_space_ptr,fieldid,scal_fun)

      call vtk_writer%attach_triangulation(this%triangulation)
      call vtk_writer%write_to_vtk_file('out_mesh.vtu')
      call vtk_writer%free()

      call vtk_writer%attach_fe_function(this%solution,this%fe_space)
      call vtk_writer%write_to_vtk_file('out_mesh_solution.vtu')
      call vtk_writer%free()
      
      call vtk_writer%attach_boundary_faces(this%triangulation)
      call vtk_writer%write_to_vtk_file('out_mesh_boundary.vtu')
      call vtk_writer%free()
      
      call vtk_writer%attach_boundary_quadrature_points(this%fe_space)
      call vtk_writer%write_to_vtk_file('out_mesh_boundary_normals.vtu')
      call vtk_writer%free()
      
      call vtk_writer%attach_fitted_faces(this%triangulation)
      call vtk_writer%write_to_vtk_file('out_mesh_facets.vtu')
      call vtk_writer%free()

      call vtk_writer%attach_vefs(this%triangulation)
      call vtk_writer%write_to_vtk_file('out_mesh_vefs.vtu')
      call vtk_writer%free()
      
      call vtk_writer%attach_facets_quadrature_points(this%fe_space)
      call vtk_writer%write_to_vtk_file('out_mesh_fitted_facets_boundary_normals.vtu')
      call vtk_writer%free()

    end if

    !type(output_handler_t)                   :: oh
    !character(len=:), allocatable            :: path
    !character(len=:), allocatable            :: prefix
    !if(this%test_params%get_write_solution()) then
    !    path = this%test_params%get_dir_path_out()
    !    prefix = this%test_params%get_prefix()
    !    call oh%create()
    !    call oh%attach_fe_space(this%fe_space)
    !    call oh%add_fe_function(this%solution, 1, 'solution')
    !    call oh%add_fe_function(this%solution, 1, 'grad_solution', grad_diff_operator)
    !    call oh%open(path, prefix)
    !    call oh%write()
    !    call oh%close()
    !    call oh%free()
    !endif


  end subroutine write_solution

  subroutine run_simulation(this)
    implicit none
    class(test_poisson_unfitted_driver_t), intent(inout) :: this
    call this%free()
    call this%setup_levelset()
    call this%setup_triangulation()
    call this%setup_reference_fes()
    call this%setup_fe_space()
    call this%compute_domain_volume()
    call this%compute_domain_surface()
    call this%compute_fitted_boundary_surface()
    call this%setup_system()
    call this%assemble_system()
    call this%setup_solver()
    call this%solve_system()
    call this%check_solution()
    !if ( trim(this%test_params%get_laplacian_type()) == 'scalar' ) then
    !  call this%check_solution()
    !else
    !  call this%check_solution_vector()
    !end if
    call this%write_solution()
    call this%free()
  end subroutine run_simulation

subroutine compute_domain_volume( this )

    implicit none
    class(test_poisson_unfitted_driver_t), intent(in) :: this

    class(fe_cell_iterator_t), allocatable :: fe
    real(rp) :: volume, dV
    type(quadrature_t), pointer :: quadrature
    integer(ip) :: qpoint, num_quad_points
    type(point_t), pointer :: quadrature_points_coordinates(:)

    write(*,*) "Computing domain volume ..."

    call this%fe_space%create_fe_cell_iterator(fe)

    volume = 0.0_rp
    do while ( .not. fe%has_finished() )

       ! Update FE-integration related data structures
       call fe%update_integration()

       ! As the quadrature changes elem by elem, this has to be inside the loop
       quadrature => fe%get_quadrature()
       num_quad_points = quadrature%get_num_quadrature_points()

       ! Physical coordinates of the quadrature points
       quadrature_points_coordinates => fe%get_quadrature_points_coordinates()

       ! Integrate!
       do qpoint = 1, num_quad_points
         dV = fe%get_det_jacobian(qpoint) * quadrature%get_weight(qpoint)
         volume = volume + dV
       end do

       call fe%next()
    end do

    call this%fe_space%free_fe_cell_iterator(fe)

    write(*,*) "Computing domain volume ... OK"
    write(*,*) "Domain volume   = ", volume

end subroutine compute_domain_volume

subroutine compute_domain_surface( this )

    implicit none
    class(test_poisson_unfitted_driver_t), intent(in) :: this

    class(unfitted_fe_cell_iterator_t), pointer :: fe
    class(fe_cell_iterator_t), allocatable, target :: fe_std
    real(rp) :: surface, dS
    type(quadrature_t), pointer :: quadrature
    type(piecewise_cell_map_t),     pointer :: cell_map
    integer(ip) :: qpoint, num_quad_points
    type(point_t), pointer :: quadrature_points_coordinates(:)

    write(*,*) "Computing domain surface..."

    call this%fe_space%create_fe_cell_iterator(fe_std)
    
    select type (fe_std)
    class is (unfitted_fe_cell_iterator_t)
      fe => fe_std
    class default
      check(.false.)
    end select

    surface = 0.0_rp
    do while ( .not. fe%has_finished() )
       if ( fe%is_cut() ) then
          ! Update FE-integration related data structures
          call fe%update_boundary_integration()

          ! As the quadrature changes elem by elem, this has to be inside the loop
          quadrature => fe%get_boundary_quadrature()
          num_quad_points = quadrature%get_num_quadrature_points()
          cell_map => fe%get_boundary_piecewise_cell_map()

          ! Physical coordinates of the quadrature points
          quadrature_points_coordinates => cell_map%get_quadrature_points_coordinates()

          ! Integrate!
          do qpoint = 1, num_quad_points
            dS = cell_map%get_det_jacobian(qpoint) * quadrature%get_weight(qpoint)
            surface = surface + dS !quadrature_points_coordinates(qpoint)%get(1)*quadrature_points_coordinates(qpoint)%get(2)*dS
          end do
       end if
       call fe%next()
    end do

    call this%fe_space%free_fe_cell_iterator(fe_std)

    write(*,*) "Computing domain surface ... OK"
    write(*,*) "Domain surface = ", surface

end subroutine compute_domain_surface

subroutine compute_fitted_boundary_surface( this )

    implicit none
    class(test_poisson_unfitted_driver_t), intent(inout) :: this

    class(fe_facet_iterator_t),allocatable :: fe_facet
    type(quadrature_t), pointer :: quadrature
    integer(ip) :: qpoint, num_quad_points
    real(rp) :: dS, surface

    write(*,*) "Computing fitted boundary surface..."
    call this%fe_space%set_up_facet_integration()
    surface = 0.0_rp
    call this%fe_space%create_fe_facet_iterator(fe_facet)
    do while ( .not. fe_facet%has_finished() )

       if ( fe_facet%is_ghost() .or. (.not. fe_facet%is_at_boundary()) ) then
         call fe_facet%next(); cycle
       end if

       call fe_facet%update_integration()

       quadrature => fe_facet%get_quadrature()
       num_quad_points = quadrature%get_num_quadrature_points()
       do qpoint = 1, num_quad_points
         dS =  fe_facet%get_det_jacobian(qpoint)*quadrature%get_weight(qpoint)
         surface = surface + dS
       end do

       call fe_facet%next()
    end do

    write(*,*) "Computing fitted boundary surface... OK"
    write(*,*) "Fitted boundary surface = ", surface
    if (this%triangulation%get_num_dims()==2) then
      check(abs(surface-1.8_rp)<1.0e-10)
    end if

    call this%fe_space%free_fe_facet_iterator(fe_facet)

end subroutine compute_fitted_boundary_surface


  subroutine free(this)
    implicit none
    class(test_poisson_unfitted_driver_t), intent(inout) :: this
    integer(ip) :: i, istat

    call this%solution%free()

#ifdef ENABLE_MKL
    call this%direct_solver%free()
#else
    call this%iterative_linear_solver%free()
#endif

    call this%fe_affine_operator%free()
    call this%fe_space%free()
    if ( allocated(this%reference_fes) ) then
      do i=1, size(this%reference_fes)
        call this%reference_fes(i)%p%free()
      end do
      deallocate(this%reference_fes, stat=istat)
      check(istat==0)
    end if
    call this%triangulation%free()
    if ( allocated(this%level_set_function) ) then
      deallocate( this%level_set_function, stat=istat ); check(istat == 0)
    end if
    if (allocated(this%cell_set_ids)) call memfree(this%cell_set_ids,__FILE__,__LINE__)
  end subroutine free

end module test_poisson_unfitted_driver_names
