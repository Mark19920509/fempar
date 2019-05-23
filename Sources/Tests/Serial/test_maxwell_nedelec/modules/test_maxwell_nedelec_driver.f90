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
module test_maxwell_nedelec_driver_names
  use fempar_names
  use maxwell_nedelec_params_names
  use maxwell_nedelec_analytical_functions_names
  use maxwell_nedelec_discrete_integration_names
  use maxwell_nedelec_conditions_names
# include "debug.i90"

  implicit none
  private

  type test_maxwell_nedelec_driver_t 
     private 

     ! Place-holder for parameter-value set provided through command-line interface
     type(maxwell_nedelec_params_t)           :: test_params
     type(ParameterList_t), pointer           :: parameter_list

     ! Cells and lower dimension objects container
     type(serial_triangulation_t)                :: triangulation

     ! Analytical functions of the problem
     type(maxwell_nedelec_analytical_functions_t) :: problem_functions

     ! Discrete weak problem integration-related data type instances 
     type(serial_fe_space_t)                     :: fe_space 
     type(p_reference_fe_t) , allocatable        :: reference_fes(:) 
     type(maxwell_nedelec_discrete_integration_t) :: maxwell_nedelec_integration
     type(maxwell_nedelec_conditions_t)           :: maxwell_nedelec_conditions

     ! Place-holder for the coefficient matrix and RHS of the linear system
     type(fe_affine_operator_t)                  :: fe_affine_operator

     ! Direct and Iterative linear solvers data type
     type(environment_t)                       :: serial_environment
#ifdef ENABLE_MKL     
     type(direct_solver_t)                     :: direct_solver
#else     
     type(iterative_linear_solver_t)           :: iterative_linear_solver
#endif     

     ! Poisson problem solution FE function
     type(fe_function_t)                         :: solution

   contains
     procedure                  :: run_simulation
     procedure                  :: parse_command_line_parameters
     procedure                  :: setup_environment
     procedure                  :: free_environment
     procedure        , private :: setup_triangulation
     procedure        , private :: setup_reference_fes
     procedure        , private :: setup_fe_space
     procedure        , private :: setup_system
     procedure        , private :: setup_solver
     procedure        , private :: assemble_system
     procedure        , private :: solve_system
     procedure        , private :: check_solution
     procedure        , private :: write_solution
     procedure        , private :: free
  end type test_maxwell_nedelec_driver_t

  ! Types
  public :: test_maxwell_nedelec_driver_t

contains

  subroutine parse_command_line_parameters(this)
    implicit none
    class(test_maxwell_nedelec_driver_t ), intent(inout) :: this
    call parameter_handler%process_parameters(maxwell_nedelec_params_define_user_parameters)
    this%parameter_list => parameter_handler%get_values()
  end subroutine parse_command_line_parameters
  
  subroutine setup_environment(this, world_context)
    implicit none
    class(test_maxwell_nedelec_driver_t ), intent(inout) :: this
    class(execution_context_t)  , intent(in)    :: world_context
    call this%serial_environment%create(world_context, this%parameter_list)
  end subroutine setup_environment
  
  subroutine free_environment(this)
    implicit none
    class(test_maxwell_nedelec_driver_t ), intent(inout) :: this
    call this%serial_environment%free()
  end subroutine free_environment

  subroutine setup_triangulation(this)
    implicit none
    class(test_maxwell_nedelec_driver_t), intent(inout) :: this
    integer(ip) :: istat 
    call this%triangulation%create(this%serial_environment, this%parameter_list)
  end subroutine setup_triangulation

  subroutine setup_reference_fes(this)
    implicit none
    class(test_maxwell_nedelec_driver_t), intent(inout) :: this
    integer(ip) :: istat
    class(vef_iterator_t), allocatable  :: vef
    class(cell_iterator_t), allocatable       :: cell
    class(reference_fe_t), pointer :: reference_fe_geo


    allocate(this%reference_fes(1), stat=istat)
    check(istat==0)

    call this%triangulation%create_cell_iterator(cell)
    reference_fe_geo => cell%get_reference_fe()
 
    this%reference_fes(1) =  make_reference_fe ( topology = reference_fe_geo%get_topology(),                  &
                                                 fe_type = fe_type_nedelec,                                   &
                                                 num_dims = this%triangulation%get_num_dims(), &
                                                 order = this%test_params%get_reference_fe_order(),           &
                                                 field_type = field_type_vector,                              &
                                                 conformity = .true. ) 
    
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
    
  end subroutine setup_reference_fes

  subroutine setup_fe_space(this)
    implicit none
    class(test_maxwell_nedelec_driver_t), intent(inout) :: this

    call this%problem_functions%set_case(this%test_params%get_analytical_function_case())
    call this%maxwell_nedelec_conditions%set_num_dims(this%triangulation%get_num_dims())
    call this%fe_space%create( triangulation       = this%triangulation, &
         reference_fes       = this%reference_fes, &
         conditions          = this%maxwell_nedelec_conditions )
    call this%fe_space%set_up_cell_integration()
    call this%fe_space%set_up_facet_integration()
  end subroutine setup_fe_space

  subroutine setup_system (this)
    implicit none
    class(test_maxwell_nedelec_driver_t), intent(inout) :: this 
    call this%problem_functions%set_num_dims(this%triangulation%get_num_dims())
    call this%maxwell_nedelec_integration%set_source_term(this%problem_functions%get_source_term())
    call this%fe_affine_operator%create ( sparse_matrix_storage_format      = csr_format, &
                                          diagonal_blocks_symmetric_storage = [ .false.  ], &
                                          diagonal_blocks_symmetric         = [ .false. ], &
                                          diagonal_blocks_sign              = [ SPARSE_MATRIX_SIGN_UNKNOWN ], &
                                          fe_space                          = this%fe_space,           &
                                          discrete_integration              = this%maxwell_nedelec_integration )
    call this%solution%create(this%fe_space) 
    call this%maxwell_nedelec_conditions%set_boundary_function_Hx(this%problem_functions%get_boundary_function_Hx())
    call this%maxwell_nedelec_conditions%set_boundary_function_Hy(this%problem_functions%get_boundary_function_Hy())
    if ( this%triangulation%get_num_dims() == 3) then 
      call this%maxwell_nedelec_conditions%set_boundary_function_Hz(this%problem_functions%get_boundary_function_Hz())
    end if 
    call this%fe_space%interpolate(1, this%problem_functions%get_solution(), this%solution)
    call this%maxwell_nedelec_integration%set_fe_function(this%solution)
  end subroutine setup_system

  subroutine setup_solver (this)
    implicit none
    class(test_maxwell_nedelec_driver_t), intent(inout) :: this
    integer               :: FPLError
    type(parameterlist_t) :: parameter_list
    integer               :: iparm(64)
    class(matrix_t), pointer       :: matrix
    
    call parameter_list%init()
