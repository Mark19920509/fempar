module SB_finite_element_names
  ! Modules
  use types_names
  use memor_names
  use allocatable_array_names
  use integration_tools_names
  use reference_fe_names
  use migratory_element_names
  use triangulation_names
#ifdef memcheck
  use iso_c_binding
#endif
  implicit none
  private
# include "debug.i90"

  ! Information of each element of the FE space
  type, extends(migratory_element_t) :: finite_element_t 
     ! Reference element info          
     type(elem_topology_t), pointer :: geometry_element 
     type(p_reference_fe_t) :: geometry_reference_element
     type(p_reference_fe_t) :: reference_element
     !type(volume_integrator_pointer_t) :: integ(:) ! Pointer to integration parameters
     
     ! Local to global 
     integer(ip)     , allocatable   :: elem2dof(:,:)   ! Map from elem to dof   
     
     ! Boundary conditions
     ! In finite_element? I think it should go to the fe_space
     integer(ip), allocatable :: bc_code(:,:)   ! Boundary Condition values
     
   contains
     procedure :: size   => finite_element_size
     procedure :: pack   => finite_element_pack
     procedure :: unpack => finite_element_unpack
     procedure :: free   => finite_element_free
     procedure :: assign => finite_element_assignment

  end type finite_element_t
  
  ! Types
  public :: finite_element_t

contains
  subroutine finite_element_size (my, n)
    implicit none
    class(finite_element_t), intent(in)  :: my
    integer(ip)            , intent(out) :: n
  end subroutine finite_element_size
  
  subroutine finite_element_pack (my, n, buffer)
    implicit none
    class(finite_element_t), intent(in)  :: my
    integer(ip)            , intent(in)   :: n
    integer(ieep)            , intent(out)  :: buffer(n)
  end subroutine finite_element_pack
  
  subroutine finite_element_unpack(my, n, buffer)
    implicit none
    class(finite_element_t), intent(inout) :: my
    integer(ip)            , intent(in)     :: n
    integer(ieep)            , intent(in)     :: buffer(n)
  end subroutine finite_element_unpack
  

  subroutine finite_element_free(my)
    implicit none
    class(finite_element_t), intent(inout) :: my
  end subroutine finite_element_free

  subroutine finite_element_assignment(this,that)
    implicit none
    class(finite_element_t)   , intent(inout) :: this
    class(migratory_element_t), intent(in)    :: that
    select type(that)
    class is(finite_element_t)
       this=that
    class default
       write(*,*) 'Error calling finite_element_t assignment'
       write(*,*) 'cannot assign object of another class'
       check(.false.)
    end select
  end subroutine finite_element_assignment

end module SB_finite_element_names
