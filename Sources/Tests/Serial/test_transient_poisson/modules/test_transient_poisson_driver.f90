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
module test_transient_poisson_driver_names
  use fempar_names
  use test_transient_poisson_params_names
  use poisson_cG_discrete_integration_names
  use mass_discrete_integration_names
  use poisson_conditions_names
  use poisson_analytical_functions_names
  use time_stepping_names
  use nonlinear_solver_names
 
  
# include "debug.i90"

  implicit none
  private
  
  type test_transient_poisson_driver_t 
     private 
     
     ! Place-holder for parameter-value set provided through command-line interface
     type(test_transient_poisson_params_t)   :: test_params
     type(ParameterList_t)         :: parameter_list
     
     ! Cells and lower dimension objects container
     type(serial_triangulation_t)              :: triangulation
     integer(ip), allocatable                  :: cell_set_ids(:)
     
     ! Discrete weak problem integration-related data type instances 
     type(serial_fe_space_t)                      :: fe_space 
     type(p_reference_fe_t), allocatable          :: reference_fes(:) 
     type(poisson_cG_discrete_integration_t)      :: poisson_cG_integration
     type(mass_discrete_integration_t)            :: mass_integration
     type(poisson_conditions_t)                   :: poisson_conditions
     type(poisson_analytical_functions_t)         :: poisson_analytical_functions
          
     ! Place-holder for the coefficient matrix and RHS of the linear system
     type(fe_nonlinear_operator_t)                :: fe_nl_op
     type(fe_nonlinear_operator_t)                :: mass_nl_op
     type(nonlinear_solver_t)                     :: nl_solver
     type(time_stepping_operator_t)               :: time_operator
     type(dirk_solver_t)                          :: time_solver
     
     ! Direct and Iterative linear solvers data type
#ifdef ENABLE_MKL     
     type(direct_solver_t)                     :: direct_solver
#else     
     type(iterative_linear_solver_t)           :: iterative_linear_solver
#endif     
 
     ! Poisson problem solution FE function
     type(fe_function_t)                       :: solution
     type(fe_function_t)                       :: mass_fe_fun
     
     type(output_handler_t)                    :: oh
   contains
     procedure                  :: run_simulation
     procedure        , private :: parse_command_line_parameters
     procedure        , private :: setup_triangulation
     procedure        , private :: setup_reference_fes
     procedure        , private :: setup_fe_space
     procedure        , private :: setup_cell_quadratures_degree
     procedure        , private :: setup_system
     procedure        , private :: setup_solver
     procedure        , private :: assemble_system
     procedure        , private :: solve_system
     procedure        , private :: check_solution
     procedure        , private :: check_convergence_order
     procedure        , private :: initialize_output
     procedure        , private :: finalize_output
     procedure        , private :: write_time_step
     procedure        , private :: get_error_norm
     procedure        , private :: free
  end type test_transient_poisson_driver_t

  ! Types
  public :: test_transient_poisson_driver_t

