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
module test_poisson_error_estimator_params_names
  use fempar_names
# include "debug.i90"

  implicit none
  private

  character(len=*), parameter :: reference_fe_order_key        = 'reference_fe_order'    
  character(len=*), parameter :: write_solution_key            = 'write_solution'        
  character(len=*), parameter :: refinement_strategy_key       = 'refinement_strategy'
  character(len=*), parameter :: analytical_functions_type_key = 'analytical_functions_type'

  type :: test_poisson_error_estimator_params_t
   contains
     procedure, non_overridable             :: process_parameters
     procedure, non_overridable             :: get_prefix
     procedure, non_overridable             :: get_dir_path_out
     procedure, non_overridable             :: get_reference_fe_order
     procedure, non_overridable             :: get_write_solution
     procedure, non_overridable             :: get_refinement_strategy
     procedure, non_overridable             :: get_analytical_functions_type
  end type test_poisson_error_estimator_params_t  

  ! Types
  public :: test_poisson_error_estimator_params_t

contains
  
  subroutine process_parameters(this)
    implicit none
    class(test_poisson_error_estimator_params_t) , intent(in) :: this
    call parameter_handler%process_parameters(test_poisson_define_user_parameters)
  end subroutine process_parameters

  !==================================================================================================
  subroutine test_poisson_define_user_parameters()
    implicit none
    ! IO parameters
    call parameter_handler%add(reference_fe_order_key, &
                               '--reference-fe-order', &
                               1, &
                               'Order of the fe space reference fe', &
                               switch_ab='-order') 
    call parameter_handler%add(write_solution_key, &
                               '--write-solution', &
                               .false., &
                               'Write solution in VTK format', &
                               switch_ab='-wsolution') 
    call parameter_handler%add(refinement_strategy_key, &
                               '--refinement_strategy', &
                               'uniform', &
                               'uniform or error_objective refinement strategy?', &
                               switch_ab='-rs') 
    call parameter_handler%add(analytical_functions_type_key, &
                               '--analytical_functions_type', &
                               'polynomial', &
                               'polynomial or shock analytical functions?', &
                               switch_ab='-af')
  end subroutine test_poisson_define_user_parameters
  
  ! GETTERS *****************************************************************************************
  !==================================================================================================
  function get_prefix(this)
    implicit none
    class(test_poisson_error_estimator_params_t) , intent(in) :: this
    character(len=:), allocatable                             :: get_prefix
    get_prefix = parameter_handler%get_prefix()
  end function get_prefix

  !==================================================================================================
  function get_dir_path_out(this)
    implicit none
    class(test_poisson_error_estimator_params_t) , intent(in) :: this
    character(len=:), allocatable                             :: get_dir_path_out
    get_dir_path_out = parameter_handler%get_dir_path_out()
  end function get_dir_path_out

  !==================================================================================================
  function get_reference_fe_order(this)
    implicit none
    class(test_poisson_error_estimator_params_t) , intent(in) :: this
    integer(ip)                                               :: get_reference_fe_order
     call parameter_handler%get(reference_fe_order_key, get_reference_fe_order)
  end function get_reference_fe_order
  
  !==================================================================================================
  function get_write_solution(this)
    implicit none
    class(test_poisson_error_estimator_params_t) , intent(in) :: this
    logical                                                   :: get_write_solution
    call parameter_handler%get(write_solution_key, get_write_solution)
  end function get_write_solution
    
  !==================================================================================================
  function get_refinement_strategy(this)
    implicit none
    class(test_poisson_error_estimator_params_t) , intent(in) :: this
    character(len=:), allocatable                             :: get_refinement_strategy
    call parameter_handler%getasstring(refinement_strategy_key, get_refinement_strategy)
  end function get_refinement_strategy 
  
  !==================================================================================================
  function get_analytical_functions_type(this)
    implicit none
    class(test_poisson_error_estimator_params_t) , intent(in) :: this
    character(len=:), allocatable                             :: get_analytical_functions_type
    call parameter_handler%getasstring(analytical_functions_type_key, get_analytical_functions_type)
  end function get_analytical_functions_type
  
end module test_poisson_error_estimator_params_names
