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

module h_adaptive_poisson_unfitted_analytical_functions_names
  use fempar_names
  implicit none
# include "debug.i90"
  private

  real(rp), parameter :: offset_x = -2.3
  real(rp), parameter :: offset_y = 0.0
  real(rp), parameter :: offset_z = 0.0
  real(rp), parameter :: val_k    = 4.0*PI

  type, extends(scalar_function_t) :: base_scalar_function_t
    logical     :: in_fe_space = .true.
    integer(ip) :: degree = 1
  contains
    procedure :: set_is_in_fe_space    => base_scalar_function_set_is_in_fe_space
    procedure :: set_degree            => base_scalar_function_set_degree
    procedure :: is_in_fe_space        => base_scalar_function_is_in_fe_space
  end type base_scalar_function_t
  
  type, extends(base_scalar_function_t) :: source_term_t
    private 
   contains
     procedure :: get_value_space    => source_term_get_value_space
  end type source_term_t

  type, extends(base_scalar_function_t) :: boundary_function_t
    private
   contains
     procedure :: get_value_space => boundary_function_get_value_space
  end type boundary_function_t

  type, extends(base_scalar_function_t) :: solution_function_t
    private 
   contains
     procedure :: get_value_space    => solution_function_get_value_space
     procedure :: get_gradient_space => solution_function_get_gradient_space
  end type solution_function_t

  type poisson_analytical_functions_t
     private
     type(source_term_t)       :: source_term
     type(boundary_function_t) :: boundary_function
     type(solution_function_t) :: solution_function
   contains
     procedure :: set_num_dims      => poisson_analytical_functions_set_num_dims
     procedure :: set_is_in_fe_space      => poisson_analytical_functions_set_is_in_fe_space
     procedure :: set_degree              => poisson_analytical_functions_set_degree
     procedure :: get_source_term         => poisson_analytical_functions_get_source_term
     procedure :: get_boundary_function   => poisson_analytical_functions_get_boundary_function
     procedure :: get_solution_function   => poisson_analytical_functions_get_solution_function
     procedure :: get_degree              => poisson_analytical_functions_get_degree
  end type poisson_analytical_functions_t

  public :: poisson_analytical_functions_t, base_scalar_function_t