contains

  subroutine parse_command_line_parameters(this)
    implicit none
    class(test_transient_poisson_driver_t ), intent(inout) :: this
    call this%test_params%create()
    call this%test_params%parse(this%parameter_list)
  end subroutine parse_command_line_parameters
  
  subroutine setup_triangulation(this)
    implicit none
    class(test_transient_poisson_driver_t), intent(inout) :: this

    class(cell_iterator_t), allocatable :: cell
    type(point_t), allocatable :: cell_coords(:)
    integer(ip) :: istat
    integer(ip) :: set_id
    real(rp) :: x, y
    integer(ip) :: num_void_neigs

    integer(ip)           :: ivef
    class(vef_iterator_t), allocatable  :: vef, vef_of_vef
    type(list_t), pointer :: vefs_of_vef
    type(list_t), pointer :: vertices_of_line
    type(list_iterator_t) :: vefs_of_vef_iterator
    type(list_iterator_t) :: vertices_of_line_iterator
    class(reference_fe_t), pointer :: reference_fe_geo
    integer(ip) :: ivef_pos_in_cell, vef_of_vef_pos_in_cell
    integer(ip) :: vertex_pos_in_cell, icell_arround
    integer(ip) :: inode, num


    !call this%triangulation%create(this%test_params%get_dir_path(),&
    !                               this%test_params%get_prefix(),&
    !                               geometry_interpolation_order=this%test_params%get_reference_fe_geo_order())
    call this%triangulation%create(this%parameter_list)
    !call this%triangulation%print()

    
    if ( this%test_params%get_triangulation_type() == 'structured' ) then
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
    end if
       
  end subroutine setup_triangulation
  
  subroutine setup_reference_fes(this)
    implicit none
    class(test_transient_poisson_driver_t), intent(inout) :: this
    !
    !type(polytope_tree_t) :: poly, poly_old
    !integer(ip) :: topology
    
    ! Locals
    integer(ip) :: istat    
    logical                                   :: conformity
    class(cell_iterator_t)      , allocatable :: cell
    class(reference_fe_t), pointer :: reference_fe_geo
    character(:), allocatable :: field_type
    
    allocate(this%reference_fes(1), stat=istat)

    conformity = .true.
    field_type = field_type_scalar
    
    call this%triangulation%create_cell_iterator(cell)
    reference_fe_geo => cell%get_reference_fe()
    this%reference_fes(1) =  make_reference_fe ( topology = reference_fe_geo%get_topology(), &
                                                                 fe_type = fe_type_lagrangian, &
                                                                 num_dims = this%triangulation%get_num_dims(), &
                                                                 order = this%test_params%get_reference_fe_order(), &
                                                                 field_type = field_type, &
                                                                 conformity = conformity )
    
    call this%triangulation%free_cell_iterator(cell)
  end subroutine setup_reference_fes

  subroutine setup_fe_space(this)
    implicit none
    class(test_transient_poisson_driver_t), intent(inout) :: this    

    call this%poisson_analytical_functions%set_num_dims(this%triangulation%get_num_dims())
    call this%poisson_conditions%set_boundary_function(this%poisson_analytical_functions%get_boundary_function())
    call this%fe_space%create( triangulation       = this%triangulation, &
                                 reference_fes     = this%reference_fes, &
                                 conditions        = this%poisson_conditions )
    call this%fe_space%set_up_cell_integration()
    call this%setup_cell_quadratures_degree()
  end subroutine setup_fe_space
  
  subroutine setup_cell_quadratures_degree (this)
    implicit none
    class(test_transient_poisson_driver_t), intent(inout) :: this
    class(fe_cell_iterator_t), allocatable :: fe
    call this%fe_space%create_fe_cell_iterator(fe) 
    ! Set first FE is enough for testing. Leaving loop as snippet for user-customization
    do while ( .not. fe%has_finished() )
       call fe%set_quadrature_degree(fe%get_default_quadrature_degree())
       call fe%next()
    end do
    call this%fe_space%free_fe_cell_iterator(fe)
  end subroutine setup_cell_quadratures_degree
  
  subroutine setup_system (this)
    implicit none
    class(test_transient_poisson_driver_t), intent(inout) :: this
    
    class(matrix_t), pointer :: A, M
    integer(ip) :: luout
   
    call this%fe_nl_op%create ( sparse_matrix_storage_format      = csr_format, &
                                          diagonal_blocks_symmetric_storage = [ .true. ], &
                                          diagonal_blocks_symmetric         = [ .true. ], &
                                          diagonal_blocks_sign              = [ SPARSE_MATRIX_SIGN_POSITIVE_DEFINITE ], &
                                          fe_space                          = this%fe_space, &
                                          discrete_integration              = this%poisson_cG_integration )
    
    call this%mass_nl_op%create ( sparse_matrix_storage_format      = csr_format, &
                                          diagonal_blocks_symmetric_storage = [ .true. ], &
                                          diagonal_blocks_symmetric         = [ .true. ], &
                                          diagonal_blocks_sign              = [ SPARSE_MATRIX_SIGN_POSITIVE_DEFINITE ], &
                                          fe_space                          = this%fe_space, &
                                          discrete_integration              = this%mass_integration )
   
    call this%time_operator%create( fe_nl_op                = this%fe_nl_op, &
                                    mass_op                 = this%mass_nl_op, &
                                    initial_time            = this%test_params%get_initial_time() , &
                                    final_time              = this%test_params%get_final_time() , &
                                    time_step               = this%test_params%get_time_step() , &
                                    time_integration_scheme = this%test_params%get_time_integration_scheme() )  
    call this%time_operator%set_fe_functions( this%solution , this%mass_fe_fun ) !pmartorell: Should it be inside create? Not nice, provisional...
  
    call this%solution%create(this%fe_space) 
    call this%mass_fe_fun%create(this%fe_space) 
    call this%poisson_cG_integration%set_fe_function(this%solution) 
    call this%mass_integration%set_fe_function(this%mass_fe_fun)
    call this%poisson_cG_integration%set_analytical_functions(this%poisson_analytical_functions)
    
    !pmartorell: Needed in release?
    !call this%fe_nl_op%set_evaluation_point(this%solution%get_free_dof_values())
    !call this%mass_nl_op%set_evaluation_point(this%mass_fe_fun%get_free_dof_values())
    !call this%fe_nl_op%compute_tangent()
    !call this%mass_nl_op%compute_tangent()
    
    !A => this%fe_nl_op%get_matrix()
    !M => this%mass_nl_op%get_matrix()
    
    
    !luout = io_open ( "A.mtx", 'write')
    !select type(A)
    !class is (sparse_matrix_t)  
    !   call A%print_matrix_market(luout) 
    !class DEFAULT
    !   assert(.false.) 
    !end select
    !call io_close(luout)
    
    !luout = io_open ( "M.mtx", 'write')
    !select type(M)
    !class is (sparse_matrix_t)  
    !  call M%print_matrix_market(luout) 
    !class DEFAULT
    !   assert(.false.) 
    !end select
    !call io_close(luout)
    
    
  end subroutine setup_system
  
  
  subroutine setup_solver (this)
    implicit none
    class(test_transient_poisson_driver_t), intent(inout) :: this
    integer :: FPLError
    type(parameterlist_t) :: parameter_list
    integer :: iparm(64), luout
    class(matrix_t), pointer       :: matrix

    call parameter_list%init()
