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
module poisson_conditions_names
  use serial_names
  
  implicit none
# include "debug.i90"
  private
  type, extends(new_conditions_t) :: poisson_conditions_t
     private
     type(constant_scalar_function_t) :: constant_scalar_function
   contains
     procedure :: set_constant_function_value => poisson_conditions_set_constant_function
     procedure :: get_number_components       => poisson_conditions_get_number_components  
     procedure :: get_components_code         => poisson_conditions_get_components_code
     procedure :: get_function                => poisson_conditions_get_function
  end type poisson_conditions_t
  
  public :: poisson_conditions_t
  
contains

  subroutine poisson_conditions_set_constant_function (this, value)
    implicit none
    class(poisson_conditions_t), intent(inout) :: this
    real(rp)                   , intent(in)    :: value
    this%constant_scalar_function = constant_scalar_function_t(value)
  end subroutine poisson_conditions_set_constant_function

  function poisson_conditions_get_number_components(this)
    implicit none
    class(poisson_conditions_t), intent(in) :: this
    integer(ip) :: poisson_conditions_get_number_components
    poisson_conditions_get_number_components = 1
  end function poisson_conditions_get_number_components

  subroutine poisson_conditions_get_components_code(this, boundary_id, components_code)
    implicit none
    class(poisson_conditions_t), intent(in)  :: this
    integer(ip)            , intent(in)  :: boundary_id
    logical                , intent(out) :: components_code(:)
    assert ( size(components_code) == 1 )
    components_code(1) = .true.
    if ( boundary_id == 1 ) then
      components_code(1) = .true.
    end if
  end subroutine poisson_conditions_get_components_code
  
  subroutine poisson_conditions_get_function ( this, boundary_id, component_id, function )
    implicit none
    class(poisson_conditions_t), target, intent(in)  :: this
    integer(ip)                        , intent(in)  :: boundary_id
    integer(ip)                        , intent(in)  :: component_id
    class(scalar_function_t), pointer  , intent(out) :: function
    assert ( component_id == 1 )
    nullify(function)
    if ( boundary_id == 1 ) then
      function => this%constant_scalar_function
    end if  
  end subroutine poisson_conditions_get_function 

end module poisson_conditions_names
