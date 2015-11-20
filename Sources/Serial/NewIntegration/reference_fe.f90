module reference_fe_names
  use SB_quadrature_names 
  use SB_interpolation_names
  use allocatable_array_ip1_names
  use types_names
  implicit none
# include "debug.i90"

  private

  ! Abstract reference_fe
  type, abstract ::  reference_fe_t
     private
     character(:), allocatable :: &
          topology,               &    ! type of element, 'tet', 'quad', 'prism'...
          fe_type                      ! 'Lagrangian', 'RT', ...

     integer(ip)              ::    &        
          number_dimensions,        &        ! ndime
          order                              ! FE order

     logical                  ::    &
          continuity                         ! CG/DG case (changes ndxob)

     integer(ip)              ::    &
          number_vefs,              &        ! Number of vefs
          number_nodes,             &        ! Number of nodes
          number_vefs_dimension(5)           ! Pointer to vef for each dimension

     ! Internal-use arrays of geometrical information
     type(allocatable_array_ip1_t)  :: orientation    ! Orientation of the vefs 
     type(list_t)   :: interior_nodes_vef !ndxob      ! array of interior nodes per vef
     type(list_t)   :: nodes_vef !ntxob               ! array of all nodes per vef
     type(list_t)   :: corners_vef !crxob             ! array of corners per vef
     type(list_t)   :: vefs_vef !obxob  ! array that list_ts all the vefs in an vef (idem ntxob for p = 2)

   contains

     ! TBPs
     procedure (create_interface), deferred :: create 
     procedure :: free => reference_fe_free
     procedure :: print

     !procedure :: get_topology
     !procedure :: get_fe_type
     procedure :: set_common_data
     procedure :: set_topology
     procedure :: set_fe_type
     procedure :: get_number_dimensions
     procedure :: get_order
     procedure :: get_continuity

     procedure :: get_number_vefs
     procedure :: get_number_nodes
     procedure :: get_number_vefs_dimension
     procedure :: get_orientation
     procedure :: get_interior_nodes_vef ! returns ndxob
     procedure :: get_nodes_vef          ! returns ntxob
     procedure :: get_node_vef
     procedure :: get_interior_node_vef
     procedure :: get_corners_vef        ! returns crxob
     procedure :: get_vefs_vef           ! returns obxob
     procedure :: get_number_nodes_vef
     procedure :: get_number_interior_nodes_vef

     procedure :: get_pointer_number_vefs
     procedure :: get_pointer_number_nodes
     procedure :: get_pointer_number_vefs_dimension
     procedure :: get_pointer_orientation
     procedure :: get_pointer_interior_nodes_vef ! returns ndxob
     procedure :: get_pointer_nodes_vef          ! returns ntxob
     procedure :: get_pointer_corners_vef        ! returns crxob
     procedure :: get_pointer_vefs_vef           ! returns obxob

     procedure :: permute_nodes_per_vef

     procedure (permute_order_vef_interface), deferred :: permute_order_vef

     procedure (create_interpolation_interface), deferred :: create_interpolation 
     procedure (create_quadrature_interface), deferred :: create_quadrature

     !procedure :: get_coordinates_node  
     !procedure :: get_normal_face  

     !procedure :: permutation_nodes_vef

  end type reference_fe_t

  type p_reference_fe_t
     class(reference_fe_t), pointer :: p => NULL()      
  end type p_reference_fe_t



  abstract interface
     subroutine create_interface ( this, number_dimensions, order, continuity )
       import :: reference_fe_t, ip
       implicit none 
       class(reference_fe_t), intent(out) :: this 
       integer(ip), intent(in)  :: number_dimensions, order
       logical, optional, intent(in) :: continuity
     end subroutine create_interface
  end interface
  abstract interface
     ! Here we create the interpolation object, i.e., the value of the shape functions of the
     ! reference element on the quadrature points. 
     ! It is the new version of the shape1_hessi in interpolation.f90
     subroutine create_interpolation_interface ( this, quadrature, interpolation, compute_hessian )
       import :: reference_fe_t, SB_interpolation_t, SB_quadrature_t
       implicit none 
       class(reference_fe_t), intent(in) :: this 
       class(SB_quadrature_t), intent(in) :: quadrature
       type(SB_interpolation_t), intent(out) :: interpolation
       logical, optional, intent(in) :: compute_hessian
     end subroutine create_interpolation_interface
  end interface
  abstract interface
     ! This subroutine gives the reodering (o2n) of the nodes of an vef given an orientation 'o'
     ! and a delay 'r' wrt to a refence element sharing the same vef.
     subroutine permute_order_vef_interface( this, o2n,p,o,r,nd )
       import :: reference_fe_t, ip
       implicit none
       class(reference_fe_t), intent(in) :: this 
       integer(ip), intent(in)    :: p,o,r,nd
       integer(ip), intent(inout) :: o2n(:)
     end subroutine permute_order_vef_interface
  end interface
  ! Here all the concrete functions
  ! ...
  abstract interface
     ! Here we provide the number of Gauss points, nlocs (?), lrule, llapl, and optionally mnode
     ! lrule, ndime, ngaus are next provided in integration_tools.f90 to compute the quadrature
     ! I need to know what all this means
     ! It is the old Q_set_integ and P_set_integ in fe_space_types.f90
     ! In the new version, I would call the quadrature_create here. Further, quadrature can be 
     ! abstract with different version based on geometrical topology only.
     subroutine create_quadrature_interface ( this, quadrature, max_order )
       import :: reference_fe_t, SB_quadrature_t, ip
       implicit none 
       class(reference_fe_t), intent(in) :: this        
       integer(ip), optional, intent(in) :: max_order
       class(SB_quadrature_t), intent(out) :: quadrature
     end subroutine create_quadrature_interface
  end interface
  ! Here all the concrete functions
  ! ...


  public :: reference_fe_t, p_reference_fe_t