#ifdef ENABLE_MKL
    FPLError = parameter_list%set(key = direct_solver_type,        value = pardiso_mkl)
    FPLError = FPLError + parameter_list%set(key = pardiso_mkl_matrix_type,   value = pardiso_mkl_spd)
    FPLError = FPLError + parameter_list%set(key = pardiso_mkl_message_level, value = 0)
    iparm = 0
    FPLError = FPLError + parameter_list%set(key = pardiso_mkl_iparm,         value = iparm)
    assert(FPLError == 0)
    
    call this%direct_solver%set_type_from_pl(parameter_list)
    call this%direct_solver%set_parameters_from_pl(parameter_list)    
    matrix => this%time_operator%get_matrix()
    
    
    select type(matrix)
    class is (matrix_t)  
       call this%direct_solver%set_matrix(matrix)
    class DEFAULT
       assert(.false.) 
    end select
    
    call this%nl_solver%create( convergence_criteria = abs_res_norm, &
                                abs_tol = 1.0e-6_rp, &
                                rel_tol = 1.0e-6_rp, &
                                max_iters = 10_ip, &
                                linear_solver = this%direct_solver, &
                                environment = this%fe_space%get_environment() )
    
    call this%time_solver%create( ts_op = this%time_operator, &
                                  nl_solver = this%nl_solver )
    
#else    
    FPLError = parameter_list%set(key = ils_rtol, value = 1.0e-12_rp)
    !FPLError = FPLError + parameter_list%set(key = ils_output_frequency, value = 30)
    FPLError = parameter_list%set(key = ils_max_num_iterations, value = 5000)
    assert(FPLError == 0)
    call this%iterative_linear_solver%create(this%fe_space%get_environment())
    call this%iterative_linear_solver%set_type_from_string(cg_name)
    call this%iterative_linear_solver%set_parameters_from_pl(parameter_list)
    call this%iterative_linear_solver%set_operators(this%fe_affine_operator%get_tangent(), .identity. this%fe_affine_operator) 
    
    call this%nl_solver%create( convergence_criteria = abs_res_norm, &
                                abs_tol = 1.0e-6_rp, &
                                rel_tol = 1.0e-6_rp, &
                                max_iters = 10_ip, &
                                linear_solver = this%iterative_linear_solver, &
                                environment = this%fe_space%get_environment() )
    
    call this%time_solver%create( ts_op = this%time_operator, &
                                  nl_solver = this%nl_solver )
