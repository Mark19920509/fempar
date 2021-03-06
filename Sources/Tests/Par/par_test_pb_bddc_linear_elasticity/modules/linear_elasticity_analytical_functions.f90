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
module linear_elasticity_analytical_functions_names
  use fempar_names
  use linear_elasticity_constitutive_models_names
  implicit none
# include "debug.i90"
  private

!===============================================================================================
  type, extends(scalar_function_t) :: zero_scalar_function_t
   contains
     procedure :: get_value_space  => zero_scalar_function_get_value_space
  end type zero_scalar_function_t

  type, extends(vector_function_t) :: zero_vector_function_t
   contains
     procedure :: get_value_space  => zero_vector_function_get_value_space
  end type zero_vector_function_t

  type, extends(vector_function_t) :: source_term_u_t
   contains
     procedure :: get_value_space => source_term_u_get_value_space
  end type source_term_u_t
  
  type, extends(vector_function_t) :: gravity_source_term_u_t
   contains
     procedure :: get_value_space => gravity_source_term_u_get_value_space
  end type gravity_source_term_u_t

  type, extends(vector_function_t) :: solution_function_u_t
   contains
     procedure :: get_value_space      => solution_function_u_get_value_space
     procedure :: get_value_space_time => solution_function_u_get_value_space_time
     procedure :: get_gradient_space   => solution_function_u_get_gradient_space
  end type solution_function_u_t
  !===============================================================================================

  type linear_elasticity_analytical_functions_t
     private
     type(source_term_u_t)         :: source_term_u
     type(gravity_source_term_u_t) :: gravity_source_term_u
     type(solution_function_u_t)   :: solution_function_u
     type(zero_vector_function_t)  :: zero_u
   contains
     procedure :: set_num_dims        => linear_elasticity_analytical_functions_set_num_dims
     procedure :: get_source_term_u         => linear_elasticity_analytical_functions_get_source_term_u
     procedure :: get_gravity_source_term_u => lin_ela_analytical_functions_get_gravity_source_term_u
     procedure :: get_solution_function_u   => linear_elasticity_analytical_functions_get_solution_function_u
     procedure :: get_zero_function_u       => linear_elasticity_analytical_functions_get_zero_function_u
  end type linear_elasticity_analytical_functions_t

  public :: linear_elasticity_analytical_functions_t

