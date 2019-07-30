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
module base_iterative_linear_solver_names
  use types_names
  use stdio_names
  use memor_names
  
  ! Abstract modules
  use vector_names
  use vector_space_names
  use operator_names
  use environment_names
  use iterative_linear_solver_parameters_names
  use FPL

  implicit none
# include "debug.i90"
  private
  
  integer(ip), parameter :: start               = 0  ! All parameters set with values, environment and name set
  integer(ip), parameter :: operators_set       = 1  ! Matrix A and preconditioner M already set
  integer(ip), parameter :: workspace_allocated = 2  ! All workspace required by solve TBP available 
  
  ! State transition diagram for type(base_iterative_linear_solver_t)
  ! -----------------------------------------------------------
  ! Input State         | Action                 | Output State 
  ! -----------------------------------------------------------
  ! start               | set_parameters_from_pl | start
  ! start               | set_operators          | operators_set
  ! start               | free                   | start
  ! operators_set       | set_operators          | operators_set
  ! operators_set       | set_parameters_from_pl | operators_set
  ! operators_set       | free                   | start 
  ! operators_set       | solve                  | workspace_allocated
  ! workspace_allocated | solve                  | workspace_allocated
  ! workspace_allocated | set_parameters_from_pl | workspace_allocated
  ! workspace_allocated | free                   | start 
    
  type, abstract :: base_iterative_linear_solver_t
    private
    
    ! Properties
    class(environment_t), pointer     :: environment
    character(len=:)    , allocatable :: name
    integer(ip)                       :: state 
  
    ! Matrix and preconditioner
    type(lvalue_operator_t) :: A 
    type(lvalue_operator_t) :: M 
    
    ! Initial solution
    class(vector_t), allocatable :: initial_solution
    logical                      :: user_has_called_set_initial_solution = .false.
  
    ! Parameters
    integer(ip)               :: luout                     ! Logical Unit Output
    real(rp)                  :: rtol                      ! Relative tolerance
    real(rp)                  :: atol                      ! Absolute tolerance
    character(:), allocatable :: stopping_criteria         ! Stopping criteria
    integer(ip)               :: output_frequency          ! Message every output_frequency iterations
    integer(ip)               :: max_num_iterations        ! Max. # of iterations
    logical                   :: track_convergence_history ! Is the convergence history going to be tracked? 
    
    ! Outputs
    logical               :: did_converge          ! Converged?
    integer(ip)           :: num_iterations        ! # of iterations to convergence
    real(rp)              :: rhs_convergence_test     
    real(rp)              :: rhs_extra_convergence_test     
    real(rp)              :: error_estimate_convergence_test
    real(rp)              :: error_estimate_extra_convergence_test
    real(rp), allocatable :: error_estimate_history_convergence_test(:)
    real(rp), allocatable :: error_estimate_history_extra_convergence_test(:)
  contains
    procedure :: set_environment
    procedure :: get_environment
    procedure :: set_name
    procedure :: set_state
    procedure :: get_state
    procedure :: set_operators
    procedure :: are_A_and_M_vector_spaces_compatible
    procedure :: reallocate_after_remesh
    procedure :: set_initial_solution
    procedure :: get_initial_solution
    procedure :: get_A
    procedure :: get_M
    
    ! Paremeters getters
    procedure :: get_luout
    procedure :: get_rtol
    procedure :: get_atol    
    procedure :: get_stopping_criteria
    procedure :: get_output_frequency
    procedure :: get_max_num_iterations
    procedure :: get_track_convergence_history   
    
    ! Outputs that might be relevant to clients of this data type, in particular,
    ! type(iterative_linear_solver_t)
    procedure :: converged
    procedure :: get_num_iterations
    procedure :: get_error_estimate_convergence_test
    procedure :: get_error_estimate_extra_convergence_test

    ! This set of TBPs allow indirect access to the output member variables of type(base_iterative_linear_solver_t).
    ! They could be avoided either with regular (i.e., no pointers) iterators TBPs or declaring the corresponding
    ! member variables as public. 
    procedure :: get_pointer_did_converge
    procedure :: get_pointer_num_iterations
    procedure :: get_pointer_rhs_convergence_test
    procedure :: get_pointer_rhs_extra_convergence_test
    procedure :: get_pointer_error_estimate_convergence_test
    procedure :: get_pointer_error_estimate_extra_convergence_test
    procedure :: get_pointer_error_estimate_history_convergence_test
    procedure :: get_pointer_error_estimate_history_extra_convergence_test
    
    procedure :: print_convergence_history
    procedure :: free   => base_iterative_linear_solver_free
    procedure :: solve  => base_iterative_linear_solver_solve
    
    ! Private TBPs to be called from class(base_iterative_linear_solver_t)
    procedure :: print_convergence_history_header
    procedure :: print_convergence_history_body
    procedure :: print_convergence_history_footer
    procedure :: print_convergence_history_new_line 

    procedure, private :: allocate_convergence_history
    procedure, private :: free_convergence_history
    procedure, private :: unset_operators
    procedure, private :: free_initial_solution
    
    ! "Private" TBPs to be called from data types which extend class(base_iterative_linear_solver_t)
    procedure           :: base_iterative_linear_solver_set_parameters_from_pl
    procedure           :: set_defaults
    
    ! Deferred TBPs
    procedure (allocate_workspace_interface)            , deferred :: allocate_workspace
    procedure (free_workspace_interface)                , deferred :: free_workspace
    procedure (set_parameters_from_pl_interface)        , deferred :: set_parameters_from_pl
    procedure (solve_body_interface)                    , deferred :: solve_body
    procedure (supports_stopping_criteria_interface)    , deferred :: supports_stopping_criteria
    procedure (get_default_stopping_criteria_interface) , deferred :: get_default_stopping_criteria
  end type
  
  abstract interface
    subroutine create_iterative_linear_solver_interface(environment, base_iterative_linear_solver)
      import environment_t
      import base_iterative_linear_solver_t
      implicit none
      class(environment_t),                           intent(in)    :: environment
      class(base_iterative_linear_solver_t), pointer, intent(inout) :: base_iterative_linear_solver
    end subroutine create_iterative_linear_solver_interface

    subroutine allocate_workspace_interface(this)
     import :: base_iterative_linear_solver_t
     implicit none
     class(base_iterative_linear_solver_t), intent(inout) :: this
    end subroutine allocate_workspace_interface
    
    subroutine free_workspace_interface(this)
     import :: base_iterative_linear_solver_t
     implicit none
     class(base_iterative_linear_solver_t), intent(inout) :: this
    end subroutine free_workspace_interface
   
    subroutine set_parameters_from_pl_interface(this, parameter_list)
     import :: base_iterative_linear_solver_t
     import :: ParameterList_t
     implicit none
     class(base_iterative_linear_solver_t), intent(inout) :: this
     type(ParameterList_t),                 intent(in)    :: parameter_list
    end subroutine set_parameters_from_pl_interface
    
    subroutine solve_body_interface(this,b,x)
     import :: base_iterative_linear_solver_t, vector_t
     implicit none
     class(base_iterative_linear_solver_t), intent(inout) :: this
     class(vector_t)                      , intent(in)    :: b
     class(vector_t)                      , intent(inout) :: x 
    end subroutine solve_body_interface
    
    function supports_stopping_criteria_interface(this, stopping_criteria)
       import :: base_iterative_linear_solver_t, ip
       implicit none
       class(base_iterative_linear_solver_t), intent(in) :: this
       character(len=*)                     , intent(in) :: stopping_criteria
       logical :: supports_stopping_criteria_interface
    end function supports_stopping_criteria_interface
    
    function get_default_stopping_criteria_interface(this)
       import :: base_iterative_linear_solver_t, ip
       implicit none
       class(base_iterative_linear_solver_t), intent(in) :: this
       character(len=:), allocatable :: get_default_stopping_criteria_interface
    end function get_default_stopping_criteria_interface
  end interface
  
  public :: base_iterative_linear_solver_t
  public :: create_iterative_linear_solver_interface
  
  ! State constants
  public :: start, operators_set, workspace_allocated
  
