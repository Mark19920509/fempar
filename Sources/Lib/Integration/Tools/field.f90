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
module field_names
  use types_names
  use memor_names
#ifdef memcheck
  use iso_c_binding
#endif
  implicit none
# include "debug.i90"
  private


  
  type :: vector_field_t
     private
     real(rp) :: value(SPACE_DIM) = 0.0_rp
   contains
     procedure, non_overridable :: vector_field_init_with_scalar
     procedure, non_overridable :: vector_field_init_with_array
     generic :: init  => vector_field_init_with_scalar, vector_field_init_with_array
     procedure, non_overridable :: set       => vector_field_set
     procedure, non_overridable :: get       => vector_field_get
     procedure, non_overridable :: vector_field_add_scalar
     procedure, non_overridable :: vector_field_add_array
     generic :: add  => vector_field_add_scalar, vector_field_add_array
     procedure, non_overridable :: nrm2      => vector_field_nrm2
     procedure, non_overridable :: get_value => vector_field_get_value
  end type vector_field_t
  
  type allocatable_array_vector_field_t
    private
    type(vector_field_t), allocatable :: a(:)
  contains
    procedure, non_overridable :: create         => allocatable_array_vector_field_create
    procedure, non_overridable :: free           => allocatable_array_vector_field_free
    procedure, non_overridable :: move_alloc_out => allocatable_array_vector_field_move_alloc_out
    procedure, non_overridable :: move_alloc_in  => allocatable_array_vector_field_move_alloc_in
    procedure, non_overridable :: get_array      => allocatable_array_vector_field_get_array
  end type allocatable_array_vector_field_t
  
  interface vector_field_t
    module procedure vector_field_constructor_with_scalar, &
                     vector_field_constructor_with_array
  end interface

  type :: tensor_field_t
     private
     real(rp)  :: value(SPACE_DIM,SPACE_DIM) = 0.0_rp
   contains
     procedure, non_overridable :: tensor_field_init_with_scalar
     procedure, non_overridable :: tensor_field_init_with_array
     generic :: init  => tensor_field_init_with_scalar, tensor_field_init_with_array
     procedure, non_overridable :: set   => tensor_field_set
     procedure, non_overridable :: get   => tensor_field_get
     procedure, non_overridable :: add   => tensor_field_add
  end type tensor_field_t
  
  type allocatable_array_tensor_field_t
    private
    type(tensor_field_t), allocatable :: a(:)
  contains
    procedure, non_overridable :: create         => allocatable_array_tensor_field_create
    procedure, non_overridable :: free           => allocatable_array_tensor_field_free
    procedure, non_overridable :: move_alloc_out => allocatable_array_tensor_field_move_alloc_out
    procedure, non_overridable :: move_alloc_in  => allocatable_array_tensor_field_move_alloc_in
    procedure, non_overridable :: get_array      => allocatable_array_tensor_field_get_array
  end type allocatable_array_tensor_field_t
  
  type :: symmetric_tensor_field_t
     private
     real(rp)  :: value(SPACE_DIM,SPACE_DIM)
   contains			
     procedure, non_overridable :: init  => symmetric_tensor_field_init
     procedure, non_overridable :: set   => symmetric_tensor_field_set					
  end type symmetric_tensor_field_t

  type, extends(vector_field_t) :: point_t
  end type point_t

  interface operator(*)
     module procedure single_contract_vector_vector, single_contract_tensor_vector, &
                      single_contract_vector_tensor, single_contract_tensor_tensor
     module procedure scal_left_vector, scal_right_vector, scal_left_tensor, scal_right_tensor
  end interface operator(*)

  interface operator(*)
     module procedure scal_left_point, scal_right_point
  end interface operator(*)

  interface operator(+)
     module procedure sum_point_point, sum_point_vector, sum_vector_vector, sum_tensor_tensor
  end interface operator(+)

  interface operator(-)
     module procedure sub_point_point, sub_point_vector, sub_vector_vector, sub_tensor_tensor
  end interface operator(-)

  interface assignment(=)
     module procedure assign_scalar_to_vector, assign_vector_to_point, assign_scalar_to_point, &
          &           assign_vector_to_vector, assign_tensor_to_tensor
  end interface assignment(=)

  interface double_contract
     module procedure double_contract_tensor_tensor
  end interface double_contract

  public :: vector_field_t, tensor_field_t, symmetric_tensor_field_t, point_t 
  public :: allocatable_array_vector_field_t, allocatable_array_tensor_field_t
  public :: operator(*), operator(+), operator(-), assignment(=)
  public :: double_contract, cross_product
  