contains  

  !===============================================================================================
  subroutine zero_scalar_function_get_value_space ( this, point, result )
    implicit none
    class(zero_scalar_function_t), intent(in)    :: this
    type(point_t), intent(in)    :: point
    real(rp)     , intent(inout) :: result
    result = 0.0
  end subroutine zero_scalar_function_get_value_space

  subroutine zero_vector_function_get_value_space( this, point, result )
    implicit none
    class(zero_vector_function_t), intent(in) :: this
    type(point_t)             , intent(in)    :: point
    type(vector_field_t)      , intent(inout) :: result
    call result%init(0.0)
  end subroutine zero_vector_function_get_value_space

  subroutine source_term_u_get_value_space ( this, point, result )
    implicit none
    class(source_term_u_t), intent(in)    :: this
    type(point_t)       , intent(in)    :: point
    type(vector_field_t), intent(inout) :: result
    if ( this%get_num_dims() == 2 ) then
       call result%set(1,0.0_rp)
       call result%set(2,0.0_rp) 
    else
       call result%set(1,0.0_rp)
       call result%set(2,0.0_rp) 
       call result%set(3,0.0_rp) 
    end if
  end subroutine source_term_u_get_value_space
  
  subroutine gravity_source_term_u_get_value_space ( this, point, result )
    implicit none
    class(gravity_source_term_u_t), intent(in)    :: this
    type(point_t)       , intent(in)    :: point
    type(vector_field_t), intent(inout) :: result
    if ( this%get_num_dims() == 2 ) then
       assert(0==1)
    else
       call result%set(1,0.0_rp)
       call result%set(2,-9.8_rp) 
       call result%set(3,0.0_rp) 
    end if
  end subroutine gravity_source_term_u_get_value_space

  subroutine solution_function_u_get_value_space ( this, point, result )
    implicit none
    class(solution_function_u_t), intent(in)    :: this
    type(point_t)           , intent(in)    :: point
    type(vector_field_t)    , intent(inout) :: result
    if ( this%get_num_dims() == 2 ) then
       call result%set(1, point%get(1)+point%get(2) ) 
       call result%set(2, point%get(1)+point%get(2) ) 
    else
       call result%set(1, point%get(1)+point%get(2)+point%get(3) ) 
       call result%set(2, point%get(1)+point%get(2)+point%get(3) ) 
       call result%set(3, point%get(1)+point%get(2)+point%get(3) )
    end if
  end subroutine solution_function_u_get_value_space

  subroutine solution_function_u_get_value_space_time ( this, point, time, result )
    implicit none
    class(solution_function_u_t), intent(in)    :: this
    type(point_t)               , intent(in)    :: point
    real(rp)                    , intent(in)    :: time
    type(vector_field_t)        , intent(inout) :: result
    ! Steady state solution
    call this%get_value_space(point,result)
  end subroutine solution_function_u_get_value_space_time
  
  subroutine solution_function_u_get_gradient_space ( this, point, result )
    implicit none
    class(solution_function_u_t), intent(in)    :: this
    type(point_t)             , intent(in)    :: point
    type(tensor_field_t)      , intent(inout) :: result
    if ( this%get_num_dims() == 2 ) then
       call result%set( 1, 1, 1.0_rp ) 
       call result%set( 2, 1, 1.0_rp )
       call result%set( 1, 2, 1.0_rp ) 
       call result%set( 2, 2, 1.0_rp )
    else
       call result%init(1.0_rp)
    end if
  end subroutine solution_function_u_get_gradient_space

  !===============================================================================================
  subroutine linear_elasticity_analytical_functions_set_num_dims ( this, num_dims )
    implicit none
    class(linear_elasticity_analytical_functions_t), intent(inout)    :: this
    integer(ip), intent(in) ::  num_dims
    call this%source_term_u%set_num_dims(num_dims)
    call this%solution_function_u%set_num_dims(num_dims)
  end subroutine linear_elasticity_analytical_functions_set_num_dims

  function linear_elasticity_analytical_functions_get_source_term_u ( this )
    implicit none
    class(linear_elasticity_analytical_functions_t), target, intent(in)    :: this
    class(vector_function_t), pointer :: linear_elasticity_analytical_functions_get_source_term_u
    linear_elasticity_analytical_functions_get_source_term_u => this%source_term_u
  end function linear_elasticity_analytical_functions_get_source_term_u
  
  !===============================================================================================
  function lin_ela_analytical_functions_get_gravity_source_term_u ( this )
    implicit none
    class(linear_elasticity_analytical_functions_t), target, intent(in)    :: this
    class(vector_function_t), pointer :: lin_ela_analytical_functions_get_gravity_source_term_u
    lin_ela_analytical_functions_get_gravity_source_term_u => this%gravity_source_term_u
  end function lin_ela_analytical_functions_get_gravity_source_term_u

  function linear_elasticity_analytical_functions_get_solution_function_u ( this )
    implicit none
    class(linear_elasticity_analytical_functions_t), target, intent(in)    :: this
    class(vector_function_t), pointer :: linear_elasticity_analytical_functions_get_solution_function_u
    linear_elasticity_analytical_functions_get_solution_function_u => this%solution_function_u
  end function linear_elasticity_analytical_functions_get_solution_function_u

  !===============================================================================================
  function linear_elasticity_analytical_functions_get_zero_function_u ( this )
    implicit none
    class(linear_elasticity_analytical_functions_t), target, intent(in)    :: this
    class(vector_function_t), pointer :: linear_elasticity_analytical_functions_get_zero_function_u
    linear_elasticity_analytical_functions_get_zero_function_u => this%zero_u
  end function linear_elasticity_analytical_functions_get_zero_function_u
  
end module linear_elasticity_analytical_functions_names
!***************************************************************************************************