contains  

  !==============================================================================================
  !==============================================================================================
  subroutine sol_ex001_2d_u(point,val,degree)
    implicit none
    type(point_t), intent(in)    :: point
    real(rp),      intent(inout) :: val
    integer(ip),   intent(in)    :: degree
    real(rp) :: x1, x2
    x1 = point%get(1)
    x2 = point%get(2)
    val = x1**degree + x2**degree
  end subroutine sol_ex001_2d_u

  !==============================================================================================
  subroutine sol_ex001_2d_grad_u(point,val,degree)
    implicit none
    type(point_t),        intent(in)    :: point
    type(vector_field_t), intent(inout) :: val
    integer(ip),          intent(in)    :: degree
    real(rp) :: x1, x2, g1, g2
    x1 = point%get(1)
    x2 = point%get(2)
    g1 = degree*x1**(degree-1)
    g2 = degree*x2**(degree-1)
    call val%set(1,g1)
    call val%set(2,g2)
    call val%set(3,0.0)
  end subroutine sol_ex001_2d_grad_u

  !==============================================================================================
  subroutine sol_ex001_2d_lapl_u(point,val,degree)
    implicit none
    type(point_t), intent(in)    :: point
    real(rp),      intent(inout) :: val
    integer(ip),   intent(in)    :: degree
    real(rp) :: x1, x2
    x1 = point%get(1)
    x2 = point%get(2)
    val = degree*(degree-1)*( x1**(degree-2) + x2**(degree-2) )
  end subroutine sol_ex001_2d_lapl_u

  !==============================================================================================
  !==============================================================================================
  subroutine sol_ex001_3d_u(point,val,degree)
    implicit none
    type(point_t), intent(in)    :: point
    real(rp),      intent(inout) :: val
    integer(ip),   intent(in)    :: degree
    real(rp) :: x1, x2, x3
    x1 = point%get(1)
    x2 = point%get(2)
    x3 = point%get(3)
    val = x1**degree + x2**degree + x3**degree
  end subroutine sol_ex001_3d_u

  !==============================================================================================
  subroutine sol_ex001_3d_grad_u(point,val,degree)
    implicit none
    type(point_t),        intent(in)    :: point
    type(vector_field_t), intent(inout) :: val
    integer(ip),          intent(in)    :: degree
    real(rp) :: x1, x2, x3, g1, g2, g3
    x1 = point%get(1)
    x2 = point%get(2)
    x3 = point%get(3)
    g1 = degree*x1**(degree-1)
    g2 = degree*x2**(degree-1)
    g3 = degree*x3**(degree-1)
    call val%set(1,g1)
    call val%set(2,g2)
    call val%set(3,g3)
  end subroutine sol_ex001_3d_grad_u

  !==============================================================================================
  subroutine sol_ex001_3d_lapl_u(point,val,degree)
    implicit none
    type(point_t), intent(in)    :: point
    real(rp),      intent(inout) :: val
    integer(ip),   intent(in)    :: degree
    real(rp) :: x1, x2, x3
    x1 = point%get(1)
    x2 = point%get(2)
    x3 = point%get(3)
    if (degree == 1) then
      val = 0.0
    else
      val = degree*(degree-1)*( x1**(degree-2) + x2**(degree-2) + x3**(degree-2))
    end if
  end subroutine sol_ex001_3d_lapl_u

  !==============================================================================================
  !==============================================================================================
  subroutine sol_ex002_2d_u(point,val)
    implicit none
    type(point_t), intent(in) :: point
    real(rp), intent(inout) :: val
    real(rp) :: x1, x2
    x1 = point%get(1) - offset_x
    x2 = point%get(2) - offset_y
    val = sin(val_k*(x1**2 + x2**2)**(1/2.0))
  end subroutine sol_ex002_2d_u

  !==============================================================================================
  subroutine sol_ex002_2d_grad_u(point,val)
    implicit none
    type(point_t), intent(in) :: point
    type(vector_field_t), intent(inout) :: val
    real(rp) :: x1, x2, g1, g2
    x1 = point%get(1) - offset_x
    x2 = point%get(2) - offset_y
    g1 = (val_k*x1*cos(val_k*(x1**2 + x2**2)**(1/2.0)))/(x1**2 + x2**2)**(1/2.0)
    g2 = (val_k*x2*cos(val_k*(x1**2 + x2**2)**(1/2.0)))/(x1**2 + x2**2)**(1/2.0)
    call val%set(1,g1)
    call val%set(2,g2)
    call val%set(3,0.0)
  end subroutine sol_ex002_2d_grad_u

  !==============================================================================================
  subroutine sol_ex002_2d_lapl_u(point,val)
    implicit none
    type(point_t), intent(in) :: point
    real(rp), intent(inout) :: val
    real(rp) :: x1, x2
    x1 = point%get(1) - offset_x
    x2 = point%get(2) - offset_y
    val = (2*val_k*cos(val_k*(x1**2 + x2**2)**(1/2.0)))/(x1**2 + x2**2)**(1/2.0) -&
          (val_k**2*x1**2*sin(val_k*(x1**2 + x2**2)**(1/2.0)))/(x1**2 + x2**2) -&
          (val_k**2*x2**2*sin(val_k*(x1**2 + x2**2)**(1/2.0)))/(x1**2 + x2**2) -&
          (val_k*x1**2*cos(val_k*(x1**2 + x2**2)**(1/2.0)))/(x1**2 + x2**2)**(3/2.0) -&
          (val_k*x2**2*cos(val_k*(x1**2 + x2**2)**(1/2.0)))/(x1**2 + x2**2)**(3/2.0)
  end subroutine sol_ex002_2d_lapl_u

  !==============================================================================================
  !==============================================================================================
  subroutine sol_ex002_3d_u(point,val)
    implicit none
    type(point_t), intent(in) :: point
    real(rp), intent(inout) :: val
    real(rp) :: x1, x2, x3
    x1 = point%get(1) - offset_x
    x2 = point%get(2) - offset_y
    x3 = point%get(3) - offset_z
    val = sin(val_k*(x1**2 + x2**2 + x3**2)**(1/2.0))
  end subroutine sol_ex002_3d_u

  !==============================================================================================
  subroutine sol_ex002_3d_grad_u(point,val)
    implicit none
    type(point_t), intent(in) :: point
    type(vector_field_t), intent(inout) :: val
    real(rp) :: x1, x2, x3, g1, g2, g3
    x1 = point%get(1) - offset_x
    x2 = point%get(2) - offset_y
    x3 = point%get(3) - offset_z
    g1 = (val_k*x1*cos(val_k*(x1**2 + x2**2 + x3**2)**(1/2.0)))/(x1**2 + x2**2 + x3**2)**(1/2.0)
    g2 = (val_k*x2*cos(val_k*(x1**2 + x2**2 + x3**2)**(1/2.0)))/(x1**2 + x2**2 + x3**2)**(1/2.0)
    g3 = (val_k*x3*cos(val_k*(x1**2 + x2**2 + x3**2)**(1/2.0)))/(x1**2 + x2**2 + x3**2)**(1/2.0)
    call val%set(1,g1)
    call val%set(2,g2)
    call val%set(3,g3)
  end subroutine sol_ex002_3d_grad_u

  !==============================================================================================
  subroutine sol_ex002_3d_lapl_u(point,val)
    implicit none
    type(point_t), intent(in) :: point
    real(rp), intent(inout) :: val
    real(rp) :: x1, x2, x3
    x1 = point%get(1) - offset_x
    x2 = point%get(2) - offset_y
    x3 = point%get(3) - offset_z
    val = (3*val_k*cos(val_k*(x1**2 + x2**2 + x3**2)**(1/2.0)))/(x1**2 + x2**2 + x3**2)**(1/2.0) -&
          (val_k*x1**2*cos(val_k*(x1**2 + x2**2 + x3**2)**(1/2.0)))/(x1**2 + x2**2 + x3**2)**(3/2.0) -&
          (val_k*x2**2*cos(val_k*(x1**2 + x2**2 + x3**2)**(1/2.0)))/(x1**2 + x2**2 + x3**2)**(3/2.0) -&
          (val_k*x3**2*cos(val_k*(x1**2 + x2**2 + x3**2)**(1/2.0)))/(x1**2 + x2**2 + x3**2)**(3/2.0) -&
          (val_k**2*x1**2*sin(val_k*(x1**2 + x2**2 + x3**2)**(1/2.0)))/(x1**2 + x2**2 + x3**2) -&
          (val_k**2*x2**2*sin(val_k*(x1**2 + x2**2 + x3**2)**(1/2.0)))/(x1**2 + x2**2 + x3**2) -&
          (val_k**2*x3**2*sin(val_k*(x1**2 + x2**2 + x3**2)**(1/2.0)))/(x1**2 + x2**2 + x3**2)
  end subroutine sol_ex002_3d_lapl_u

  !===============================================================================================
  subroutine base_scalar_function_set_is_in_fe_space(this,val)
    implicit none
    class(base_scalar_function_t), intent(inout)    :: this
    logical,                       intent(in)       :: val
    this%in_fe_space = val
  end subroutine base_scalar_function_set_is_in_fe_space

  !===============================================================================================
  subroutine base_scalar_function_set_degree(this,degree)
    implicit none
    class(base_scalar_function_t), intent(inout)    :: this
    integer(ip),                   intent(in)       :: degree
    this%degree = degree
  end subroutine base_scalar_function_set_degree

  !===============================================================================================
  function base_scalar_function_is_in_fe_space(this)
    implicit none
    class(base_scalar_function_t), intent(in)    :: this
    logical :: base_scalar_function_is_in_fe_space 
    base_scalar_function_is_in_fe_space = this%in_fe_space
  end function base_scalar_function_is_in_fe_space

  !===============================================================================================
  subroutine source_term_get_value_space ( this, point, result )
    implicit none
    class(source_term_t), intent(in)    :: this
    type(point_t)       , intent(in)    :: point
    real(rp)            , intent(inout) :: result
    assert ( this%get_num_dims() == 2 .or. this%get_num_dims() == 3 )
    if ( this%get_num_dims() == 2 ) then
      if (this%is_in_fe_space()) then
        call sol_ex001_2d_lapl_u(point,result,this%degree)
        result = -1.0*result
      else
        call sol_ex002_2d_lapl_u(point,result)
        result = -1.0*result
      end if
    else if ( this%get_num_dims() == 3 ) then
      if (this%is_in_fe_space()) then
        call sol_ex001_3d_lapl_u(point,result,this%degree)
        result = -1.0*result
      else
        call sol_ex002_3d_lapl_u(point,result)
        result = -1.0*result
      end if
    end if  
  end subroutine source_term_get_value_space

  !===============================================================================================
  subroutine boundary_function_get_value_space ( this, point, result )
    implicit none
    class(boundary_function_t), intent(in)  :: this
    type(point_t)           , intent(in)    :: point
    real(rp)                , intent(inout) :: result
    assert ( this%get_num_dims() == 2 .or. this%get_num_dims() == 3 )
    if ( this%get_num_dims() == 2 ) then
      if (this%is_in_fe_space()) then
        call sol_ex001_2d_u(point,result,this%degree)
      else
        call sol_ex002_2d_u(point,result)
      end if
    else if ( this%get_num_dims() == 3 ) then
      if (this%is_in_fe_space()) then
        call sol_ex001_3d_u(point,result,this%degree)
      else
        call sol_ex002_3d_u(point,result)
      end if
    end if  
  end subroutine boundary_function_get_value_space 

  !===============================================================================================
  subroutine solution_function_get_value_space ( this, point, result )
    implicit none
    class(solution_function_t), intent(in)    :: this
    type(point_t)             , intent(in)    :: point
    real(rp)                  , intent(inout) :: result
    assert ( this%get_num_dims() == 2 .or. this%get_num_dims() == 3 )
    if ( this%get_num_dims() == 2 ) then
      if (this%is_in_fe_space()) then
        call sol_ex001_2d_u(point,result,this%degree)
      else
        call sol_ex002_2d_u(point,result)
      end if
    else if ( this%get_num_dims() == 3 ) then
      if (this%is_in_fe_space()) then
        call sol_ex001_3d_u(point,result,this%degree)
      else
        call sol_ex002_3d_u(point,result)
      end if
    end if  
  end subroutine solution_function_get_value_space
  
  !===============================================================================================
  subroutine solution_function_get_gradient_space ( this, point, result )
    implicit none
    class(solution_function_t), intent(in)    :: this
    type(point_t)             , intent(in)    :: point
    type(vector_field_t)      , intent(inout) :: result
    assert ( this%get_num_dims() == 2 .or. this%get_num_dims() == 3 )
    if ( this%get_num_dims() == 2 ) then
      if (this%is_in_fe_space()) then
        call sol_ex001_2d_grad_u(point,result,this%degree)
      else
        call sol_ex002_2d_grad_u(point,result)
      end if
    else if ( this%get_num_dims() == 3 ) then
      if (this%is_in_fe_space()) then
        call sol_ex001_3d_grad_u(point,result,this%degree)
      else
        call sol_ex002_3d_grad_u(point,result)
      end if
    end if  
  end subroutine solution_function_get_gradient_space
  
  !===============================================================================================
  subroutine poisson_analytical_functions_set_num_dims ( this, num_dims )
    implicit none
    class(poisson_analytical_functions_t), intent(inout)    :: this
    integer(ip), intent(in) ::  num_dims
    call this%source_term%set_num_dims(num_dims)
    call this%boundary_function%set_num_dims(num_dims)
    call this%solution_function%set_num_dims(num_dims)
  end subroutine poisson_analytical_functions_set_num_dims 

  !===============================================================================================
  subroutine poisson_analytical_functions_set_is_in_fe_space(this,val)
    implicit none
    class(poisson_analytical_functions_t), intent(inout)    :: this
    logical, intent(in) :: val
    call this%source_term      %set_is_in_fe_space(val)
    call this%boundary_function%set_is_in_fe_space(val)
    call this%solution_function%set_is_in_fe_space(val)
  end subroutine poisson_analytical_functions_set_is_in_fe_space

  !===============================================================================================
  subroutine poisson_analytical_functions_set_degree(this,degree)
    implicit none
    class(poisson_analytical_functions_t), intent(inout) :: this
    integer(ip),                                    intent(in)    :: degree
    call this%source_term      %set_degree(degree)
    call this%boundary_function%set_degree(degree)
    call this%solution_function%set_degree(degree)
  end subroutine poisson_analytical_functions_set_degree
  
  !===============================================================================================
  function poisson_analytical_functions_get_source_term ( this )
    implicit none
    class(poisson_analytical_functions_t), target, intent(in)    :: this
    class(scalar_function_t), pointer :: poisson_analytical_functions_get_source_term
    poisson_analytical_functions_get_source_term => this%source_term
  end function poisson_analytical_functions_get_source_term
  
  !===============================================================================================
  function poisson_analytical_functions_get_boundary_function ( this )
    implicit none
    class(poisson_analytical_functions_t), target, intent(in)    :: this
    class(scalar_function_t), pointer :: poisson_analytical_functions_get_boundary_function
    poisson_analytical_functions_get_boundary_function => this%boundary_function
  end function poisson_analytical_functions_get_boundary_function
  
  !===============================================================================================
  function poisson_analytical_functions_get_solution_function ( this )
    implicit none
    class(poisson_analytical_functions_t), target, intent(in)    :: this
    class(scalar_function_t), pointer :: poisson_analytical_functions_get_solution_function
    poisson_analytical_functions_get_solution_function => this%solution_function
  end function poisson_analytical_functions_get_solution_function
  
  !===============================================================================================
  function poisson_analytical_functions_get_degree(this)
    implicit none
    class(poisson_analytical_functions_t), intent(in)    :: this
    integer(ip) :: poisson_analytical_functions_get_degree
    poisson_analytical_functions_get_degree = this%source_term%degree
  end function poisson_analytical_functions_get_degree

end module h_adaptive_poisson_unfitted_analytical_functions_names
!***************************************************************************************************