# define var_attr allocatable, target
# define point(a,b) call move_alloc(a,b)
# define generic_status_test             allocated
# define generic_memalloc_interface      memalloc
# define generic_memrealloc_interface    memrealloc
# define generic_memfree_interface       memfree
# define generic_memmovealloc_interface  memmovealloc

# define var_type type(point_t)
# define var_size 8*SPACE_DIM
# define bound_kind ip
# include "mem_header.i90"
  public :: memalloc,  memrealloc,  memfree, memmovealloc
 
contains

# include "mem_body.i90"

  function vector_field_get_value(this)
    implicit none
    class(vector_field_t), intent(in) :: this
    real(rp) :: vector_field_get_value(SPACE_DIM)
    vector_field_get_value = this%value
  end function vector_field_get_value

  subroutine vector_field_init_with_scalar(this,value)
    implicit none
    class(vector_field_t), intent(inout) :: this
    real(rp)             , intent(in)    :: value
    this%value = value
  end subroutine vector_field_init_with_scalar

  subroutine vector_field_init_with_array(this,value)
    implicit none
    class(vector_field_t), intent(inout) :: this
    real(rp)             , intent(in)    :: value(SPACE_DIM)
    this%value = value
  end subroutine vector_field_init_with_array

  subroutine vector_field_set(this,i,value)
    implicit none
    class(vector_field_t), intent(inout) :: this
    integer(ip)          , intent(in)    :: i
    real(rp)             , intent(in)    :: value
    this%value(i) = value
  end subroutine vector_field_set

  function vector_field_get(this,i) result(value)
    implicit none
    class(vector_field_t), intent(in) :: this
    integer(ip)          , intent(in) :: i
    real(rp)                          :: value
    value = this%value(i)
  end function vector_field_get

  subroutine vector_field_add_scalar(this,i,value)
    implicit none
    class(vector_field_t), intent(inout) :: this
    integer(ip)          , intent(in)    :: i
    real(rp)             , intent(in)    :: value
    this%value(i) = this%value(i) + value
  end subroutine vector_field_add_scalar
  
  subroutine vector_field_add_array(this,value)
    implicit none
    class(vector_field_t), intent(inout) :: this
    real(rp)             , intent(in)    :: value(SPACE_DIM)
    this%value = this%value + value
  end subroutine vector_field_add_array

  function vector_field_nrm2(this)
    implicit none
    class(vector_field_t), intent(inout) :: this
    real(rp) :: vector_field_nrm2
    vector_field_nrm2 = this * this
    vector_field_nrm2 = sqrt(vector_field_nrm2)
  end function vector_field_nrm2
  
  ! This constructor should be used with care. In a 2D simulation,
  ! and assuming that FEMPAR was compiled with parameter constant
  ! number_space_dimensions == 3, then this function will also fill
  ! with a nonzero value the third component of new_vector_field
  ! (obviously if value/= 0.0_rp). This may cause trouble if the
  ! code that consumes the resulting type(vector_field_t) also 
  ! accesses the third component, as e.g., happens with all operations
  ! among vectors and tensors (single_contration, double_contraction,etc.).
  function vector_field_constructor_with_scalar(value) result(new_vector_field)
    implicit none
    real(rp), intent(in) :: value
    type(vector_field_t) :: new_vector_field
    call new_vector_field%init(value)
  end function vector_field_constructor_with_scalar
  
  function vector_field_constructor_with_array(value) result(new_vector_field)
    implicit none
    real(rp), intent(in) :: value(SPACE_DIM)
    type(vector_field_t) :: new_vector_field
    call new_vector_field%init(value)
  end function vector_field_constructor_with_array
  
  subroutine allocatable_array_vector_field_create ( this, size )
    implicit none
    class(allocatable_array_vector_field_t), intent(inout) :: this
    integer(ip)          , intent(in)    :: size
     integer(ip) :: istat
    call this%free()
    allocate(this%a(size), stat=istat); check(istat==0)
  end subroutine allocatable_array_vector_field_create
 
  subroutine allocatable_array_vector_field_free ( this )
    implicit none
    class(allocatable_array_vector_field_t), intent(inout) :: this
    integer(ip) :: istat
    if (allocated(this%a)) then
      deallocate(this%a, stat=istat); check(istat==0);
    end if
  end subroutine allocatable_array_vector_field_free
  
  subroutine allocatable_array_vector_field_move_alloc_out(this, a)
    implicit none
    class(allocatable_array_vector_field_t), intent(inout) :: this
    type(vector_field_t), allocatable      , intent(inout) :: a(:)
    assert (.not. allocated (a))
    !assert (allocated(this%a))
    call move_alloc(from=this%a, to=a) 
  end subroutine allocatable_array_vector_field_move_alloc_out
  
  subroutine allocatable_array_vector_field_move_alloc_in(this, a)
    implicit none
    class(allocatable_array_vector_field_t), intent(inout) :: this
    type(vector_field_t), allocatable      , intent(inout) :: a(:)
    !assert (allocated (a))
    assert (.not. allocated(this%a))
    call move_alloc(from=a, to=this%a) 
  end subroutine allocatable_array_vector_field_move_alloc_in
  
  function allocatable_array_vector_field_get_array(this)
    implicit none
    class(allocatable_array_vector_field_t), target , intent(in) :: this
    type(vector_field_t)                   , pointer :: allocatable_array_vector_field_get_array(:)
    allocatable_array_vector_field_get_array => this%a
  end function allocatable_array_vector_field_get_array
  
  subroutine tensor_field_init_with_scalar(this,value)
    implicit none
    class(tensor_field_t), intent(inout) :: this
    real(rp)             , intent(in)    :: value
    this%value = value
  end subroutine tensor_field_init_with_scalar
  
  subroutine tensor_field_init_with_array(this,value)
    implicit none
    class(tensor_field_t), intent(inout) :: this
    real(rp)             , intent(in)    :: value(SPACE_DIM,SPACE_DIM)
    this%value = value
  end subroutine tensor_field_init_with_array

  subroutine tensor_field_set(this,i,j,value)
    implicit none
    class(tensor_field_t), intent(inout) :: this
    integer(ip)          , intent(in)    :: i
    integer(ip)          , intent(in)    :: j
    real(rp)             , intent(in)    :: value
    this%value(i,j) = value
  end subroutine tensor_field_set

  function tensor_field_get(this,i,j) result(value)
    implicit none
    class(tensor_field_t), intent(in) :: this
    integer(ip)          , intent(in) :: i
    integer(ip)          , intent(in) :: j
    real(rp)                          :: value
    value = this%value(i,j)
  end function tensor_field_get

  subroutine tensor_field_add(this,i,j,value)
    implicit none
    class(tensor_field_t), intent(inout) :: this
    integer(ip)          , intent(in)    :: i, j
    real(rp)             , intent(in)    :: value
    this%value(i,j) = this%value(i,j) + value
  end subroutine tensor_field_add
  
  subroutine allocatable_array_tensor_field_create ( this, size )
    implicit none
    class(allocatable_array_tensor_field_t), intent(inout) :: this
    integer(ip)          , intent(in)    :: size
     integer(ip) :: istat
    call this%free()
    allocate(this%a(size), stat=istat); check(istat==0)
  end subroutine allocatable_array_tensor_field_create
 
  subroutine allocatable_array_tensor_field_free ( this )
    implicit none
    class(allocatable_array_tensor_field_t), intent(inout) :: this
    integer(ip) :: istat
    if (allocated(this%a)) then
      deallocate(this%a, stat=istat); check(istat==0);
    end if
  end subroutine allocatable_array_tensor_field_free
  
  subroutine allocatable_array_tensor_field_move_alloc_out(this, a)
    implicit none
    class(allocatable_array_tensor_field_t), intent(inout) :: this
    type(tensor_field_t), allocatable      , intent(inout) :: a(:)
    assert (.not. allocated (a))
    !assert (allocated(this%a))
    call move_alloc(from=this%a, to=a) 
  end subroutine allocatable_array_tensor_field_move_alloc_out
  
  subroutine allocatable_array_tensor_field_move_alloc_in(this, a)
    implicit none
    class(allocatable_array_tensor_field_t), intent(inout) :: this
    type(tensor_field_t), allocatable      , intent(inout) :: a(:)
    !assert (allocated (a))
    assert (.not. allocated(this%a))
    call move_alloc(from=a, to=this%a) 
  end subroutine allocatable_array_tensor_field_move_alloc_in
  
  function allocatable_array_tensor_field_get_array(this)
    implicit none
    class(allocatable_array_tensor_field_t), target , intent(in) :: this
    type(tensor_field_t)                   , pointer :: allocatable_array_tensor_field_get_array(:)
    allocatable_array_tensor_field_get_array => this%a
  end function allocatable_array_tensor_field_get_array
  
  subroutine symmetric_tensor_field_init(this,value)
    implicit none
    class(symmetric_tensor_field_t), intent(inout) :: this
    real(rp)                       , intent(in)    :: value
    this%value = value
  end subroutine symmetric_tensor_field_init

  subroutine symmetric_tensor_field_set(this,i,j,value)
    implicit none
    class(symmetric_tensor_field_t), intent(inout) :: this
    integer(ip)                    , intent(in)    :: i
    integer(ip)                    , intent(in)    :: j
    real(rp)                       , intent(in)    :: value
    assert(j>=i)
    this%value(i,j) = value
  end subroutine symmetric_tensor_field_set

  function single_contract_vector_vector(v1,v2) result(res)
    implicit none
    type(vector_field_t), intent(in) :: v1
    type(vector_field_t), intent(in) :: v2
    real(rp)                         :: res
    integer(ip) :: k
    res=0.0_rp
    do k=1,SPACE_DIM
       res = res + v1%value(k)*v2%value(k)
    end do
  end function single_contract_vector_vector

  function single_contract_tensor_vector(t,v) result(res)
    implicit none
    type(tensor_field_t), intent(in) :: t
    type(vector_field_t), intent(in) :: v
    type(vector_field_t)             :: res
    integer(ip) :: i, k
    res%value=0.0_rp
    do k=1,SPACE_DIM
       do i=1,SPACE_DIM
          res%value(i) = res%value(i) + t%value(i,k) * v%value(k)
       end do
    end do
  end function single_contract_tensor_vector

  function single_contract_vector_tensor(v,t) result(res)
    implicit none
    type(vector_field_t), intent(in) :: v
    type(tensor_field_t), intent(in) :: t
    type(vector_field_t)             :: res
    integer(ip) :: i, k
    res%value=0.0_rp
    do i=1,SPACE_DIM
       do k=1,SPACE_DIM
          res%value(i) = res%value(i) + v%value(k) * t%value(k,i)
       end do
    end do
  end function single_contract_vector_tensor

  function single_contract_tensor_tensor(t1,t2) result(res)
    implicit none
    type(tensor_field_t), intent(in) :: t1
    type(tensor_field_t), intent(in) :: t2
    type(tensor_field_t)             :: res
    integer(ip) :: i, j, k
    res%value=0.0_rp
    do i=1,SPACE_DIM
       do k=1,SPACE_DIM
          do j=1,SPACE_DIM
             res%value(i,k) = res%value(i,k) + t1%value(i,j) * t2%value(j,k)
          end do
       end do
    end do
  end function single_contract_tensor_tensor

  function scal_left_vector(alpha,v) result(res)
    implicit none
    real(rp)            , intent(in) :: alpha
    type(vector_field_t), intent(in) :: v
    type(vector_field_t)             :: res
    res%value = alpha * v%value
  end function scal_left_vector

  function scal_right_vector(v,alpha) result(res)
    implicit none
    type(vector_field_t), intent(in) :: v
    real(rp)            , intent(in) :: alpha
    type(vector_field_t)             :: res
    res%value = alpha * v%value
  end function scal_right_vector

  function scal_left_tensor(alpha,t) result(res)
    implicit none
    real(rp)            , intent(in) :: alpha
    type(tensor_field_t), intent(in) :: t
    type(tensor_field_t)             :: res
    res%value = alpha * t%value
  end function scal_left_tensor

  function scal_right_tensor(t,alpha) result(res)
    implicit none
    type(tensor_field_t), intent(in) :: t
    real(rp)            , intent(in) :: alpha
    type(tensor_field_t)             :: res
    res%value = alpha * t%value
  end function scal_right_tensor

  function double_contract_tensor_tensor(t1,t2) result(res)
    implicit none
    type(tensor_field_t), intent(in) :: t1
    type(tensor_field_t), intent(in) :: t2
    real(rp)                         :: res
    integer(ip) :: i, j
    res = 0.0_rp
    do j=1, SPACE_DIM
       do i=1,SPACE_DIM
          res = res + t1%value(i,j)*t2%value(i,j)
       end do
    end do
  end function double_contract_tensor_tensor

  function scal_left_point(alpha,v) result(res)
    implicit none
    real(rp)            , intent(in) :: alpha
    type(point_t), intent(in) :: v
    type(vector_field_t)             :: res
    res%value = alpha * v%value
  end function scal_left_point

  function scal_right_point(v,alpha) result(res)
    implicit none
    type(point_t), intent(in) :: v
    real(rp)     , intent(in) :: alpha
    type(vector_field_t)             :: res
    res%value = alpha * v%value
  end function scal_right_point

  function sum_vector_vector ( vector1, vector2) result(vector_sum)
    implicit none
    type(vector_field_t), intent(in) :: vector1, vector2
    type(vector_field_t) :: vector_sum

    vector_sum%value = vector1%value + vector2%value
  end function sum_vector_vector

  function sum_point_point ( point1, point2) result(point_sum)
    implicit none
    type(point_t), intent(in) :: point1, point2
    type(point_t) :: point_sum

    point_sum%value = point1%value + point2%value
  end function sum_point_point

  function sum_point_vector ( point, vector) result(vector_sum)
    implicit none
    type(point_t), intent(in) :: point
    type(vector_field_t), intent(in) :: vector
    type(vector_field_t) :: vector_sum

    vector_sum%value = point%value + vector%value
  end function sum_point_vector

  function sum_tensor_tensor ( tensor1, tensor2) result(tensor_sum)
    implicit none
    type(tensor_field_t), intent(in) :: tensor1, tensor2
    type(tensor_field_t) :: tensor_sum

    tensor_sum%value = tensor1%value + tensor2%value
  end function sum_tensor_tensor

  function sub_point_point (point1,point2) result(vector_sub)
    implicit none
    type(point_t), intent(in) :: point1, point2
    type(vector_field_t) :: vector_sub

    vector_sub%value = point1%value - point2%value
  end function sub_point_point

  function sub_point_vector ( point, vector) result(vector_sub)
    implicit none
    type(point_t)       , intent(in) :: point
    type(vector_field_t), intent(in) :: vector
    type(vector_field_t) :: vector_sub

    vector_sub%value = point%value - vector%value
  end function sub_point_vector

  function sub_vector_vector ( vector1, vector2) result(vector_sub)
    implicit none
    type(vector_field_t), intent(in) :: vector1, vector2
    type(vector_field_t):: vector_sub

    vector_sub%value = vector1%value - vector2%value
  end function sub_vector_vector
  
  function sub_tensor_tensor ( tensor1, tensor2) result(tensor_sub)
    implicit none
    type(tensor_field_t), intent(in) :: tensor1, tensor2
    type(tensor_field_t):: tensor_sub

    tensor_sub%value = tensor1%value - tensor2%value
  end function sub_tensor_tensor
  
  subroutine assign_scalar_to_point ( point, scalar )
    implicit none
    type(point_t), intent(out) :: point
    real(rp)     , intent(in)  :: scalar
    point%value = scalar
  end subroutine assign_scalar_to_point

  subroutine assign_scalar_to_vector ( vector, scalar )
    implicit none
    type(vector_field_t), intent(out) :: vector
    real(rp)     , intent(in)  :: scalar
    vector%value = scalar
  end subroutine assign_scalar_to_vector

  subroutine assign_vector_to_vector( vector1, vector2 )
    implicit none
    type(vector_field_t), intent(out) :: vector1
    type(vector_field_t), intent(in)  :: vector2
    vector1%value = vector2%value
  end subroutine assign_vector_to_vector

  subroutine assign_vector_to_point( point, vector )
    implicit none
    type(point_t), intent(out) :: point
    type(vector_field_t), intent(in) :: vector
    point%value = vector%value
  end subroutine assign_vector_to_point

  subroutine assign_tensor_to_tensor( tensor1, tensor2 )
    implicit none
    type(tensor_field_t), intent(out) :: tensor1
    type(tensor_field_t), intent(in)  :: tensor2
    tensor1%value = tensor2%value
  end subroutine assign_tensor_to_tensor
  
  function cross_product(v1,v2) result(res)
    implicit none
    type(vector_field_t), intent(in) :: v1
    type(vector_field_t), intent(in) :: v2
    type(vector_field_t) :: res
    call res%set(1,v1%value(2)*v2%value(3)-v1%value(3)*v2%value(2))
    call res%set(2,v1%value(3)*v2%value(1)-v1%value(1)*v2%value(3))
    call res%set(3,v1%value(1)*v2%value(2)-v1%value(2)*v2%value(1))
  end function cross_product

end module field_names