contains
  ! Here we create the interpolation object, i.e., the value of the shape functions of the
  ! reference element on the quadrature points. 
  ! It is the new version of the shape1_hessi in interpolation.f90		
  subroutine set_common_data( this, number_dimensions, order, continuity )
    implicit none 
    class(reference_fe_t), intent(out) :: this 
    integer(ip), intent(in)  :: number_dimensions, order
    logical, optional, intent(in) :: continuity

    this%number_dimensions = number_dimensions
    this%order = order
    if ( present( continuity) ) then
       this%continuity = continuity
    else 
       this%continuity = .true.
    end if

  end subroutine set_common_data

  subroutine set_topology( this, topology)
    implicit none
    class(reference_fe_t), intent(inout) :: this 
    character(*), intent(in) :: topology
    this%topology = topology
  end subroutine set_topology

  subroutine set_fe_type( this, fe_type)
    implicit none
    class(reference_fe_t), intent(inout) :: this 
    character(*), intent(in) :: fe_type
    this%fe_type = fe_type
  end subroutine set_fe_type

  subroutine print ( reference_fe )
    implicit none
    ! Parameters
    class(reference_fe_t),  intent(in) :: reference_fe

    integer(ip) :: i

    write(*,*) 'topology: ', reference_fe%topology
    write(*,*) 'fe_type: ', reference_fe%fe_type
    write(*,*) 'number_dimensions: ', reference_fe%number_dimensions
    write(*,*) 'order: ', reference_fe%order
    write(*,*) 'continuity: ',reference_fe%continuity
    write(*,*) 'number_vefs', reference_fe%number_vefs
    write(*,*) 'number_nodes', reference_fe%number_nodes
    write(*,*) 'number_vefs_dimension', reference_fe%number_vefs_dimension

    write(*,*) 'orientation', reference_fe%orientation%a

    write(*,*) 'interior_nodes_vef'
    do i=1,reference_fe%number_vefs+1
       write(*,*) reference_fe%interior_nodes_vef%l(reference_fe%interior_nodes_vef%p(i):reference_fe%interior_nodes_vef%p(i+1)-1)
    end do

    write(*,*) 'nodes_vef'
    do i=1,reference_fe%number_vefs+1
       write(*,*) reference_fe%nodes_vef%l(reference_fe%nodes_vef%p(i):reference_fe%nodes_vef%p(i+1)-1)
    end do

    write(*,*) 'corners_vef'
    do i=1,reference_fe%number_vefs+1
       write(*,*) reference_fe%corners_vef%l(reference_fe%corners_vef%p(i):reference_fe%corners_vef%p(i+1)-1)
    end do

    write(*,*) 'vefs_vef'
    do i=1,reference_fe%number_vefs+1
       write(*,*) reference_fe%vefs_vef%l(reference_fe%vefs_vef%p(i):reference_fe%vefs_vef%p(i+1)-1)
    end do

  end subroutine print

  function get_number_dimensions( this )
    implicit none
    class(reference_fe_t), intent(in) :: this
    integer(ip) :: get_number_dimensions
    get_number_dimensions = this%number_dimensions
  end function get_number_dimensions

  function get_order( this )
    implicit none
    class(reference_fe_t), intent(in) :: this
    integer(ip) :: get_order
    get_order = this%order
  end function get_order

  function get_continuity( this )
    implicit none
    class(reference_fe_t), intent(in) :: this
    logical :: get_continuity
    get_continuity = this%continuity
  end function get_continuity

  function get_number_vefs ( this )
    implicit none
    class(reference_fe_t), intent(in) :: this
    integer(ip)                 :: get_number_vefs
    get_number_vefs = this%number_vefs
  end function get_number_vefs

  function get_number_nodes ( this )
    implicit none
    class(reference_fe_t), intent(in) :: this
    integer(ip)                 :: get_number_nodes
    get_number_nodes = this%number_nodes
  end function get_number_nodes

  function get_number_vefs_dimension ( this )
    implicit none
    class(reference_fe_t), intent(in) :: this
    integer(ip)                 :: get_number_vefs_dimension(5)
    get_number_vefs_dimension = this%number_vefs_dimension
  end function get_number_vefs_dimension

  function get_orientation ( this )
    implicit none
    class(reference_fe_t), intent(in) :: this
    type(allocatable_array_ip1_t) :: get_orientation
    get_orientation = this%orientation
  end function get_orientation

  function get_interior_nodes_vef ( this )
    implicit none
    class(reference_fe_t), intent(in) :: this
    type(list_t) :: get_interior_nodes_vef
    get_interior_nodes_vef = this%interior_nodes_vef
  end function get_interior_nodes_vef

  function get_nodes_vef ( this )
    implicit none
    class(reference_fe_t), intent(in) :: this
    type(list_t) :: get_nodes_vef
    get_nodes_vef = this%nodes_vef
  end function get_nodes_vef

  function get_number_nodes_vef ( this, i )
    implicit none
    class(reference_fe_t), intent(in) :: this
    integer(ip) :: i
    integer(ip) :: get_number_nodes_vef
    get_number_nodes_vef = this%nodes_vef%p(i+1)-this%nodes_vef%p(i)
  end function get_number_nodes_vef

  function get_number_interior_nodes_vef ( this, i )
    implicit none
    class(reference_fe_t), intent(in) :: this
    integer(ip) :: i
    integer(ip) :: get_number_interior_nodes_vef
    get_number_interior_nodes_vef = this%interior_nodes_vef%p(i+1)-this%interior_nodes_vef%p(i)
  end function get_number_interior_nodes_vef

  function get_node_vef ( this, i, j )
    implicit none
    class(reference_fe_t), intent(in) :: this
    integer(ip) :: i, j
    integer(ip) :: get_node_vef
    get_node_vef = this%nodes_vef%l(this%nodes_vef%p(j) + i -1)
  end function get_node_vef

  function get_interior_node_vef ( this, i, j )
    implicit none
    class(reference_fe_t), intent(in) :: this
    integer(ip) :: i, j
    integer(ip) :: get_interior_node_vef
    get_interior_node_vef = this%interior_nodes_vef%l(this%interior_nodes_vef%p(j) + i -1)
  end function get_interior_node_vef

  function get_corners_vef ( this )
    implicit none
    class(reference_fe_t), intent(in) :: this
    type(list_t) :: get_corners_vef
    get_corners_vef = this%corners_vef
  end function get_corners_vef

  function get_vefs_vef ( this )
    implicit none
    class(reference_fe_t), intent(in) :: this
    type(list_t) :: get_vefs_vef
    get_vefs_vef = this%vefs_vef
  end function get_vefs_vef

  function get_pointer_number_vefs ( this )
    implicit none
    class(reference_fe_t), target, intent(in) :: this
    integer(ip)                , pointer :: get_pointer_number_vefs
    get_pointer_number_vefs => this%number_vefs
  end function get_pointer_number_vefs

  function get_pointer_number_nodes ( this )
    implicit none
    class(reference_fe_t), target, intent(in) :: this
    integer(ip)                , pointer :: get_pointer_number_nodes
    get_pointer_number_nodes => this%number_nodes
  end function get_pointer_number_nodes

  function get_pointer_number_vefs_dimension ( this )
    implicit none
    class(reference_fe_t), target, intent(in) :: this
    integer(ip)                , pointer :: get_pointer_number_vefs_dimension(:)
    get_pointer_number_vefs_dimension => this%number_vefs_dimension
  end function get_pointer_number_vefs_dimension

  function get_pointer_orientation ( this )
    implicit none
    class(reference_fe_t), target, intent(in) :: this
    type(allocatable_array_ip1_t), pointer :: get_pointer_orientation
    get_pointer_orientation => this%orientation
  end function get_pointer_orientation

  function get_pointer_interior_nodes_vef ( this )
    implicit none
    class(reference_fe_t), target, intent(in) :: this
    type(list_t), pointer :: get_pointer_interior_nodes_vef
    get_pointer_interior_nodes_vef => this%interior_nodes_vef
  end function get_pointer_interior_nodes_vef

  function get_pointer_nodes_vef ( this )
    implicit none
    class(reference_fe_t), target, intent(in) :: this
    type(list_t), pointer :: get_pointer_nodes_vef
    get_pointer_nodes_vef => this%nodes_vef
  end function get_pointer_nodes_vef

  function get_pointer_corners_vef ( this )
    implicit none
    class(reference_fe_t), target, intent(in) :: this
    type(list_t), pointer :: get_pointer_corners_vef
    get_pointer_corners_vef => this%corners_vef
  end function get_pointer_corners_vef

  function get_pointer_vefs_vef ( this )
    implicit none
    class(reference_fe_t), target, intent(in) :: this
    type(list_t), pointer :: get_pointer_vefs_vef
    get_pointer_vefs_vef => this%vefs_vef
  end function get_pointer_vefs_vef

  subroutine reference_fe_free( this )
    implicit none
    class(reference_fe_t), intent(inout) :: this

    if(allocated(this%topology))              deallocate(this%topology)
    if(allocated(this%fe_type))               deallocate(this%fe_type)

    if(allocated(this%interior_nodes_vef%p)) & 
         call memfree(this%interior_nodes_vef%p,__FILE__,__LINE__)
    if(allocated(this%interior_nodes_vef%l)) & 
         call memfree(this%interior_nodes_vef%l,__FILE__,__LINE__)
    this%interior_nodes_vef%n = 0

    if(allocated(this%nodes_vef%p)) & 
         call memfree(this%nodes_vef%p,__FILE__,__LINE__)
    if(allocated(this%nodes_vef%l)) & 
         call memfree(this%nodes_vef%l,__FILE__,__LINE__)
    this%nodes_vef%n = 0

    if(allocated(this%corners_vef%p)) & 
         call memfree(this%corners_vef%p,__FILE__,__LINE__)
    if(allocated(this%corners_vef%l)) & 
         call memfree(this%corners_vef%l,__FILE__,__LINE__)
    this%corners_vef%n = 0

    if(allocated(this%vefs_vef%p)) & 
         call memfree(this%vefs_vef%p,__FILE__,__LINE__)
    if(allocated(this%vefs_vef%l)) & 
         call memfree(this%vefs_vef%l,__FILE__,__LINE__)
    this%vefs_vef%n = 0

    call this%orientation%free()

    this%number_dimensions  = 0
    this%order       = 0
    this%number_vefs        = 0
    this%number_nodes       = 0
    this%number_vefs_dimension  = 0
    this%continuity         = .true.
  end subroutine reference_fe_free

  subroutine permute_nodes_per_vef(reference_element2,reference_element1,permu,o1,o2,ln1,ln2,od,q,subface1,subface2)
    implicit none
    ! Parameters
    class(reference_fe_t), intent(in)   :: reference_element1, reference_element2   ! Info of the elements
    integer(ip)         , intent(out)  :: permu(:) ! Permutation vector
    integer(ip)         , intent(in)   :: o1,o2    ! Local identifier of the vef in each element
    integer(ip)         , intent(in)   :: ln1(reference_element1%number_vefs), ln2(reference_element2%number_vefs) ! lnods of each vef
    integer(ip)         , intent(in)   :: od       ! Dimension of the vef
    integer(ip)         , intent(in)   :: q  
    integer(ip), optional, intent(in)  :: subface1,subface2

    ! Local variables
    integer(ip) :: i,c1,r, o=0, r0, num_corners

    ! TODO: CHECK THE R0 implementation, it is probably worng


    if (present(subface1)) then
       if (subface1 == 0) then
          r0=0
       else
          r0 = subface1 -1
       end if
       assert (subface2 == 0) 
    else
       r0 = 0
    end if

    permu = 1

    c1 = ln1(reference_element1%corners_vef%l(reference_element1%corners_vef%p(o1)+r0))  ! Global identifier of the vef of the first corner
    r = 1
    do i = reference_element2%corners_vef%p(o2),reference_element2%corners_vef%p(o2+1)-1
       if ( ln2(reference_element2%corners_vef%l(i)) == c1 ) exit
       r = r+1
    end do
    check ( ln2(reference_element2%corners_vef%l(i)) == c1 )

    if (r0>0) then
       r = r-r0
       if (r < 1) then
          num_corners = reference_element2%corners_vef%p(o2+1)- reference_element2%corners_vef%p(o2)
          r = r + num_corners 
       end if
    end if

    if (od == 2) then
       o = modulo(reference_element1%orientation%a(o1)+reference_element1%orientation%a(o2)+1,2)
    else
       o = 0
    end if

    call reference_element2%permute_order_vef( permu,q,o,r,od )

  end subroutine permute_nodes_per_vef

end module reference_fe_names