#ifdef ENABLE_MKL    
    FPLError =            parameter_list%set(key = dls_type_key     ,   value = pardiso_mkl)
    FPLError = FPLError + parameter_list%set(key = pardiso_mkl_matrix_type,   value = pardiso_mkl_uns)
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
    FPLError = parameter_list%set(key = ils_rtol_key, value = 1.0e-10_rp)
    FPLError = FPLError + parameter_list%set(key = ils_output_frequency_key, value = 30)
    FPLError = FPLError + parameter_list%set(key = ils_max_num_iterations_key, value = 5000)
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
    class(test_maxwell_nedelec_driver_t), intent(inout) :: this
    class(matrix_t), pointer       :: matrix
    class(vector_t), pointer       :: rhs
    call this%fe_affine_operator%compute()
    !rhs    => this%fe_affine_operator%get_translation()
    !matrix => this%fe_affine_operator%get_matrix()
    !select type(matrix)
    !class is (sparse_matrix_t)  
    !   call matrix%print_matrix_market(6) 
    !class DEFAULT
    !   assert(.false.) 
    !end select
  end subroutine assemble_system

  subroutine solve_system(this)
    implicit none
    class(test_maxwell_nedelec_driver_t), intent(inout) :: this
    class(matrix_t), pointer       :: matrix
    class(vector_t), pointer       :: rhs
    class(vector_t), pointer       :: dof_values
    matrix     => this%fe_affine_operator%get_matrix()
    rhs        => this%fe_affine_operator%get_translation()
    dof_values => this%solution%get_free_dof_values()
#ifdef ENABLE_MKL    
    call this%direct_solver%solve(this%fe_affine_operator%get_translation(), dof_values)
#else
    call this%iterative_linear_solver%solve(this%fe_affine_operator%get_translation(), &
                                            dof_values)