contains
    subroutine set_environment(this,environment)
     implicit none
     class(base_iterative_linear_solver_t)        , intent(inout) :: this
     class(environment_t),    target    , intent(in)    :: environment
     this%environment => environment
    end subroutine set_environment
    
    function get_environment(this)
     implicit none
     class(base_iterative_linear_solver_t), target , intent(in) :: this
     class(environment_t)       , pointer :: get_environment
     get_environment => this%environment
    end function get_environment
    
    subroutine set_name(this,name)
     implicit none
     class(base_iterative_linear_solver_t)        , intent(inout) :: this
     character(len=*)                   , intent(in)    :: name
     this%name = name
    end subroutine set_name
    
    subroutine set_state(this,state)
     implicit none
     class(base_iterative_linear_solver_t)        , intent(inout) :: this
     integer(ip)                        , intent(in)    :: state
     this%state = state
    end subroutine set_state
    
    function get_state(this)
      implicit none
      class(base_iterative_linear_solver_t), intent(in) :: this
      integer(ip) :: get_state
      get_state = this%state
    end function get_state
    
    subroutine set_operators(this,A,M)
     implicit none
     class(base_iterative_linear_solver_t) , intent(inout) :: this
     class(operator_t)           , intent(in)    :: A
     class(operator_t)           , intent(in)    :: M     
     type(vector_space_t), pointer :: A_range
     class(vector_t), pointer :: b
          
     assert(this%state == start .or. this%state == operators_set)
     
     call A%GuardTemp()
     call M%GuardTemp()
     
     this%A = A       
     this%M = M
     massert(this%are_A_and_M_vector_spaces_compatible(), "base_iterative_linear_solver_t%set_operators :: domain(A)/=domain(M) or range(A)/=range(M)")
     A_range  => this%A%get_range_vector_space()
     if ( this%state == start ) then
        call A_range%create_vector(this%initial_solution)
        call this%initial_solution%init(0.0_rp)
     else if ( this%state == operators_set ) then
        if (.not. A_range%belongs_to(this%initial_solution)) then
           call this%free_initial_solution()
           call A_range%create_vector(this%initial_solution)
           call this%initial_solution%init(0.0_rp)
           wassert(.false.,"base_iterative_linear_solver_t%set_operators :: Initial solution re-set such that it now belongs to range(A)")
           wassert(.false.,"base_iterative_linear_solver_t%set_operators :: you have to (re-)call %set_initial_solution to select an initial solution different from zero")
        end if
     end if
     this%state = operators_set
     
     call A%CleanTemp()
     call M%CleanTemp() 
    end subroutine set_operators
    
    function are_A_and_M_vector_spaces_compatible(this)
     implicit none
     class(base_iterative_linear_solver_t) , intent(in) :: this
     logical :: are_A_and_M_vector_spaces_compatible
     type(vector_space_t), pointer :: A_domain, A_range
     type(vector_space_t), pointer :: M_domain, M_range
     A_domain => this%A%get_domain_vector_space()
     A_range  => this%A%get_range_vector_space()
     M_domain => this%M%get_domain_vector_space()
     M_range  => this%M%get_range_vector_space()
     are_A_and_M_vector_spaces_compatible = .true.
     if ( .not. A_domain%equal_to(M_domain) ) then
       are_A_and_M_vector_spaces_compatible = .false.
     else if ( .not. A_range%equal_to(M_range) ) then
       are_A_and_M_vector_spaces_compatible = .false.
     end if 
    end function are_A_and_M_vector_spaces_compatible
    
    subroutine reallocate_after_remesh(this)
     implicit none
     class(base_iterative_linear_solver_t) , intent(inout) :: this
     type(vector_space_t), pointer :: A_range
     
     if ( this%state == operators_set .or. this%state == workspace_allocated ) then
       call this%A%reallocate_after_remesh()
       call this%M%reallocate_after_remesh()
       if ( .not. this%are_A_and_M_vector_spaces_compatible() ) then
         massert(.false., 'base_iterative_linear_solver_t%reallocate_after_remesh :: domain(A)/=domain(M) or range(A)/=range(M)')
       else
         A_range  => this%A%get_range_vector_space()
         call A_range%create_vector(this%initial_solution)
         call this%initial_solution%init(0.0_rp)
         wassert(.not. this%user_has_called_set_initial_solution,"base_iterative_linear_solver_t%reallocate_after_remesh :: Initial solution re-set to zero. You have to (re-)call %set_initial_solution to select an initial solution different from zero")
         if ( this%state == workspace_allocated ) then
           call this%free_workspace()
           call this%allocate_workspace()
         end if 
       end if   
     end if 
     
    end subroutine reallocate_after_remesh 
    
    subroutine set_initial_solution(this,initial_solution)
     implicit none
     class(base_iterative_linear_solver_t) , intent(inout) :: this
     class(vector_t)                       , intent(in)    :: initial_solution     
     type(vector_space_t)                  , pointer       :: A_range     
     
     assert(this%state == operators_set .or. this%state == workspace_allocated)
     call initial_solution%GuardTemp()
     A_range  => this%A%get_range_vector_space()
     if (.not. A_range%belongs_to(initial_solution)) then
       wassert(.false.,"Warning: base_iterative_linear_solver_t%set_initial_solution :: Ignoring initial solution; it does not belong to range(A)")
     else
       call this%initial_solution%copy(initial_solution)
       this%user_has_called_set_initial_solution = .true.
     end if  
     call initial_solution%CleanTemp()
    end subroutine set_initial_solution
    
    function get_initial_solution(this)
     implicit none
     class(base_iterative_linear_solver_t), target, intent(in) :: this
     class(vector_t)            , pointer :: get_initial_solution
     get_initial_solution => this%initial_solution
    end function get_initial_solution
        
    function get_A(this)
      implicit none
      class(base_iterative_linear_solver_t), target, intent(in) :: this
      type(lvalue_operator_t), pointer         :: get_A
      get_A => this%A
    end function get_A
    
    function get_M(this)
      implicit none
      class(base_iterative_linear_solver_t), target, intent(in) :: this
      class(lvalue_operator_t), pointer        :: get_M
      get_M => this%M
    end function get_M
    
    subroutine set_stopping_criteria(this,stopping_criteria)
     implicit none
     class(base_iterative_linear_solver_t)        , intent(inout) :: this
     character(*)                                 , intent(in)    :: stopping_criteria
     this%stopping_criteria = stopping_criteria
    end subroutine set_stopping_criteria
    
    function get_luout(this)
      implicit none
      class(base_iterative_linear_solver_t), intent(in) :: this
      integer(ip) :: get_luout
      get_luout = this%luout
    end function get_luout
    
    function get_rtol(this)
      implicit none
      class(base_iterative_linear_solver_t), intent(in) :: this
      real(rp) :: get_rtol
      get_rtol = this%rtol
    end function get_rtol
    
    function get_atol(this)
      implicit none
      class(base_iterative_linear_solver_t), intent(in) :: this
      real(rp) :: get_atol
      get_atol = this%atol
    end function get_atol
    
    function get_stopping_criteria(this)
      implicit none
      class(base_iterative_linear_solver_t), intent(in) :: this
      character(len=:), allocatable :: get_stopping_criteria
      get_stopping_criteria = this%stopping_criteria
    end function get_stopping_criteria
    
    function get_output_frequency(this)
      implicit none
      class(base_iterative_linear_solver_t), intent(in) :: this
      integer(ip) :: get_output_frequency
      get_output_frequency = this%output_frequency
    end function get_output_frequency
    
    function get_max_num_iterations(this)
      implicit none
      class(base_iterative_linear_solver_t), intent(in) :: this
      integer(ip) :: get_max_num_iterations
      get_max_num_iterations = this%max_num_iterations
    end function get_max_num_iterations

    function get_track_convergence_history(this)
      implicit none
      class(base_iterative_linear_solver_t), intent(in) :: this
      logical :: get_track_convergence_history
      get_track_convergence_history = this%track_convergence_history
    end function get_track_convergence_history
    
    subroutine unset_operators(this)
     implicit none
     class(base_iterative_linear_solver_t), intent(inout) :: this
     call this%A%free()
     call this%M%free() 
    end subroutine unset_operators
    
    subroutine free_initial_solution(this)
      implicit none
      class(base_iterative_linear_solver_t), intent(inout) :: this
      call this%initial_solution%free()
      deallocate(this%initial_solution)
      this%user_has_called_set_initial_solution = .false.
    end subroutine free_initial_solution
    
    function converged(this)
      implicit none
      class(base_iterative_linear_solver_t), intent(in) :: this
      logical :: converged
      converged = this%did_converge
    end function converged 
    
    function get_num_iterations(this)
      implicit none
      class(base_iterative_linear_solver_t), intent(in) :: this
      integer(ip) :: get_num_iterations
      get_num_iterations = this%num_iterations
    end function get_num_iterations

    function get_error_estimate_convergence_test(this)
      implicit none
      class(base_iterative_linear_solver_t), intent(in) :: this
      real(rp) :: get_error_estimate_convergence_test
      get_error_estimate_convergence_test = this%error_estimate_convergence_test
    end function
    
    function get_error_estimate_extra_convergence_test(this)
      implicit none
      class(base_iterative_linear_solver_t), intent(in) :: this
      real(rp) :: get_error_estimate_extra_convergence_test
      get_error_estimate_extra_convergence_test = this%error_estimate_extra_convergence_test
    end function
    
    function get_pointer_did_converge ( this )
      implicit none
      class(base_iterative_linear_solver_t), target, intent(in) :: this
      logical                               , pointer :: get_pointer_did_converge
      get_pointer_did_converge => this%did_converge
    end function 
    
    function get_pointer_num_iterations ( this )
      implicit none
      class(base_iterative_linear_solver_t), target, intent(in) :: this
      integer(ip)                , pointer :: get_pointer_num_iterations
      get_pointer_num_iterations => this%num_iterations
    end function 
    
    function get_pointer_rhs_convergence_test ( this )
      implicit none
      class(base_iterative_linear_solver_t), target, intent(in) :: this
      real(rp)                   , pointer :: get_pointer_rhs_convergence_test 
      get_pointer_rhs_convergence_test => this%rhs_convergence_test
    end function get_pointer_rhs_convergence_test
    
    function get_pointer_rhs_extra_convergence_test ( this )
      implicit none
      class(base_iterative_linear_solver_t), target, intent(in) :: this
      real(rp)                   , pointer :: get_pointer_rhs_extra_convergence_test 
      get_pointer_rhs_extra_convergence_test => this%rhs_extra_convergence_test
    end function get_pointer_rhs_extra_convergence_test
    
    function get_pointer_error_estimate_convergence_test(this)
      implicit none
      class(base_iterative_linear_solver_t), target, intent(in) :: this
      real(rp), pointer :: get_pointer_error_estimate_convergence_test
      get_pointer_error_estimate_convergence_test => this%error_estimate_convergence_test
    end function get_pointer_error_estimate_convergence_test
    
    function get_pointer_error_estimate_extra_convergence_test(this)
      implicit none
      class(base_iterative_linear_solver_t), target, intent(in) :: this
      real(rp), pointer :: get_pointer_error_estimate_extra_convergence_test
      get_pointer_error_estimate_extra_convergence_test => this%error_estimate_extra_convergence_test
    end function get_pointer_error_estimate_extra_convergence_test
    
    function get_pointer_error_estimate_history_convergence_test(this)
      implicit none
      class(base_iterative_linear_solver_t), target, intent(in) :: this
      real(rp), pointer :: get_pointer_error_estimate_history_convergence_test(:)
      get_pointer_error_estimate_history_convergence_test => this%error_estimate_history_convergence_test
    end function get_pointer_error_estimate_history_convergence_test
    
    function get_pointer_error_estimate_history_extra_convergence_test(this)
      implicit none
      class(base_iterative_linear_solver_t), target, intent(in) :: this
      real(rp), pointer :: get_pointer_error_estimate_history_extra_convergence_test(:)
      get_pointer_error_estimate_history_extra_convergence_test => this%error_estimate_history_extra_convergence_test
    end function get_pointer_error_estimate_history_extra_convergence_test
    
    subroutine print_convergence_history ( this, file_path ) 
      implicit none
      class(base_iterative_linear_solver_t), intent(in) :: this
      character(len=*)           , intent(in) :: file_path
      ! Locals
      integer(ip) :: luout
      assert ( this%state == workspace_allocated )
      if (this%environment%am_i_l1_root() .and. this%track_convergence_history) then
        luout = io_open ( file_path, 'write')
        call this%print_convergence_history_header(luout)
        call this%print_convergence_history_body(luout)
        call this%print_convergence_history_footer(luout)
        call io_close(luout)
      end if
    end subroutine print_convergence_history
        
    subroutine print_convergence_history_body ( this, luout )
      implicit none 
      ! Parameters
      class(base_iterative_linear_solver_t), intent(in) :: this
      integer(ip)                , intent(in) :: luout

      ! Local variables
      character(len=*), parameter   :: fmt1='(a,1x,i9,3(2x,es16.9))'
      character(len=*), parameter   :: fmt2='(a,1x,i9,3(2x,es16.9),3(2x,es16.9))'
      character(len=:), allocatable :: outname
      integer(ip)                   :: i
      assert ( this%state == workspace_allocated )
      assert ( this%track_convergence_history )
      assert ( this%environment%am_i_l1_root() )
      if (this%environment%am_i_l1_root()) then
        outname = this%name // ':' // '  '
        select case(this%stopping_criteria)
        case ( delta_rhs, delta_delta, res_res, res_rhs, & 
           & res_nrmgiven_rhs_nrmgiven, res_nrmgiven_res_nrmgiven )
           do i=1,this%num_iterations
             write(luout,fmt1) outname, i, this%error_estimate_history_convergence_test(i), this%rhs_convergence_test
           end do
        case ( delta_rhs_and_res_res  , delta_rhs_and_res_rhs, & 
             & delta_delta_and_res_res, delta_delta_and_res_rhs )
           do i=1,this%num_iterations
            write(luout,fmt2) outname, i, this%error_estimate_history_convergence_test(i), this%rhs_convergence_test, &
                 &                        this%error_estimate_history_extra_convergence_test(i), this%rhs_extra_convergence_test 
           end do
        end select
      end if 
    end subroutine print_convergence_history_body

    subroutine print_convergence_history_new_line ( this, luout )
      implicit none

      ! Parameters
      class(base_iterative_linear_solver_t), intent(in) :: this 
      integer(ip)                , intent(in) :: luout

      ! Local variables
      character(len=*), parameter   :: fmt1='(a,1x,i9,3(2x,es16.9))'
      character(len=*), parameter   :: fmt2='(a,1x,i9,3(2x,es16.9),3(2x,es16.9))'
      character(len=:), allocatable :: outname
    
       if( this%environment%am_i_l1_root().and.(this%output_frequency/=0)) then
          outname = this%name // ':' // '  '
          if ( (mod(this%num_iterations,this%output_frequency) == 0).or.this%did_converge.or.(this%num_iterations>=this%max_num_iterations)) then
             outname = this%name // ':' // '  '
             select case(this%stopping_criteria)
             case ( delta_rhs, delta_delta, res_res, res_rhs, &
                  & res_nrmgiven_rhs_nrmgiven, res_nrmgiven_res_nrmgiven )
               write(luout,fmt1) outname, this%num_iterations, this%error_estimate_convergence_test, this%rhs_convergence_test
             case ( delta_rhs_and_res_res  , delta_rhs_and_res_rhs, &
                  & delta_delta_and_res_res, delta_delta_and_res_rhs )
               write(luout,fmt2) outname, this%num_iterations, this%error_estimate_convergence_test, this%rhs_convergence_test, &
                  &  this%error_estimate_extra_convergence_test, this%rhs_extra_convergence_test
             case default
               ! Write an error message and stop ?
             end select
          end if
       endif
    end subroutine print_convergence_history_new_line 

    subroutine print_convergence_history_header( this, luout )
      implicit none
      ! Parameters
      class(base_iterative_linear_solver_t), intent(in) :: this 
      integer(ip)                , intent(in) :: luout

      ! Local variables
      character(len=*), parameter    :: fmt1='(a,1x,a9,3(2x,a15))'
      character(len=*), parameter    :: fmt2='(a,1x,a9,3(2x,a15),3(2x,a15))'
      character(len=:), allocatable  :: outname
     
      if( this%environment%am_i_l1_root().and.(this%output_frequency/=0)) then
          outname = this%name // ':' // '  '
          select case(this%stopping_criteria)
          case ( delta_rhs, delta_delta, res_res, res_rhs, res_nrmgiven_rhs_nrmgiven, &
               & res_nrmgiven_res_nrmgiven )
             write(luout,fmt1) outname,'Iteration','Error Estimate','Tolerance'
          case ( delta_rhs_and_res_res, delta_rhs_and_res_rhs,  &
                delta_delta_and_res_res, delta_delta_and_res_rhs )
             write(luout,fmt2) outname, 'Iteration', 'Error Estimate', 'Tolerance', &
                                     & 'Error Estimate', 'Tolerance'
          case default
             ! Write an error message and stop ?      
          end select
        endif
    end subroutine print_convergence_history_header 

    subroutine print_convergence_history_footer ( this, luout )
      implicit none
      ! Parameters
      class(base_iterative_linear_solver_t), intent(in) :: this
      integer(ip)                , intent(in) :: luout 
      character(len=*), parameter  :: fmt11='(a,2x,es16.9,1x,a,1x,i9,1x,a)'
      character(len=*), parameter  :: fmt12='(a,3(2x,es16.9))'
      character(len=*), parameter  :: fmt21='(a,2x,es16.9,1x,es16.9,1x,a,1x,i9,1x,a)'
      character(len=*), parameter  :: fmt22='(a,3(2x,es16.9),3(2x,es16.9))'
      
      if( this%environment%am_i_l1_root().and.(this%output_frequency/=0)) then
        select case( this%stopping_criteria )
           case ( delta_rhs,delta_delta,res_res,res_rhs,&
                & res_nrmgiven_rhs_nrmgiven, res_nrmgiven_res_nrmgiven)
             if ( this%did_converge ) then
                write(luout,fmt11) this%name //' converged to ', &
                     & this%rhs_convergence_test,' in ',this%num_iterations,' iterations. '
                write(luout,fmt12) 'Last iteration error estimate: ', this%error_estimate_convergence_test
             else
                write(luout,fmt11) this%name //' failed to converge to ', &
                          & this%rhs_convergence_test,' in ',this%num_iterations,' iterations. '
                 write(luout,fmt12) 'Last iteration error estimate: ', this%error_estimate_convergence_test
             end if
           case ( delta_rhs_and_res_res  , delta_rhs_and_res_rhs, &
                & delta_delta_and_res_res, delta_delta_and_res_rhs )
             if ( this%did_converge ) then
               write(luout,fmt21) this%name //' converged to ', &
                                & this%rhs_convergence_test, this%rhs_extra_convergence_test, ' in ', this%num_iterations ,' iterations. '
               write(luout,fmt22) 'Last iteration error estimates: ', this%error_estimate_convergence_test, this%error_estimate_extra_convergence_test
             else
               write(luout,fmt21) this%name //' failed to converge to ', &
                                & this%rhs_convergence_test, this%rhs_extra_convergence_test, ' in ', this%num_iterations ,' iterations. '
               write(luout,fmt22) 'Last iteration error estimates: ', this%error_estimate_convergence_test, this%error_estimate_extra_convergence_test
             end if
           case default
             ! Write an error message and stop ?      
           end select
         end if
    end subroutine print_convergence_history_footer 
    
    subroutine allocate_convergence_history (this)
      implicit none
      class(base_iterative_linear_solver_t), intent(inout) :: this
      if (this%environment%am_i_l1_root() .and. this%track_convergence_history) then
         if ( allocated(this%error_estimate_history_convergence_test) ) then
           if ( this%max_num_iterations /= size(this%error_estimate_history_convergence_test) ) then
             call memrealloc(this%max_num_iterations, this%error_estimate_history_convergence_test, __FILE__, __LINE__)
           end if
         else
             call memalloc(this%max_num_iterations, this%error_estimate_history_convergence_test, __FILE__, __LINE__)
         end if
         if ( allocated(this%error_estimate_history_extra_convergence_test) ) then
           if ( this%num_iterations /= size(this%error_estimate_history_extra_convergence_test) ) then
             call memrealloc(this%max_num_iterations, this%error_estimate_history_extra_convergence_test, __FILE__, __LINE__)
           end if
         else
             call memalloc(this%max_num_iterations, this%error_estimate_history_extra_convergence_test, __FILE__, __LINE__)
         end if
      end if
    end subroutine allocate_convergence_history
    
    subroutine free_convergence_history (this)
      implicit none
      class(base_iterative_linear_solver_t), intent(in) :: this
      if (this%track_convergence_history) then
         if ( allocated(this%error_estimate_history_convergence_test) ) then
             call memfree(this%error_estimate_history_convergence_test, __FILE__, __LINE__)
         end if
         if ( allocated(this%error_estimate_history_extra_convergence_test) ) then
             call memfree(this%error_estimate_history_extra_convergence_test, __FILE__, __LINE__)
         end if
      end if
    end subroutine free_convergence_history
    
    subroutine set_defaults(this)
      implicit none
      class(base_iterative_linear_solver_t), intent(inout) :: this
      this%luout                     = default_luout
      this%rtol                      = default_rtol
      this%atol                      = default_atol                            
      this%output_frequency          = default_output_frequency
      this%max_num_iterations        = default_max_num_iterations
      this%track_convergence_history = default_track_convergence_history
      this%stopping_criteria         = this%get_default_stopping_criteria()
    end subroutine set_defaults
    
    subroutine base_iterative_linear_solver_set_parameters_from_pl ( this, parameter_list )
      implicit none
      ! Parameters
      class(base_iterative_linear_solver_t), intent(inout) :: this
      type(ParameterList_t),                 intent(in)    :: parameter_list
      integer(ip)                                          :: FPLError
      ! Rtol
      if(parameter_list%isPresent(ils_rtol_key)) then
          assert(parameter_list%isAssignable(ils_rtol_key, this%rtol))
          FPLError   = parameter_list%Get(Key=ils_rtol_key, Value=this%rtol)
          assert(FPLError == 0)
      endif
      ! Atol
      if(parameter_list%isPresent(ils_atol_key)) then
          assert(parameter_list%isAssignable(ils_atol_key, this%atol))
          FPLError   = parameter_list%Get(Key=ils_atol_key, Value=this%atol)
          assert(FPLError == 0)
      endif
      ! Stopping criterias
      if(parameter_list%isPresent(ils_stopping_criterium_key)) then
          assert(parameter_list%isAssignable(ils_stopping_criterium_key, "string"))
          FPLError   = parameter_list%GetAsString(Key=ils_stopping_criterium_key, String=this%stopping_criteria)
          assert(FPLError == 0)
      endif
      ! Output frequency
      if(parameter_list%isPresent(ils_output_frequency_key)) then
          assert(parameter_list%isAssignable(ils_output_frequency_key, this%output_frequency))
          FPLError   = parameter_list%Get(Key=ils_output_frequency_key, Value=this%output_frequency)
          assert(FPLError == 0)
      endif
      ! Max num iterations
      if(parameter_list%isPresent(ils_max_num_iterations_key)) then
          assert(parameter_list%isAssignable(ils_max_num_iterations_key, this%max_num_iterations))
          FPLError   = parameter_list%Get(Key=ils_max_num_iterations_key, Value=this%max_num_iterations)
          assert(FPLError == 0)
      endif
      ! Track convergence history
      if(parameter_list%isPresent(ils_track_convergence_history_key)) then
          assert(parameter_list%isAssignable(ils_track_convergence_history_key, this%track_convergence_history))
          FPLError   = parameter_list%Get(Key=ils_track_convergence_history_key, Value=this%track_convergence_history)
          assert(FPLError == 0)
      endif
      ! Track convergence history
      if(parameter_list%isPresent(ils_luout_key)) then
          assert(parameter_list%isAssignable(ils_luout_key, this%luout))
          FPLError   = parameter_list%Get(Key=ils_luout_key, Value=this%luout)
          assert(FPLError == 0)
      endif
    end subroutine base_iterative_linear_solver_set_parameters_from_pl
    
    subroutine base_iterative_linear_solver_free(this)
      implicit none
      class(base_iterative_linear_solver_t), intent(inout) :: this
      if ( this%state == operators_set ) then
        call this%unset_operators()
        call this%free_initial_solution()
      else if ( this%state == workspace_allocated ) then
        call this%unset_operators()
        call this%free_initial_solution()
        call this%free_workspace()
        call this%free_convergence_history()
      end if
      this%state = start
    end subroutine base_iterative_linear_solver_free
    
    subroutine base_iterative_linear_solver_solve(this,b,x)
      implicit none
      class(base_iterative_linear_solver_t), intent(inout) :: this
      class(vector_t)                      , intent(in)    :: b
      class(vector_t)                      , intent(inout) :: x
      assert ( this%state == operators_set .or. this%state == workspace_allocated )
      call this%allocate_convergence_history()
      if ( this%get_state() == operators_set ) then
         call this%allocate_workspace()
      end if   
      call x%GuardTemp()
      call this%solve_body(b,x)
      call x%CleanTemp()
      this%state = workspace_allocated
    end subroutine base_iterative_linear_solver_solve
    
end module base_iterative_linear_solver_names