#endif
    call parameter_list%free()
  end subroutine setup_solver
  
  
  subroutine assemble_system (this)
    implicit none
    class(test_transient_poisson_driver_t), intent(inout) :: this
    !class(matrix_t)                  , pointer       :: matrix
    !class(vector_t)                  , pointer       :: rhs
    !integer(ip) :: luout
    !call this%fe_affine_operator%compute()
    !rhs                => this%fe_affine_operator%get_translation()
    !matrix             => this%fe_affine_operator%get_matrix()
    
    !luout = io_open ( "matrix.mtx", 'write')
    !select type(matrix)
    !class is (sparse_matrix_t)  
    !   call matrix%print_matrix_market(luout) 
    !class DEFAULT
    !   assert(.false.) 
    !end select
    !call io_close(luout)
    
    !luout = io_open ( "force_term.mtx", 'write')
    !select type(rhs)
    !class is (serial_scalar_array_t)  
    !  call rhs%print_matrix_market(luout) 
    !class DEFAULT
    !   assert(.false.) 
    !end select
    !call io_close(luout)
  end subroutine assemble_system
  
  
  subroutine solve_system(this)
    implicit none
    class(test_transient_poisson_driver_t), intent(inout)   :: this
    class(vector_t)                         , pointer       :: dof_values_current
    class(vector_t)                         , allocatable   :: dof_values_previous
    real(rp) :: final_time, time_step
    real(rp)                                                :: current_time
    
    !! sbadia: for transient body force/bc's we will need the time t0 too

    current_time = this%time_operator%get_current_time()
    final_time = this%time_operator%get_final_time()

    call this%fe_space%interpolate(field_id=1, &
                                   function = this%poisson_analytical_functions%get_solution_function(), &
                                   fe_function=this%solution, &
                                   time=current_time)
  
    dof_values_current => this%solution%get_free_dof_values()

    call dof_values_current%mold(dof_values_previous)  ! select dynamic type of dof_values_previous
    
    call dof_values_previous%clone(dof_values_current) ! allocate dof_values_current
    

    
    do while ( .not. this%time_operator%has_finished() )

       call dof_values_previous%copy(dof_values_current) ! copy entries

       call this%time_solver%apply( dof_values_previous, dof_values_current )
       
       current_time = this%time_operator%get_current_time() ! pmartorell: updated current_time after solve, time_operator solves at t=t^(n-1) + c_i * dt
       call this%fe_space%interpolate_dirichlet_values(this%solution, time=current_time) ! pmartorell: updated boundary values when not evaluated in the solver, e.g. forward_euler
       call this%write_time_step(current_time)       
       if ( .not. this%test_params%get_is_test()) then
         call this%check_solution(current_time)
       endif
    end do
    
    if ( allocated(dof_values_previous) ) call dof_values_previous%free()
  
  end subroutine solve_system
    
  subroutine check_solution(this,current_time)
    implicit none
    class(test_transient_poisson_driver_t), intent(inout) :: this
    real(rp)                              , intent(in)    :: current_time 
    type(error_norms_scalar_t) :: error_norm
    real(rp) :: mean, l1, l2, lp, linfty, h1, h1_s, w1p_s, w1p, w1infty_s, w1infty
    real(rp) :: error_tolerance
    
    call error_norm%create(this%fe_space,1)
    mean = error_norm%compute(this%poisson_analytical_functions%get_solution_function(), this%solution, mean_norm, time=current_time)   
    l1 = error_norm%compute(this%poisson_analytical_functions%get_solution_function(), this%solution, l1_norm, time=current_time)   
    l2 = error_norm%compute(this%poisson_analytical_functions%get_solution_function(), this%solution, l2_norm, time=current_time)   
    lp = error_norm%compute(this%poisson_analytical_functions%get_solution_function(), this%solution, lp_norm, time=current_time)   
    linfty = error_norm%compute(this%poisson_analytical_functions%get_solution_function(), this%solution, linfty_norm, time=current_time)   
    h1_s = error_norm%compute(this%poisson_analytical_functions%get_solution_function(), this%solution, h1_seminorm, time=current_time) 
    h1 = error_norm%compute(this%poisson_analytical_functions%get_solution_function(), this%solution, h1_norm, time=current_time) 
    w1p_s = error_norm%compute(this%poisson_analytical_functions%get_solution_function(), this%solution, w1p_seminorm, time=current_time)   
    w1p = error_norm%compute(this%poisson_analytical_functions%get_solution_function(), this%solution, w1p_norm, time=current_time)   
    w1infty_s = error_norm%compute(this%poisson_analytical_functions%get_solution_function(), this%solution, w1infty_seminorm, time=current_time) 
    w1infty = error_norm%compute(this%poisson_analytical_functions%get_solution_function(), this%solution, w1infty_norm, time=current_time)