#endif    
    
    !select type (rhs)
    !class is (serial_scalar_array_t)  
    !   call rhs%print_matrix_market(6)
    !class DEFAULT
    !   assert(.false.) 
    !end select
    
    !select type (dof_values)
    !class is (serial_scalar_array_t)  
    !   call dof_values%print_matrix_market(6)
    !class DEFAULT
    !   assert(.false.) 
    !end select
  end subroutine solve_system
  
  subroutine check_solution(this)
    implicit none
    class(test_maxwell_nedelec_driver_t), intent(inout) :: this
    class(vector_function_t), pointer :: H_exact_function
    type(error_norms_vector_t) :: H_error_norm
    real(rp) :: mean, l1, l2, lp, linfty, h1, hcurl, h1_s, w1p_s, w1p, w1infty_s, w1infty
    real(rp) :: error_tolerance
    
    H_exact_function => this%problem_functions%get_solution()
    
    call H_error_norm%create(this%fe_space,1)
    write(*,*) 'H ERROR NORMS'
    mean = H_error_norm%compute(H_exact_function, this%solution, mean_norm)   
    l1 = H_error_norm%compute(H_exact_function, this%solution, l1_norm)   
    l2 = H_error_norm%compute(H_exact_function, this%solution, l2_norm)   
    lp = H_error_norm%compute(H_exact_function, this%solution, lp_norm)   
    linfty = H_error_norm%compute(H_exact_function, this%solution, linfty_norm)   
    h1_s = H_error_norm%compute(H_exact_function, this%solution, h1_seminorm) 
    h1 = H_error_norm%compute(H_exact_function, this%solution, h1_norm) 
    hcurl = H_error_norm%compute(H_exact_function, this%solution, hcurl_seminorm) 
    w1p_s = H_error_norm%compute(H_exact_function, this%solution, w1p_seminorm)   
    w1p = H_error_norm%compute(H_exact_function, this%solution, w1p_norm)   
    w1infty_s = H_error_norm%compute(H_exact_function, this%solution, w1infty_seminorm) 
    w1infty = H_error_norm%compute(H_exact_function, this%solution, w1infty_norm)
    
#ifdef ENABLE_MKL    
    error_tolerance = 1.0e-06
#else
    error_tolerance = 1.0e-04
#endif    
    
    write(*,'(a20,e32.25)') 'mean_norm:', mean
    write(*,'(a20,e32.25)') 'l1_norm:', l1
    write(*,'(a20,e32.25)') 'l2_norm:', l2
    write(*,'(a20,e32.25)') 'lp_norm:', lp
    write(*,'(a20,e32.25)') 'linfnty_norm:', linfty
    write(*,'(a20,e32.25)') 'h1_seminorm:', h1_s
    write(*,'(a20,e32.25)') 'h1_norm:', h1
    write(*,'(a20,e32.25)') 'hcurl_norm:', hcurl
    write(*,'(a20,e32.25)') 'w1p_seminorm:', w1p_s
    write(*,'(a20,e32.25)') 'w1p_norm:', w1p
    write(*,'(a20,e32.25)') 'w1infty_seminorm:', w1infty_s
    write(*,'(a20,e32.25)') 'w1infty_norm:', w1infty
    if ( this%test_params%get_analytical_function_case() == in_fe_space ) then 
    massert( abs(mean) < error_tolerance, 'mean-norm not consistent' )
    massert( l1 < error_tolerance, 'L1-norm not consistent' )
    massert( l2 < error_tolerance, 'L2-norm not consistent' )
    massert( lp < error_tolerance, 'Lp-norm not consistent' )
    massert( linfty < error_tolerance, 'L_infinity-norm not consistent' )
    massert( h1_s < error_tolerance, 'H1-seminorm not consistent' )
    massert( h1 < error_tolerance, 'H1-norm not consistent' )
    massert( hcurl < error_tolerance, 'Hcurl-norm not consistent' )
    massert( w1p_s < error_tolerance, 'W1ps_norm not consistent' )
    massert( w1p < error_tolerance, 'W1p-norm not consistent' )
    massert( w1infty_s < error_tolerance, 'W1_infinity-seminorm not consistent' )
    massert( w1infty < error_tolerance, 'W1_infinity-norm not consistent' )
    end if 
    
    call H_error_norm%free()
  end subroutine check_solution 
  
  subroutine write_solution(this)
    implicit none
    class(test_maxwell_nedelec_driver_t), intent(in) :: this
    type(output_handler_t)                           :: oh
    if(this%test_params%get_write_solution()) then
        call oh%create()
        call oh%attach_fe_space(this%fe_space)
        call oh%add_fe_function(this%solution, 1, 'solution')
        call oh%open(this%test_params%get_dir_path_out(), this%test_params%get_prefix())
        call oh%write()
        call oh%close()
        call oh%free()
    endif
  end subroutine write_solution

  subroutine run_simulation(this) 
    implicit none
    class(test_maxwell_nedelec_driver_t), intent(inout) :: this
    call this%free()
    call this%setup_triangulation()
    call this%setup_reference_fes()
    call this%setup_fe_space()
    call this%setup_system()
    call this%assemble_system()
    call this%setup_solver()
    call this%solve_system()
    call this%write_solution()
    call this%check_solution()
    !call this%show_H()
    call this%free()
  end subroutine run_simulation
  
  subroutine free(this)
    implicit none
    class(test_maxwell_nedelec_driver_t), intent(inout) :: this
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
  end subroutine free

end module test_maxwell_nedelec_driver_names