#ifdef ENABLE_MKL    
    error_tolerance = 1.0e-08
#else
    error_tolerance = 1.0e-06
#endif    
    
    write(*,'(a20,e32.25)') 'mean_norm:', mean; !check ( abs(mean) < error_tolerance )
    write(*,'(a20,e32.25)') 'l1_norm:', l1; !check ( l1 < error_tolerance )
    write(*,'(a20,e32.25)') 'l2_norm:', l2; !check ( l2 < error_tolerance )
    write(*,'(a20,e32.25)') 'lp_norm:', lp; !check ( lp < error_tolerance )
    write(*,'(a20,e32.25)') 'linfnty_norm:', linfty; !check ( linfty < error_tolerance )
    write(*,'(a20,e32.25)') 'h1_seminorm:', h1_s; !check ( h1_s < error_tolerance )
    write(*,'(a20,e32.25)') 'h1_norm:', h1; !check ( h1 < error_tolerance )
    write(*,'(a20,e32.25)') 'w1p_seminorm:', w1p_s; !check ( w1p_s < error_tolerance )
    write(*,'(a20,e32.25)') 'w1p_norm:', w1p; !check ( w1p < error_tolerance )
    write(*,'(a20,e32.25)') 'w1infty_seminorm:', w1infty_s; !check ( w1infty_s < error_tolerance )
    write(*,'(a20,e32.25)') 'w1infty_norm:', w1infty; ! check ( w1infty < error_tolerance )
    call error_norm%free()
  end subroutine check_solution
  
  ! -----------------------------------------------------------------------------------------------
  subroutine check_convergence_order(this)
    implicit none
    class(test_transient_poisson_driver_t), intent(inout) :: this
    type(error_norms_scalar_t) :: error_norm
    character(len=:), allocatable :: time_integration_scheme
    real(rp) :: l2, l2_prev, dt, dt_variation, current_time, order_tol, final_time, error_tolerance
    integer(ip) :: convergence_order
    logical :: is_test , in_tol
    
    dt = 1.0e-03
    final_time = 1.0e-02
    dt_variation = 1.0e-01
    order_tol = 0.05_rp
    in_tol  = .false.
    
    
    time_integration_scheme = this%test_params%get_time_integration_scheme()
    is_test = this%test_params%get_is_test()
    
#ifdef ENABLE_MKL    
    error_tolerance = 1.0e-10
#else
    error_tolerance = 1.0e-06
#endif  
    
    if ( time_integration_scheme == 'trapezoidal_rule' ) then
      dt = 1
      final_time = 10
    end if
    
    if (is_test) then

      l2_prev = this%get_error_norm(dt,dt,time_integration_scheme)
      l2      = this%get_error_norm(dt*dt_variation,dt*dt_variation,time_integration_scheme)
      
      if ( time_integration_scheme == 'trapezoidal_rule' ) then
        if ( l2 < error_tolerance .and. l2_prev < error_tolerance) then
          in_tol = .true.
        endif
      endif
      
      convergence_order = this%time_operator%get_order()

      if ( abs((l2 - l2_prev*dt_variation**(convergence_order+1)) / l2) < order_tol .or. in_tol ) then
        write(*,*) 'Local  convergence test for: ', time_integration_scheme , char(9) ,' ...  pass' 
      else
        write(*,*) 'Local  convergence test for: ', time_integration_scheme , char(9) ,' ...  fail' 
      endif
      
      l2_prev = this%get_error_norm(dt,final_time,time_integration_scheme)
      l2      = this%get_error_norm(dt*dt_variation,final_time,time_integration_scheme)
       
      convergence_order = this%time_operator%get_order()
      
      
      if ( time_integration_scheme == 'trapezoidal_rule' ) then
        if ( l2 < error_tolerance .and. l2_prev < error_tolerance) then
          in_tol = .true.
        endif
      endif
      
      if ( abs((l2 - l2_prev*dt_variation**convergence_order) / l2) < order_tol .or. in_tol ) then
        write(*,*) 'Global convergence test for: ', time_integration_scheme , char(9) ,' ...  pass' 
      else
        write(*,*) 'Global convergence test for: ', time_integration_scheme , char(9) ,' ...  fail' 
      endif
      
      
       deallocate(time_integration_scheme)
    endif  
  end subroutine check_convergence_order
  
  function get_error_norm ( this , dt , final_time, time_integration_scheme)
    implicit none
    class(test_transient_poisson_driver_t), intent(inout) :: this
    real(rp)                              , intent(in)    :: dt, final_time
    character(len=:), allocatable         , intent(in)    :: time_integration_scheme
    real(rp)                                              :: get_error_norm, current_time
    type(error_norms_scalar_t) :: error_norm
    
    call error_norm%create(this%fe_space,1)
    call this%time_operator%update(0.0_rp,final_time,dt,time_integration_scheme)
    call this%solve_system()
    current_time = this%time_operator%get_current_time()
    get_error_norm = error_norm%compute(this%poisson_analytical_functions%get_solution_function(), this%solution, l2_norm, time=current_time) !pmartorell: l2_norm argumnent if tested for differents norms
    call error_norm%free()                 
  end function get_error_norm
  
  ! -----------------------------------------------------------------------------------------------
  subroutine initialize_output(this)
    implicit none
    class(test_transient_poisson_driver_t), intent(inout) :: this
    character(len=:), allocatable            :: path
    character(len=:), allocatable            :: prefix
    if(this%test_params%get_write_solution()) then
        path = this%test_params%get_dir_path_out()
        prefix = this%test_params%get_prefix()
        call this%oh%create()
        call this%oh%attach_fe_space(this%fe_space)
        call this%oh%add_fe_function(this%solution, 1, 'solution')
        call this%oh%add_fe_function(this%solution, 1, 'grad_solution', grad_diff_operator)
        call this%oh%open(path, prefix)
    endif
  end subroutine initialize_output
  
  ! -----------------------------------------------------------------------------------------------
  subroutine write_time_step(this, current_time)
    implicit none
    class(test_transient_poisson_driver_t), intent(inout) :: this
    real(rp)                              , intent(in)    :: current_time
    if(this%test_params%get_write_solution()) then
     call this%oh%append_time_step(current_time)
     call this%oh%write()
    endif
  end subroutine write_time_step
  
  ! -----------------------------------------------------------------------------------------------
  subroutine finalize_output(this)
    implicit none
    class(test_transient_poisson_driver_t), intent(inout) :: this
    integer(ip)                                      :: err
    if(this%test_params%get_write_solution()) then
      call this%oh%close()
    endif
  end subroutine finalize_output
  
  subroutine run_simulation(this) 
    implicit none
    class(test_transient_poisson_driver_t), intent(inout) :: this    
    call this%free()
    call this%parse_command_line_parameters()
    call this%setup_triangulation()
    call this%setup_reference_fes()
    call this%setup_fe_space()
    call this%setup_system()
    call this%assemble_system()
    call this%setup_solver()
    call this%initialize_output()
    call this%solve_system()
    call this%check_convergence_order() !hide?
    call this%finalize_output()
    call this%free()
  end subroutine run_simulation
  
  subroutine free(this)
    implicit none
    class(test_transient_poisson_driver_t), intent(inout) :: this
    integer(ip) :: i, istat
    
    call this%solution%free()
    call this%mass_fe_fun%free()
    
#ifdef ENABLE_MKL        
    call this%direct_solver%free()
#else
    call this%iterative_linear_solver%free()
#endif
    
    call this%time_solver%free()
    call this%nl_solver%free()
    
    call this%time_operator%free()
    call this%fe_nl_op%free()
    call this%mass_nl_op%free()
    call this%fe_space%free()
    if ( allocated(this%reference_fes) ) then
      do i=1, size(this%reference_fes)
        call this%reference_fes(i)%p%free()
      end do
      deallocate(this%reference_fes, stat=istat)
      check(istat==0)
    end if
    call this%triangulation%free()
    if (allocated(this%cell_set_ids)) call memfree(this%cell_set_ids,__FILE__,__LINE__)
    call this%test_params%free()
    call this%oh%free()
  end subroutine free  
  
end module test_transient_poisson_driver_names
