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
module mpi_context_names
  ! Serial modules
  use types_names
  use memor_names

  ! Parallel modules
  use execution_context_names
  use allocatable_array_names
#ifdef MPI_MOD
  use mpi
#endif
  implicit none 
#ifdef MPI_H
  include 'mpif.h'
#endif

#include "debug.i90"
  private

  
  ! Constants that define buffer types. They must be changed if
  ! our definitions in types.f90 changes.
  integer, parameter :: mpi_context_ieep = mpi_integer1
  integer, parameter :: mpi_context_ip   = mpi_integer
  integer, parameter :: mpi_context_igp  = mpi_integer8
  integer, parameter :: mpi_context_rp   = mpi_double_precision
  integer, parameter :: mpi_context_lg   = mpi_logical
  integer, parameter :: mpi_context_root = 0
  integer, parameter :: mpi_context_tag  = 1453524 ! which number should go here?
  integer :: mpi_context_status(mpi_status_size)

  ! Parallel context
  type, extends(execution_context_t) :: mpi_context_t
     private 
     ! ***IMPORTANT NOTE***: parallel contexts are always of type 
     ! integer: the kind parameter must NOT be specified. This requirement is 
     ! imposed by the underlying message-passing library, i.e., MPI. 
     ! The same comment applies to other integers in mpi interfaces (except
     ! buffers).
     logical :: created_from_mpi = .false.
     integer :: icontxt = mpi_comm_null
   contains
     ! These functions should be non_overridable but there is a bug in gfotran
     procedure :: create             => mpi_context_create
     procedure :: assign             => mpi_context_assign
     procedure :: get_icontxt        => mpi_context_get_icontxt
     procedure :: split_by_condition => mpi_context_split_by_condition
     procedure :: split_by_color     => mpi_context_split_by_color
     procedure :: free               => mpi_context_free
     procedure :: nullify            => mpi_context_nullify
     procedure :: am_i_member        => mpi_context_am_i_member
     procedure :: am_i_root          => mpi_context_am_i_root
     procedure :: barrier            => mpi_context_barrier
     procedure :: time               => mpi_context_time
     procedure :: sum_scalar_ip      => mpi_context_sum_scalar_ip
     procedure :: sum_scalar_rp      => mpi_context_sum_scalar_rp
     procedure :: sum_vector_rp      => mpi_context_sum_vector_rp
     procedure :: max_scalar_rp      => mpi_context_max_scalar_rp
     procedure :: max_vector_rp      => mpi_context_max_vector_rp
     procedure :: min_scalar_rp      => mpi_context_min_scalar_rp
     procedure :: max_scalar_ip      => mpi_context_max_scalar_ip
     procedure :: sum_scalar_igp     => mpi_context_sum_scalar_igp
     procedure :: max_scalar_igp     => mpi_context_max_scalar_igp
     procedure :: sum_vector_igp     => mpi_context_sum_vector_igp
     procedure :: max_vector_igp     => mpi_context_max_vector_igp
     procedure :: scatter_ip         => mpi_context_scatter_scalar_ip
     procedure :: gather_ip          => mpi_context_gather_scalar_ip
     procedure :: bcast_ip           => mpi_context_bcast_scalar_ip
     procedure :: bcast_ip_1D_array  => mpi_context_bcast_scalar_ip_1D_array
     procedure :: scatter_igp        => mpi_context_scatter_scalar_igp
     procedure :: gather_igp         => mpi_context_gather_scalar_igp
     procedure :: bcast_igp          => mpi_context_bcast_scalar_igp
     procedure :: bcast_subcontext   => mpi_context_bcast_subcontext
     procedure :: neighbours_exchange_rp                   => mpi_context_neighbours_exchange_rp    
     procedure :: neighbours_exchange_wo_alpha_beta_rp     => mpi_context_neighbours_exchange_wo_alpha_beta_rp
     procedure :: neighbours_exchange_wo_alpha_beta_rp_v   => mpi_context_neighbours_exchange_wo_alpha_beta_rp_v
     procedure :: neighbours_exchange_ip                   => mpi_context_neighbours_exchange_ip                 
     procedure :: neighbours_exchange_igp                  => mpi_context_neighbours_exchange_igp                
     procedure :: neighbours_exchange_single_ip            => mpi_context_neighbours_exchange_single_ip
     procedure :: neighbours_exchange_multiple_igp         => mpi_context_neighbours_exchange_multiple_igp
     procedure :: neighbours_exchange_wo_pack_unpack_ieep  => mpi_context_neighbours_exchange_wo_pack_unpack_ieep
     procedure :: neighbours_exchange_wo_unpack_ip         => mpi_context_neighbours_exchange_wo_unpack_ip
     procedure :: neighbours_exchange_variable_igp         => mpi_context_neighbours_exchange_variable_igp
     procedure :: neighbours_exchange_variable_ip          => mpi_context_neighbours_exchange_variable_ip       
     procedure :: send_ip           => mpi_context_send_ip
     procedure :: send_igp          => mpi_context_send_igp     
     procedure :: send_rp           => mpi_context_send_rp
     procedure :: send_ip_1D_array  => mpi_context_send_ip_1D_array
     procedure :: send_igp_1D_array => mpi_context_send_igp_1D_array
     procedure :: send_rp_1D_array  => mpi_context_send_rp_1D_array
     procedure :: rcv_ip            => mpi_context_rcv_ip
     procedure :: rcv_igp           => mpi_context_rcv_igp     
     procedure :: rcv_rp            => mpi_context_rcv_rp
     procedure :: rcv_ip_1D_array   => mpi_context_rcv_ip_1D_array
     procedure :: rcv_igp_1D_array  => mpi_context_rcv_igp_1D_array     
     procedure :: rcv_rp_1D_array   => mpi_context_rcv_rp_1D_array
     procedure :: root_send_master_rcv_ip          => mpi_context_root_send_master_rcv_ip
     procedure :: root_send_master_rcv_ip_1D_array => mpi_context_root_send_master_rcv_ip_1D_array
     procedure :: root_send_master_rcv_rp          => mpi_context_root_send_master_rcv_rp
     procedure :: root_send_master_rcv_rp_1D_array => mpi_context_root_send_master_rcv_rp_1D_array
     procedure :: root_send_master_rcv_logical     => mpi_context_root_send_master_rcv_logical
     procedure :: gather_to_master_ip              => mpi_context_gather_to_master_ip            
     procedure :: gather_to_master_igp             => mpi_context_gather_to_master_igp           
     procedure :: gather_to_master_ip_1D_array     => mpi_context_gather_to_master_ip_1D_array   
     procedure :: gather_to_masterv_ip_1D_array    => mpi_context_gather_to_masterv_ip_1D_array  
     procedure :: gather_to_masterv_igp_1D_array   => mpi_context_gather_to_masterv_igp_1D_array 
     procedure :: gather_to_masterv_rp_1D_array    => mpi_context_gather_to_masterv_rp_1D_array  
     procedure :: gather_to_masterv_rp_2D_array    => mpi_context_gather_to_masterv_rp_2D_array  
     procedure :: scatter_from_master_ip           => mpi_context_scatter_from_master_ip
     procedure :: scatter_from_masterv_ip_1D_array => mpi_context_scatter_from_masterv_ip_1D_array
     procedure :: scatter_from_masterv_rp_1D_array => mpi_context_scatter_from_masterv_rp_1D_array
  end type mpi_context_t

  ! Types
  public :: mpi_context_t
  
  interface
     subroutine report_bindings(Fcomm) bind(c,name='report_bindings')
       use iso_c_binding
       implicit none
       integer, value, intent(in) :: Fcomm
     end subroutine report_bindings
  end interface

contains

  !=============================================================================
  subroutine mpi_context_assign(this, that)
    implicit none 
    class(mpi_context_t)      , intent(inout) :: this
    class(execution_context_t), intent(in)    :: that
    integer  :: current_task, num_tasks, istat
    ! call this%free(finalize=.false.)
    select type(that)
    type is(mpi_context_t)
       ! Uncomment the following line for maximum checking
       ! call mpi_initialized(initialized,info); check((initialized).and.(info == mpi_success))
       assert(that%icontxt/=mpi_comm_null)
       !call mpi_comm_dup(that%icontxt,this%icontxt,istat) ; check(istat == mpi_success)
       this%icontxt=that%icontxt
       this%created_from_mpi = .false.
       assert(this%icontxt/=mpi_comm_null)
       call mpi_comm_size(this%icontxt,num_tasks,istat)   ; check(istat == mpi_success)
       call mpi_comm_rank(this%icontxt,current_task,istat); check(istat == mpi_success)
       assert(current_task==that%get_current_task())
       assert(num_tasks==that%get_num_tasks())
       call this%set_current_task(current_task)
       call this%set_num_tasks(num_tasks)
    class default
       mcheck(.false.,'Only a mpi_context_t can be assigned using this function')
    end select
  end subroutine mpi_context_assign
  
  !=============================================================================
  function mpi_context_get_icontxt(this) result(icontxt)
    class(mpi_context_t), intent(inout) :: this
    integer                             :: icontxt
    icontxt = this%icontxt
  end function mpi_context_get_icontxt

  !=============================================================================
  subroutine mpi_context_create ( this )
    implicit none 
    class(mpi_context_t), intent(inout) :: this
    integer :: current_task, num_tasks,istat
    logical :: initialized
    call this%free(finalize=.false.)
    call mpi_initialized(initialized,istat); check((.not.initialized).and.(istat == mpi_success))
    call mpi_init(istat); check(istat == mpi_success)
    call mpi_comm_dup(mpi_comm_world,this%icontxt,istat); check(istat == mpi_success)
    this%created_from_mpi = .true.
    assert(this%icontxt/=mpi_comm_null)
    call mpi_comm_size(this%icontxt,num_tasks,istat)    ; check(istat == mpi_success)
    call mpi_comm_rank(this%icontxt,current_task,istat) ; check(istat == mpi_success)
    call this%set_current_task(current_task)
    call this%set_num_tasks(num_tasks)
#ifdef DEBUG
    call report_bindings(this%icontxt)
#endif
  end subroutine mpi_context_create

  !=============================================================================
  subroutine mpi_context_split_by_color ( this, color, new_subcontext )
    implicit none 
    class(mpi_context_t), intent(in)    :: this
    integer             , intent(in)    :: color
    class(execution_context_t), allocatable , intent(inout) :: new_subcontext
    integer, parameter :: key=0
    integer :: istat, my_color, current_task,num_tasks

    if(color==undefined_color) then
       my_color = mpi_undefined
    else
       my_color = color
    end if

    if(allocated(new_subcontext)) then
       call new_subcontext%free(finalize=.false.)
    else
       allocate(new_subcontext,mold=this,stat=istat);check(istat==0)
    end if

    select type(new_subcontext)
    type is(mpi_context_t)
       call mpi_comm_split(this%icontxt, my_color, key, new_subcontext%icontxt, istat);  assert ( istat == mpi_success )
       if(new_subcontext%icontxt/=mpi_comm_null) then
          call mpi_comm_size(new_subcontext%icontxt,num_tasks,istat)    ; check(istat == mpi_success)
          call mpi_comm_rank(new_subcontext%icontxt,current_task,istat) ; check(istat == mpi_success)
       else
          current_task = -1
          num_tasks = -1
       end if
       call new_subcontext%set_current_task(current_task)
       call new_subcontext%set_num_tasks(num_tasks)
       new_subcontext%created_from_mpi = .true.
    class default
       check(.false.)
    end select

  end subroutine mpi_context_split_by_color

  !=============================================================================
  subroutine mpi_context_split_by_condition ( this, in_subcontext1, subcontext1, subcontext2 )
    implicit none 
    class(mpi_context_t)            , intent(in)    :: this
    logical                         , intent(in)    :: in_subcontext1
    class(execution_context_t), allocatable, intent(inout) :: subcontext1
    class(execution_context_t), allocatable, intent(inout) :: subcontext2
    integer                :: istat,current_task,num_tasks
    integer, parameter     :: key=0

    if(allocated(subcontext1)) then
       call subcontext1%free(finalize=.false.)
    else
       allocate(subcontext1,mold=this,stat=istat);check(istat==0)
    end if
    if(allocated(subcontext2)) then
       call subcontext2%free(finalize=.false.)
    else
       allocate(subcontext2,mold=this,stat=istat);check(istat==0)
    end if

    select type(subcontext1)
    type is(mpi_context_t)
       select type(subcontext2)
       type is(mpi_context_t)
          if ( in_subcontext1 ) then
             call mpi_comm_split(this%icontxt, 1, key, subcontext1%icontxt, istat); assert ( istat == mpi_success )
             subcontext1%created_from_mpi = .true.
             call subcontext2%nullify()
          else
             call mpi_comm_split(this%icontxt, 2, key, subcontext2%icontxt, istat); assert ( istat == mpi_success )
             subcontext2%created_from_mpi = .true.
             call subcontext1%nullify()
          end if

          if(subcontext1%icontxt/=mpi_comm_null) then
             call mpi_comm_size(subcontext1%icontxt,num_tasks,istat)    ; check(istat == mpi_success)
             call mpi_comm_rank(subcontext1%icontxt,current_task,istat) ; check(istat == mpi_success)
          else
             num_tasks = -1
             current_task = -1
          end if
          call subcontext1%set_current_task(current_task)
          call subcontext1%set_num_tasks(num_tasks)
          
          if(subcontext2%icontxt/=mpi_comm_null) then
             call mpi_comm_size(subcontext2%icontxt,num_tasks,istat)    ; check(istat == mpi_success)
             call mpi_comm_rank(subcontext2%icontxt,current_task,istat) ; check(istat == mpi_success)
          else
             num_tasks = -1
             current_task = -1
          end if
          call subcontext2%set_current_task(current_task)
          call subcontext2%set_num_tasks(num_tasks)

          class default
          check(.false.)
       end select
       class default
       check(.false.)
    end select

  end subroutine mpi_context_split_by_condition

  !=============================================================================
  subroutine mpi_context_free ( this, finalize  )
    implicit none 
    class(mpi_context_t)            , intent(inout) :: this
    logical                         , intent(in)    :: finalize
    integer(ip) :: istat

    if(this%created_from_mpi) then
       if(this%icontxt/=mpi_comm_null.and.this%icontxt/=mpi_comm_world) then
          call mpi_comm_free(this%icontxt,istat); check(istat == mpi_success)
       end if
    
       if(finalize) then
          call mpi_finalize(istat); check(istat == mpi_success)
       end if
    end if
    this%created_from_mpi=.false.
    this%icontxt=mpi_comm_null
    call this%set_current_task(-1)
    call this%set_num_tasks(-1)

  end subroutine mpi_context_free

  !=============================================================================
  subroutine mpi_context_nullify ( this )
    implicit none 
    class(mpi_context_t), intent(inout) :: this
    call this%free(finalize=.false.)
    this%icontxt = mpi_comm_null
    call this%set_current_task(-1)
    call this%set_num_tasks(-1)
  end subroutine mpi_context_nullify

  !=============================================================================
  pure function mpi_context_am_i_member(this)
    implicit none
    class(mpi_context_t), intent(in) :: this
    logical                          :: mpi_context_am_i_member
    mpi_context_am_i_member = (this%get_current_task()>=0)
  end function mpi_context_am_i_member

  !=============================================================================
  pure function mpi_context_am_i_root(this)
    implicit none
    class(mpi_context_t), intent(in) :: this
    logical                          :: mpi_context_am_i_root
    mpi_context_am_i_root = (this%get_current_task()==0)
  end function mpi_context_am_i_root

  !=============================================================================
  subroutine mpi_context_barrier(this)
    implicit none 
    class(mpi_context_t), intent(in) :: this
    integer :: istat
    call mpi_barrier ( this%icontxt, istat); check ( istat == mpi_success )
  end subroutine mpi_context_barrier

  !=============================================================================
  function mpi_context_time(this)
    implicit none 
    class(mpi_context_t), intent(in) :: this
    real(rp) :: mpi_context_time
    mpi_context_time =  mpi_wtime ()
  end function mpi_context_time

  !=============================================================================
  subroutine mpi_context_sum_scalar_rp (this,alpha)
    implicit none
    class(mpi_context_t) , intent(in)    :: this
    real(rp)             , intent(inout) :: alpha
    integer  :: istat
    call mpi_allreduce(MPI_IN_PLACE,alpha,1,mpi_context_rp,mpi_sum,this%icontxt,istat); check ( istat == mpi_success )
  end subroutine mpi_context_sum_scalar_rp
  
  !=============================================================================
  subroutine mpi_context_sum_scalar_ip (this,alpha)
    implicit none
    class(mpi_context_t) , intent(in)    :: this
    integer(ip)          , intent(inout) :: alpha
    integer  :: istat
    call mpi_allreduce(MPI_IN_PLACE,alpha,1,mpi_context_ip,mpi_sum,this%icontxt,istat); check ( istat == mpi_success )
  end subroutine mpi_context_sum_scalar_ip  

  !=============================================================================
  subroutine mpi_context_sum_vector_rp(this,alpha)
    implicit none
    class(mpi_context_t) , intent(in)    :: this
    real(rp)             , intent(inout) :: alpha(:) 
    integer  :: istat
    call mpi_allreduce(MPI_IN_PLACE,alpha,size(alpha),mpi_context_rp,mpi_sum,this%icontxt,istat); check ( istat == mpi_success )
  end subroutine mpi_context_sum_vector_rp

  !=============================================================================
  subroutine mpi_context_max_scalar_ip(this,n)
    implicit none
    class(mpi_context_t) , intent(in)    :: this
    integer(ip)          , intent(inout) :: n
    integer  :: istat
    call mpi_allreduce(MPI_IN_PLACE,n,1,mpi_context_ip,mpi_max,this%icontxt,istat); check ( istat == mpi_success )
  end subroutine mpi_context_max_scalar_ip
  
  !=============================================================================
  subroutine mpi_context_max_scalar_rp (this,alpha)
    implicit none
    class(mpi_context_t) , intent(in)    :: this
    real(rp)             , intent(inout) :: alpha
    integer  :: istat
    call mpi_allreduce(MPI_IN_PLACE,alpha,1,mpi_context_rp,mpi_max,this%icontxt,istat); check ( istat == mpi_success )
  end subroutine mpi_context_max_scalar_rp

  !=============================================================================
  subroutine mpi_context_max_vector_rp(this,alpha)
    implicit none
    class(mpi_context_t) , intent(in)    :: this
    real(rp)             , intent(inout) :: alpha(:) 
    integer  :: istat
    call mpi_allreduce(MPI_IN_PLACE,alpha,size(alpha),mpi_context_rp,mpi_max,this%icontxt,istat); check ( istat == mpi_success )
  end subroutine mpi_context_max_vector_rp

  !=============================================================================
  subroutine mpi_context_min_scalar_rp (this,alpha)
    implicit none
    class(mpi_context_t) , intent(in)    :: this
    real(rp)             , intent(inout) :: alpha
    integer  :: istat 
    call mpi_allreduce(MPI_IN_PLACE,alpha,1,mpi_context_rp,mpi_min,this%icontxt,istat); check ( istat == mpi_success )
  end subroutine mpi_context_min_scalar_rp
  
  !=============================================================================
  subroutine mpi_context_sum_scalar_igp (this,n)
    implicit none
    class(mpi_context_t) , intent(in)    :: this
    integer(igp)         , intent(inout) :: n
    integer  :: istat
    call mpi_allreduce(MPI_IN_PLACE,n,1,mpi_context_igp,mpi_sum,this%icontxt,istat); check ( istat == mpi_success )
  end subroutine mpi_context_sum_scalar_igp
  
!=============================================================================
  subroutine mpi_context_max_scalar_igp (this,n)
    implicit none
    class(mpi_context_t) , intent(in)    :: this
    integer(igp)         , intent(inout) :: n
    integer  :: istat
    call mpi_allreduce(MPI_IN_PLACE,n,1,mpi_context_igp,mpi_max,this%icontxt,istat); check ( istat == mpi_success )
  end subroutine mpi_context_max_scalar_igp

  !=============================================================================
  subroutine mpi_context_sum_vector_igp (this,n)
    implicit none
    class(mpi_context_t) , intent(in)    :: this
    integer(igp)         , intent(inout) :: n(:)
    integer  :: istat
    call mpi_allreduce(MPI_IN_PLACE,n,size(n),mpi_context_igp,mpi_sum,this%icontxt,istat); check ( istat == mpi_success )
  end subroutine mpi_context_sum_vector_igp
  
  !=============================================================================
  subroutine mpi_context_max_vector_igp (this,n)
    implicit none
    class(mpi_context_t) , intent(in)    :: this
    integer(igp)         , intent(inout) :: n(:)
    integer  :: istat
    call mpi_allreduce(MPI_IN_PLACE,n,size(n),mpi_context_igp,mpi_max,this%icontxt,istat); check ( istat == mpi_success )
  end subroutine mpi_context_max_vector_igp

  !=============================================================================
  subroutine mpi_context_bcast_subcontext(this,subcontxt1,subcontxt2,condition)
    implicit none
    class(mpi_context_t)       , intent(in)    :: this
    class(execution_context_t) , intent(in)    :: subcontxt1
    class(execution_context_t) , intent(in)    :: subcontxt2
    logical                    , intent(inout) :: condition
    integer :: recv_rank, send_rank, istat

    ! If subcontext2 is void ...
    if ( subcontxt1%am_i_member() .and. &
         this%get_num_tasks() == subcontxt1%get_num_tasks() ) then
     return
    end if


    send_rank = mpi_context_root
    if(subcontxt1%am_i_member()) then
       recv_rank = subcontxt1%get_num_tasks()
    else if(subcontxt2%am_i_member()) then
       recv_rank = this%get_num_tasks() - subcontxt2%get_num_tasks()
    end if

    if(this%get_current_task()==send_rank.and.recv_rank<this%get_num_tasks()) then
       call mpi_send(condition, 1, mpi_context_lg, recv_rank,  &
               & mpi_context_tag, this%icontxt, istat); check( istat == mpi_success )
    else if(this%get_current_task()==recv_rank) then
       call mpi_recv(condition, 1, mpi_context_lg, send_rank,  &
               & mpi_context_tag, this%icontxt, mpi_context_status, istat); check( istat == mpi_success )
    end if

    select type(subcontxt2)
    type is(mpi_context_t)
       if(subcontxt2%am_i_member()) then
          call mpi_bcast(condition,1,mpi_context_lg,mpi_context_root,subcontxt2%icontxt,istat); check( istat == mpi_success )
       end if
    class default
       check(.false.)
    end select

  end subroutine mpi_context_bcast_subcontext

  !=============================================================================
  ! When packing   (gathering) ,    buffer <- alpha * x
  ! When unpacking (scattering),    x <- beta*x + buffer
  subroutine mpi_context_neighbours_exchange_rp ( this, & 
       &                                          num_rcv, list_rcv, rcv_ptrs, unpack_idx, & 
       &                                          num_snd, list_snd, snd_ptrs, pack_idx,   &
       &                                          alpha, beta, x, y)
    implicit none
    class(mpi_context_t), intent(inout) :: this

    ! Control info to receive
    integer(ip)             , intent(in) :: num_rcv, list_rcv(num_rcv), rcv_ptrs(num_rcv+1)
    integer(ip)             , intent(in) :: unpack_idx (rcv_ptrs(num_rcv+1)-1)

    ! Control info to send
    integer(ip)             , intent(in) :: num_snd, list_snd(num_snd), snd_ptrs(num_snd+1)
    integer(ip)             , intent(in) :: pack_idx (snd_ptrs(num_snd+1)-1)

    ! Floating point data
    real(rp), intent(in)    :: alpha, beta
    real(rp), intent(in)    :: x(:)
    real(rp), intent(inout) :: y(:)

    ! Communication related locals 
    integer :: i, proc_to_comm, sizmsg, istat
    integer :: p2pstat(mpi_status_size)

    ! Request handlers for non-blocking receives
    integer, allocatable :: rcvhd(:)

    ! Request handlers for non-blocking receives
    integer, allocatable :: sndhd(:)

    real(rp), allocatable :: sndbuf(:) 
    real(rp), allocatable :: rcvbuf(:)

    call memalloc (num_rcv, rcvhd, __FILE__,__LINE__)
    call memalloc (num_snd, sndhd, __FILE__,__LINE__)

    call memalloc ((snd_ptrs(num_snd+1)-snd_ptrs(1)), sndbuf, __FILE__,__LINE__)
    call memalloc ((rcv_ptrs(num_rcv+1)-rcv_ptrs(1)), rcvbuf, __FILE__,__LINE__)

    ! Pack send buffers
    call pack_rp ( snd_ptrs(num_snd+1)-snd_ptrs(1), pack_idx, alpha, x, sndbuf )

    ! First post all the non blocking receives   
    do i=1, num_rcv
       proc_to_comm = list_rcv(i) - 1 

       ! Message size to be received
       sizmsg = rcv_ptrs(i+1)-rcv_ptrs(i)

       if ( (sizmsg > 0) .and. (list_rcv(i)-1 /= this%get_current_task()) ) then
          call mpi_irecv(  rcvbuf(rcv_ptrs(i)), sizmsg,        &
               &  mpi_context_rp, proc_to_comm, &
               &  mpi_context_tag, this%icontxt, rcvhd(i), istat)
          check ( istat == mpi_success )
       end if
    end do

    ! Secondly post all non-blocking sends
    do i=1, num_snd
       proc_to_comm = list_snd(i) - 1

       ! Message size to be sent
       sizmsg = snd_ptrs(i+1)-snd_ptrs(i)

       if ( (sizmsg > 0) .and. (list_snd(i)-1 /= this%get_current_task()) ) then 
          call mpi_isend(sndbuf(snd_ptrs(i)), sizmsg, &
               & mpi_context_rp, proc_to_comm,    &
               & mpi_context_tag, this%icontxt, sndhd(i), istat)
          check ( istat == mpi_success )
       end if
    end do

    ! Wait on all non-blocking receives
    do i=1, num_rcv
       proc_to_comm = list_rcv(i) - 1

       ! Message size to be received
       sizmsg = rcv_ptrs(i+1)-rcv_ptrs(i)

       if ( (sizmsg > 0) .and. (list_rcv(i)-1 /= this%get_current_task()) ) then
          call mpi_wait(rcvhd(i), p2pstat, istat)

       else if ( list_rcv(i)-1 == this%get_current_task() ) then
          if ( sizmsg /= snd_ptrs(i+1)-snd_ptrs(i) ) then 
             write(0,*) 'Fatal error in single_exchange: mismatch on self sendf', & 
                  & sizmsg, snd_ptrs(i+1)-snd_ptrs(i) 
          end if

          rcvbuf( rcv_ptrs(i):rcv_ptrs(i)+sizmsg-1) = &
               sndbuf( snd_ptrs(i): snd_ptrs(i)+sizmsg-1 )
       end if
    end do

    ! Finally wait on all non-blocking sends
    do i=1, num_snd
       proc_to_comm = list_snd(i) - 1 

       ! Message size to be received
       sizmsg = snd_ptrs(i+1)-snd_ptrs(i)

       if ( (sizmsg > 0) .and. (list_snd(i)-1 /= this%get_current_task()) ) then
          call mpi_wait(sndhd(i), p2pstat, istat)
          check ( istat == mpi_success )
       end if
    end do

    if ( rcv_ptrs(num_rcv+1)-rcv_ptrs(1) > 0 ) then 
      ! Unpack recv buffers
      call unpack_rp (rcv_ptrs(num_rcv+1)-rcv_ptrs(1), unpack_idx, beta, rcvbuf, y )
    end if
    
    call memfree (rcvhd,__FILE__,__LINE__) 
    call memfree (sndhd,__FILE__,__LINE__)

    call memfree (sndbuf,__FILE__,__LINE__)
    call memfree (rcvbuf,__FILE__,__LINE__)

  end subroutine mpi_context_neighbours_exchange_rp

  !=============================================================================
  subroutine mpi_context_neighbours_exchange_wo_alpha_beta_rp ( this, & 
       &                                                        num_rcv, list_rcv, rcv_ptrs, unpack_idx, & 
       &                                                        num_snd, list_snd, snd_ptrs, pack_idx,   &
       &                                                        x, y, chunk_size)
    implicit none
    class(mpi_context_t), intent(in)    :: this
    ! Control info to receive
    integer(ip)             , intent(in)    :: num_rcv, list_rcv(num_rcv), rcv_ptrs(num_rcv+1)
    integer(ip)             , intent(in)    :: unpack_idx (rcv_ptrs(num_rcv+1)-1)
    ! Control info to send
    integer(ip)             , intent(in)    :: num_snd, list_snd(num_snd), snd_ptrs(num_snd+1)
    integer(ip)             , intent(in)    :: pack_idx (snd_ptrs(num_snd+1)-1)
    ! Raw data to be exchanged
    real(rp)                , intent(in)    :: x(:)
    real(rp)                , intent(inout) :: y(:)
    integer(ip)   , optional, intent(in)    :: chunk_size  
    
    ! Communication related locals 
    integer :: i, proc_to_comm, sizmsg, istat
    integer :: p2pstat(mpi_status_size)

    ! Request handlers for non-blocking receives
    integer, allocatable :: rcvhd(:)

    ! Request handlers for non-blocking receives
    integer, allocatable :: sndhd(:)

    real(rp), allocatable :: sndbuf(:) 
    real(rp), allocatable :: rcvbuf(:)

    integer(ip) :: chunk_size_


    if ( present(chunk_size) ) then
       chunk_size_ = chunk_size
    else
       chunk_size_ = 1
    end if

    call memalloc (num_rcv, rcvhd, __FILE__,__LINE__)
    call memalloc (num_snd, sndhd, __FILE__,__LINE__)

    call memalloc ((snd_ptrs(num_snd+1)-snd_ptrs(1))*chunk_size_, sndbuf, __FILE__,__LINE__)
    call memalloc ((rcv_ptrs(num_rcv+1)-rcv_ptrs(1))*chunk_size_, rcvbuf, __FILE__,__LINE__)

    ! Pack send buffers
    call pack_rp_wo_alpha ( snd_ptrs(num_snd+1)-snd_ptrs(1), chunk_size_, pack_idx, x, sndbuf )

    ! First post all the non blocking receives   
    do i=1, num_rcv
       proc_to_comm = list_rcv(i) - 1 

       ! Message size to be received
       sizmsg = (rcv_ptrs(i+1)-rcv_ptrs(i))*chunk_size_

       if ( (sizmsg > 0) .and. (list_rcv(i)-1 /= this%get_current_task()) ) then
          call mpi_irecv(  rcvbuf((rcv_ptrs(i)-1)*chunk_size_+1), sizmsg,        &
               &  mpi_context_rp, proc_to_comm, &
               &  mpi_context_tag, this%icontxt, rcvhd(i), istat)
          check ( istat == mpi_success )
       end if
    end do

    ! Secondly post all non-blocking sends
    do i=1, num_snd
       proc_to_comm = list_snd(i) - 1

       ! Message size to be sent
       sizmsg = (snd_ptrs(i+1)-snd_ptrs(i))*chunk_size_

       if ( (sizmsg > 0) .and. (list_snd(i)-1 /= this%get_current_task()) ) then 
          call mpi_isend(sndbuf((snd_ptrs(i)-1)*chunk_size_+1), sizmsg, &
               & mpi_context_rp, proc_to_comm,    &
               & mpi_context_tag, this%icontxt, sndhd(i), istat)
          check ( istat == mpi_success )
       end if
    end do

    ! Wait on all non-blocking receives
    do i=1, num_rcv
       proc_to_comm = list_rcv(i) - 1

       ! Message size to be received
       sizmsg = (rcv_ptrs(i+1)-rcv_ptrs(i))*chunk_size_

       if ( (sizmsg > 0) .and. (list_rcv(i)-1 /= this%get_current_task()) ) then
          call mpi_wait(rcvhd(i), p2pstat, istat)
          check ( istat == mpi_success )
       else if ( list_rcv(i)-1 == this%get_current_task() ) then
          if ( sizmsg /= (snd_ptrs(i+1)-snd_ptrs(i))*chunk_size_ ) then 
             write(0,*) 'Fatal error in single_exchange: mismatch on self sendf', & 
                  & sizmsg, snd_ptrs(i+1)-snd_ptrs(i) 
             check(.false.)
          end if
          rcvbuf((rcv_ptrs(i)-1)*chunk_size_+1:(rcv_ptrs(i)-1)*chunk_size_+sizmsg) = &
               sndbuf( (snd_ptrs(i)-1)*chunk_size_+1:(snd_ptrs(i)-1)*chunk_size_+sizmsg )
       end if
    end do

    ! Finally wait on all non-blocking sends
    do i=1, num_snd
       proc_to_comm = list_snd(i) - 1

       ! Message size to be received
       sizmsg = (snd_ptrs(i+1)-snd_ptrs(i))*chunk_size_

       if ( (sizmsg > 0) .and. (list_snd(i)-1 /= this%get_current_task()) ) then
          call mpi_wait(sndhd(i), p2pstat, istat)
          check ( istat == mpi_success )
       end if
    end do

    if ( rcv_ptrs(num_rcv+1)-rcv_ptrs(1) > 0 ) then 
      ! Unpack recv buffers
      call unpack_rp_wo_beta (rcv_ptrs(num_rcv+1)-rcv_ptrs(1), chunk_size_, unpack_idx, rcvbuf, y )
    end if
    call memfree (rcvhd,__FILE__,__LINE__) 
    call memfree (sndhd,__FILE__,__LINE__)

    call memfree (sndbuf,__FILE__,__LINE__)
    call memfree (rcvbuf,__FILE__,__LINE__)
  end subroutine mpi_context_neighbours_exchange_wo_alpha_beta_rp
  
  !=============================================================================
  subroutine mpi_context_neighbours_exchange_wo_alpha_beta_rp_v ( this, & 
       &                                                          num_rcv, list_rcv, rcv_ptrs, unpack_idx, & 
       &                                                          num_snd, list_snd, snd_ptrs, pack_idx,   &
       &                                                          x, y, ptr_chunk_size_snd, ptr_chunk_size_rcv )
    implicit none
    class(mpi_context_t), intent(in)    :: this
    ! Control info to receive
    integer(ip)             , intent(in)    :: num_rcv, list_rcv(num_rcv), rcv_ptrs(num_rcv+1)
    integer(ip)             , intent(in)    :: unpack_idx (rcv_ptrs(num_rcv+1)-1)
    ! Control info to send
    integer(ip)             , intent(in)    :: num_snd, list_snd(num_snd), snd_ptrs(num_snd+1)
    integer(ip)             , intent(in)    :: pack_idx (snd_ptrs(num_snd+1)-1)
    ! Raw data to be exchanged
    real(rp)                , intent(in)    :: x(:)
    real(rp)                , intent(inout) :: y(:)
    integer(ip)             , intent(in)    :: ptr_chunk_size_snd(:)
    integer(ip)             , intent(in)    :: ptr_chunk_size_rcv(:)
    
    ! Communication related locals 
    integer :: i, proc_to_comm, sizmsg, istat
    integer :: p2pstat(mpi_status_size)

    ! Request handlers for non-blocking receives
    integer, allocatable :: rcvhd(:)

    ! Request handlers for non-blocking receives
    integer, allocatable :: sndhd(:)

    real(rp), allocatable :: sndbuf(:) 
    real(rp), allocatable :: rcvbuf(:)

    integer(ip) , allocatable :: ptr_snd_size(:)
    integer(ip) , allocatable :: ptr_rcv_size(:)
    
    call memalloc (num_rcv, rcvhd, __FILE__,__LINE__)
    call memalloc (num_snd, sndhd, __FILE__,__LINE__)
    
    call memalloc ( num_snd+1, ptr_snd_size, __FILE__, __LINE__ )
    call memalloc ( num_rcv+1, ptr_rcv_size, __FILE__, __LINE__ )
    
    call fill_ptr_snd_rcv_size( num_rcv,rcv_ptrs,unpack_idx,           &
                                      num_snd,snd_ptrs,pack_idx,             &
                                      ptr_rcv_size,ptr_snd_size,             &
                                      ptr_chunk_size_rcv,ptr_chunk_size_snd )
    
    call memalloc (ptr_snd_size(num_snd+1)-ptr_snd_size(1),sndbuf,__FILE__,__LINE__)
    call memalloc (ptr_rcv_size(num_rcv+1)-ptr_rcv_size(1),rcvbuf,__FILE__,__LINE__)

    ! Pack send buffers
    call pack_variable_rp ( snd_ptrs(num_snd+1)-snd_ptrs(1), ptr_chunk_size_snd, pack_idx, x, sndbuf )
    
    ! First post all the non blocking receives   
    do i=1, num_rcv
       proc_to_comm = list_rcv(i) - 1

       ! Message size to be received
       sizmsg = ptr_rcv_size(i+1)-ptr_rcv_size(i)

       if ( (sizmsg > 0) .and. (list_rcv(i)-1 /= this%get_current_task()) ) then
          call mpi_irecv(  rcvbuf(ptr_rcv_size(i)), sizmsg,        &
               &  mpi_context_rp, proc_to_comm,                          &
               &  mpi_context_tag, this%icontxt, rcvhd(i), istat)
          check ( istat == mpi_success )
       end if
    end do

    ! Secondly post all non-blocking sends
    do i=1, num_snd
       proc_to_comm = list_snd(i) - 1

       ! Message size to be sent
       sizmsg = ptr_snd_size(i+1)-ptr_snd_size(i)

       if ( (sizmsg > 0) .and. (list_snd(i)-1 /= this%get_current_task()) ) then 
          call mpi_isend(sndbuf(ptr_snd_size(i)), sizmsg,         &
               & mpi_context_rp, proc_to_comm,                          &
               & mpi_context_tag, this%icontxt, sndhd(i), istat)
          check ( istat == mpi_success )
       end if
    end do

    ! Wait on all non-blocking receives
    do i=1, num_rcv
       proc_to_comm = list_rcv(i) - 1

       ! Message size to be received
       sizmsg = ptr_rcv_size(i+1)-ptr_rcv_size(i)

       if ( (sizmsg > 0) .and. (list_rcv(i)-1 /= this%get_current_task()) ) then
          call mpi_wait(rcvhd(i), p2pstat, istat)
          check ( istat == mpi_success )
       else if ( list_rcv(i)-1 == this%get_current_task() ) then
          if ( sizmsg /= (ptr_snd_size(i+1)-ptr_snd_size(i)) ) then 
             write(0,*) 'Fatal error in single_exchange: mismatch on self sendf', & 
                  & sizmsg, ptr_snd_size(i+1)-ptr_snd_size(i) 
             check(.false.)     
          end if
          rcvbuf(   (ptr_rcv_size(i)+1):(ptr_rcv_size(i)+sizmsg) ) = &
            sndbuf( (ptr_snd_size(i)+1):(ptr_snd_size(i)+sizmsg) )
       end if
    end do

    ! Finally wait on all non-blocking sends
    do i=1, num_snd
       proc_to_comm = list_snd(i) - 1

       ! Message size to be received
       sizmsg = ptr_snd_size(i+1)-ptr_snd_size(i)

       if ( (sizmsg > 0) .and. (list_snd(i)-1 /= this%get_current_task()) ) then
          call mpi_wait(sndhd(i), p2pstat, istat)
          check ( istat == mpi_success )
       end if
    end do
    
    if ( rcv_ptrs(num_rcv+1)-rcv_ptrs(1) > 0 ) then 
      ! Unpack recv buffers
      call unpack_variable_rp (rcv_ptrs(num_rcv+1)-rcv_ptrs(1), ptr_chunk_size_rcv, unpack_idx, rcvbuf, y )
    end if 
    
    call memfree (rcvhd,__FILE__,__LINE__) 
    call memfree (sndhd,__FILE__,__LINE__)

    call memfree (sndbuf,__FILE__,__LINE__)
    call memfree (rcvbuf,__FILE__,__LINE__)
    
    call memfree ( ptr_snd_size, __FILE__, __LINE__ )
    call memfree ( ptr_rcv_size, __FILE__, __LINE__ )
    
  end subroutine mpi_context_neighbours_exchange_wo_alpha_beta_rp_v
  
  !=============================================================================
  ! When packing   (gathering) ,    buffer <- alpha * x
  ! When unpacking (scattering),    x <- beta*x + buffer
  subroutine mpi_context_neighbours_exchange_ip ( this, & 
       &                                          num_rcv, list_rcv, rcv_ptrs, unpack_idx, & 
       &                                          num_snd, list_snd, snd_ptrs, pack_idx,   &
       &                                          x,y,chunk_size)
    implicit none
    class(mpi_context_t), intent(in)    :: this
    ! Control info to receive
    integer(ip)             , intent(in)    :: num_rcv, list_rcv(num_rcv), rcv_ptrs(num_rcv+1)
    integer(ip)             , intent(in)    :: unpack_idx (rcv_ptrs(num_rcv+1)-1)
    ! Control info to send
    integer(ip)             , intent(in)    :: num_snd, list_snd(num_snd), snd_ptrs(num_snd+1)
    integer(ip)             , intent(in)    :: pack_idx (snd_ptrs(num_snd+1)-1)
    ! Raw data to be exchanged
    integer(ip)             , intent(in)    :: x(:)
    integer(ip)             , intent(inout) :: y(:)
    integer(ip)   , optional, intent(in)    :: chunk_size

    ! Communication related locals 
    integer :: i, proc_to_comm, sizmsg, istat
    integer :: p2pstat(mpi_status_size)

    ! Request handlers for non-blocking receives
    integer, allocatable :: rcvhd(:)

    ! Request handlers for non-blocking receives
    integer, allocatable :: sndhd(:)

    integer(ip), allocatable :: sndbuf(:) 
    integer(ip), allocatable :: rcvbuf(:)

    integer(ip) :: chunk_size_


    if ( present(chunk_size) ) then
       chunk_size_ = chunk_size
    else
       chunk_size_ = 1
    end if

    call memalloc (num_rcv, rcvhd, __FILE__,__LINE__)
    call memalloc (num_snd, sndhd, __FILE__,__LINE__)

    call memalloc ((snd_ptrs(num_snd+1)-snd_ptrs(1))*chunk_size_, sndbuf, __FILE__,__LINE__)
    call memalloc ((rcv_ptrs(num_rcv+1)-rcv_ptrs(1))*chunk_size_, rcvbuf, __FILE__,__LINE__)

    ! Pack send buffers
    if ( snd_ptrs(num_snd+1)-snd_ptrs(1) > 0 ) then
      call pack_ip ( snd_ptrs(num_snd+1)-snd_ptrs(1), chunk_size_, pack_idx, x, sndbuf )
    end if 
    
    ! First post all the non blocking receives   
    do i=1, num_rcv
       proc_to_comm = list_rcv(i) - 1 

       ! Message size to be received
       sizmsg = (rcv_ptrs(i+1)-rcv_ptrs(i))*chunk_size_

       if ( (sizmsg > 0) .and. (list_rcv(i)-1 /= this%get_current_task()) ) then
          call mpi_irecv(  rcvbuf((rcv_ptrs(i)-1)*chunk_size_+1), sizmsg,        &
               &  mpi_context_ip, proc_to_comm, &
               &  mpi_context_tag, this%icontxt, rcvhd(i), istat)
          check ( istat == mpi_success )
       end if
    end do

    ! Secondly post all non-blocking sends
    do i=1, num_snd
       proc_to_comm = list_snd(i) - 1

       ! Message size to be sent
       sizmsg = (snd_ptrs(i+1)-snd_ptrs(i))*chunk_size_

       if ( (sizmsg > 0) .and. (list_snd(i)-1 /= this%get_current_task()) ) then 
          call mpi_isend(sndbuf((snd_ptrs(i)-1)*chunk_size_+1), sizmsg, &
               & mpi_context_ip, proc_to_comm,    &
               & mpi_context_tag, this%icontxt, sndhd(i), istat)
          check ( istat == mpi_success )
       end if
    end do

    ! Wait on all non-blocking receives
    do i=1, num_rcv
       proc_to_comm = list_rcv(i) - 1

       ! Message size to be received
       sizmsg = (rcv_ptrs(i+1)-rcv_ptrs(i))*chunk_size_

       if ( (sizmsg > 0) .and. (list_rcv(i)-1 /= this%get_current_task()) ) then
          call mpi_wait(rcvhd(i), p2pstat, istat)
          check ( istat == mpi_success )
       else if ( list_rcv(i)-1 == this%get_current_task() ) then
          if ( sizmsg /= (snd_ptrs(i+1)-snd_ptrs(i))*chunk_size_ ) then 
             write(0,*) 'Fatal error in single_exchange: mismatch on self sendf', & 
                  & sizmsg, snd_ptrs(i+1)-snd_ptrs(i) 
             check(.false.)
          end if
          rcvbuf((rcv_ptrs(i)-1)*chunk_size_+1:(rcv_ptrs(i)-1)*chunk_size_+sizmsg) = &
               sndbuf( (snd_ptrs(i)-1)*chunk_size_+1:(snd_ptrs(i)-1)*chunk_size_+sizmsg )
       end if
    end do

    ! Finally wait on all non-blocking sends
    do i=1, num_snd
       proc_to_comm = list_snd(i) - 1

       ! Message size to be received
       sizmsg = (snd_ptrs(i+1)-snd_ptrs(i))*chunk_size_

       if ( (sizmsg > 0) .and. (list_snd(i)-1 /= this%get_current_task()) ) then
          call mpi_wait(sndhd(i), p2pstat, istat)
          check ( istat == mpi_success )
       end if
    end do

    if ( rcv_ptrs(num_rcv+1)-rcv_ptrs(1) > 0 ) then 
      ! Unpack recv buffers
      call unpack_ip (rcv_ptrs(num_rcv+1)-rcv_ptrs(1), chunk_size_, unpack_idx, rcvbuf, y )
    end if
    
    call memfree (rcvhd,__FILE__,__LINE__) 
    call memfree (sndhd,__FILE__,__LINE__)

    call memfree (sndbuf,__FILE__,__LINE__)
    call memfree (rcvbuf,__FILE__,__LINE__)
  end subroutine mpi_context_neighbours_exchange_ip

  !=============================================================================
  subroutine mpi_context_neighbours_exchange_igp ( this, & 
       &                                           num_rcv, list_rcv, rcv_ptrs, unpack_idx, & 
       &                                           num_snd, list_snd, snd_ptrs, pack_idx,   &
       &                                           x, y, chunk_size, mask)
    implicit none
    class(mpi_context_t), intent(in)    :: this
    ! Control info to receive
    integer(ip)             , intent(in)    :: num_rcv, list_rcv(num_rcv), rcv_ptrs(num_rcv+1)
    integer(ip)             , intent(in)    :: unpack_idx (rcv_ptrs(num_rcv+1)-1)
    ! Control info to send
    integer(ip)             , intent(in)    :: num_snd, list_snd(num_snd), snd_ptrs(num_snd+1)
    integer(ip)             , intent(in)    :: pack_idx (snd_ptrs(num_snd+1)-1)
    ! Raw data to be exchanged
    integer(igp)            , intent(in)    :: x(:)
    integer(igp)            , intent(inout) :: y(:)
    integer(ip)   , optional, intent(in)    :: chunk_size
    integer(igp)  , optional, intent(in)    :: mask

    ! Communication related locals 
    integer :: i, proc_to_comm, sizmsg, istat
    integer :: p2pstat(mpi_status_size)

    ! Request handlers for non-blocking receives
    integer, allocatable :: rcvhd(:)

    ! Request handlers for non-blocking receives
    integer, allocatable :: sndhd(:)

    integer(igp), allocatable :: sndbuf(:) 
    integer(igp), allocatable :: rcvbuf(:)

    integer(ip) :: chunk_size_

    if ( present(chunk_size) ) then
       chunk_size_ = chunk_size
    else
       chunk_size_ = 1
    end if

    call memalloc (num_rcv, rcvhd, __FILE__,__LINE__)
    call memalloc (num_snd, sndhd, __FILE__,__LINE__)

    call memalloc ((snd_ptrs(num_snd+1)-snd_ptrs(1))*chunk_size_, sndbuf, __FILE__,__LINE__)
    call memalloc ((rcv_ptrs(num_rcv+1)-rcv_ptrs(1))*chunk_size_, rcvbuf, __FILE__,__LINE__)

    if ( snd_ptrs(num_snd+1)-snd_ptrs(1) > 0 ) then
      ! Pack send buffers
      call pack_igp ( snd_ptrs(num_snd+1)-snd_ptrs(1), chunk_size_, pack_idx, x, sndbuf )
    end if 
      
    ! First post all the non blocking receives   
    do i=1, num_rcv
       proc_to_comm = list_rcv(i) - 1

       ! Message size to be received
       sizmsg = (rcv_ptrs(i+1)-rcv_ptrs(i))*chunk_size_

       if ( (sizmsg > 0) .and. (list_rcv(i)-1 /= this%get_current_task()) ) then
          call mpi_irecv(  rcvbuf((rcv_ptrs(i)-1)*chunk_size_+1), sizmsg,        &
               &  mpi_context_igp, proc_to_comm, &
               &  mpi_context_tag, this%icontxt, rcvhd(i), istat)
          check ( istat == mpi_success )
       end if
    end do

    ! Secondly post all non-blocking sends
    do i=1, num_snd
       proc_to_comm = list_snd(i) - 1

       ! Message size to be sent
       sizmsg = (snd_ptrs(i+1)-snd_ptrs(i))*chunk_size_

       if ( (sizmsg > 0) .and. (list_snd(i)-1 /= this%get_current_task()) ) then 
          call mpi_isend(sndbuf((snd_ptrs(i)-1)*chunk_size_+1), sizmsg, &
               & mpi_context_igp, proc_to_comm,    &
               & mpi_context_tag, this%icontxt, sndhd(i), istat)
          check ( istat == mpi_success )
       end if
    end do

    ! Wait on all non-blocking receives
    do i=1, num_rcv
       proc_to_comm = list_rcv(i) - 1

       ! Message size to be received
       sizmsg = (rcv_ptrs(i+1)-rcv_ptrs(i))*chunk_size_

       if ( (sizmsg > 0) .and. (list_rcv(i)-1 /= this%get_current_task()) ) then
          call mpi_wait(rcvhd(i), p2pstat, istat)
          check ( istat == mpi_success )
       else if ( list_rcv(i)-1 == this%get_current_task() ) then
          if ( sizmsg /= (snd_ptrs(i+1)-snd_ptrs(i))*chunk_size_ ) then 
             write(0,*) 'Fatal error in single_exchange: mismatch on self sendf', & 
                  & sizmsg, snd_ptrs(i+1)-snd_ptrs(i) 
             check(.false.)     
          end if
          rcvbuf( (rcv_ptrs(i)-1)*chunk_size_+1:(rcv_ptrs(i)-1)*chunk_size_+sizmsg) = &
               sndbuf( (snd_ptrs(i)-1)*chunk_size_+1:(snd_ptrs(i)-1)*chunk_size_+sizmsg )
       end if
    end do

    ! Finally wait on all non-blocking sends
    do i=1, num_snd
       proc_to_comm = list_snd(i) - 1

       ! Message size to be received
       sizmsg = (snd_ptrs(i+1)-snd_ptrs(i))*chunk_size_

       if ( (sizmsg > 0) .and. (list_snd(i)-1 /= this%get_current_task()) ) then
          call mpi_wait(sndhd(i), p2pstat, istat)
          check ( istat == mpi_success )
       end if
    end do

    if ( rcv_ptrs(num_rcv+1)-rcv_ptrs(1) > 0 ) then
      ! Unpack recv buffers
      call unpack_igp (rcv_ptrs(num_rcv+1)-rcv_ptrs(1), chunk_size_, unpack_idx, rcvbuf, y, mask )
    end if 
    
    call memfree (rcvhd,__FILE__,__LINE__) 
    call memfree (sndhd,__FILE__,__LINE__)

    call memfree (sndbuf,__FILE__,__LINE__)
    call memfree (rcvbuf,__FILE__,__LINE__)
  end subroutine mpi_context_neighbours_exchange_igp

  !=============================================================================
  subroutine mpi_context_neighbours_exchange_single_ip ( this, & 
       &                                                    num_neighbours, &
       &                                                    list_neighbours, &
       &                                                    input_data,&
       &                                                    output_data)
    implicit none
    class(mpi_context_t), intent(in) :: this

    integer                 , intent(in)    :: num_neighbours
    integer(ip)             , intent(in)    :: list_neighbours (num_neighbours)
    integer(ip)             , intent(in)    :: input_data
    integer(ip)             , intent(inout) :: output_data(num_neighbours)

    integer(ip), allocatable :: ptrs_snd(:)        ! How much data does the part send/recv to/from each neighbour?
    integer(ip), allocatable :: unpack_idx(:)  ! Where the data received from each neighbour is copied/added 
    ! on the local vectors of the part ?
    integer(ip), allocatable :: pack_idx(:)    ! Where is located the data to be sent to 
    ! each neighbour on the local vectors of the part ?

    integer(ip), allocatable :: buffer(:)  
    integer(ip)              :: i 

    call memalloc ( num_neighbours+1, ptrs_snd, __FILE__, __LINE__ )
    ptrs_snd(1)=1
    do i=2, num_neighbours+1
       ptrs_snd(i)=ptrs_snd(i-1)+1
    end do

    call memalloc ( ptrs_snd(num_neighbours+1)-1, pack_idx, __FILE__, __LINE__ )
    pack_idx = 1 

    call memalloc ( ptrs_snd(num_neighbours+1)-1, unpack_idx, __FILE__, __LINE__ )
    do i=1, ptrs_snd(num_neighbours+1)-1
       unpack_idx(i) = i + 1
    end do

    call memalloc ( num_neighbours+1, buffer, __FILE__, __LINE__ )
    buffer(1) = input_data

    call this%neighbours_exchange ( num_neighbours,    &
         list_neighbours,   &
         ptrs_snd,              &
         unpack_idx,        &  
         num_neighbours,    &
         list_neighbours,   &
         ptrs_snd,              &
         pack_idx,          &
         buffer,            &
         buffer )

    output_data = buffer(2:)

    call memfree (buffer    , __FILE__, __LINE__ )
    call memfree (pack_idx  , __FILE__, __LINE__ )
    call memfree (unpack_idx, __FILE__, __LINE__ )
    call memfree (ptrs_snd      , __FILE__, __LINE__ )
  end subroutine mpi_context_neighbours_exchange_single_ip
  
  
  !=============================================================================
  subroutine mpi_context_neighbours_exchange_multiple_igp ( this, & 
       &                                                    num_neighbours, &
       &                                                    list_neighbours, &
       &                                                    size_input_data, &
       &                                                    input_data,&
       &                                                    size_output_data,&
       &                                                    output_data)
    implicit none
    class(mpi_context_t), intent(in) :: this

    integer                              , intent(in)    :: num_neighbours
    integer(ip)                          , intent(in)    :: list_neighbours (num_neighbours)
    integer(ip)                          , intent(in)    :: size_input_data
    integer(igp)                         , intent(in)    :: input_data(size_input_data)
    integer(ip)                          , intent(in)    :: size_output_data(num_neighbours)
    type(allocatable_array_igp1_t)       , intent(inout) :: output_data(num_neighbours)

    integer(ip), allocatable :: ptrs_snd(:)        ! How much data does the part send to each neighbour?
    integer(ip), allocatable :: unpack_idx(:)  ! Where the data received from each neighbour is copied/added 
    ! on the local vectors of the part ?
    integer(ip), allocatable :: pack_idx(:)    ! Where is located the data to be sent to 
    ! each neighbour on the local vectors of the part ?
    
    integer(ip) , allocatable :: ptrs_rcv(:)        ! How much data does the part recv from each neighbour?
    integer(igp), allocatable :: buffer(:)  
    integer(ip)              :: i,j 

    call memalloc ( num_neighbours+1, ptrs_snd, __FILE__, __LINE__ )
    call memalloc ( num_neighbours+1, ptrs_rcv, __FILE__, __LINE__ )
    ptrs_snd(1)=1
    ptrs_rcv(1)=1
    do i=2, num_neighbours+1
       ptrs_snd(i)=ptrs_snd(i-1)+size_input_data
       ptrs_rcv(i)=ptrs_rcv(i-1)+size_output_data(i-1)
    end do

    call memalloc ( ptrs_snd(num_neighbours+1)-1, pack_idx, __FILE__, __LINE__ )
    do i=1, num_neighbours
       pack_idx(ptrs_snd(i):ptrs_snd(i+1)-1) = (/(j, j=1,size_input_data)/)
    end do

    call memalloc ( ptrs_rcv(num_neighbours+1)-1, unpack_idx, __FILE__, __LINE__ )
    do i=1, ptrs_rcv(num_neighbours+1)-1
       unpack_idx(i) = i
    end do

    call memalloc ( ptrs_rcv(num_neighbours+1)-1, buffer, __FILE__, __LINE__ )
    call this%neighbours_exchange ( num_neighbours,    &
         list_neighbours,   &
         ptrs_rcv,              &
         unpack_idx,        &  
         num_neighbours,    &
         list_neighbours,   &
         ptrs_snd,              &
         pack_idx,          &
         input_data,        &
         buffer )
    
    do i=1, num_neighbours
       output_data(i)%a(:) = buffer(ptrs_rcv(i):ptrs_rcv(i+1)-1)
    end do
   
    call memfree (buffer    , __FILE__, __LINE__ )
    call memfree (pack_idx  , __FILE__, __LINE__ )
    call memfree (unpack_idx, __FILE__, __LINE__ )
    call memfree (ptrs_snd      , __FILE__, __LINE__ )
    call memfree (ptrs_rcv      , __FILE__, __LINE__ )
  end subroutine mpi_context_neighbours_exchange_multiple_igp
 
  !=============================================================================
  subroutine mpi_context_neighbours_exchange_wo_pack_unpack_ieep ( this, &
       &                                                              num_neighbours, &
       &                                                              neighbour_ids, &
       &                                                              snd_ptrs, &
       &                                                              snd_buf, & 
       &                                                              rcv_ptrs, &
       &                                                              rcv_buf )
    implicit none
    class(mpi_context_t)  , intent(in)    :: this 
    integer(ip)           , intent(in)    :: num_neighbours
    integer(ip)           , intent(in)    :: neighbour_ids(num_neighbours)
    integer(ip)           , intent(in)    :: snd_ptrs(num_neighbours+1)
    integer(ieep)         , intent(in)    :: snd_buf(snd_ptrs(num_neighbours+1)-1)   
    integer(ip)           , intent(in)    :: rcv_ptrs(num_neighbours+1)
    integer(ieep)         , intent(out)   :: rcv_buf(rcv_ptrs(num_neighbours+1)-1)

    ! Communication related locals 
    integer :: i, proc_to_comm, sizmsg, istat
    integer :: p2pstat(mpi_status_size)

    ! Request handlers for non-blocking receives
    integer, allocatable, dimension(:) :: rcvhd

    ! Request handlers for non-blocking receives
    integer, allocatable, dimension(:) :: sndhd

    call memalloc (num_neighbours, rcvhd, __FILE__,__LINE__)
    call memalloc (num_neighbours, sndhd, __FILE__,__LINE__)

    ! First post all the non blocking receives   
    do i=1, num_neighbours
       proc_to_comm = neighbour_ids(i) - 1

       ! Message size to be received
       sizmsg = rcv_ptrs(i+1)-rcv_ptrs(i)

       if ( (sizmsg > 0) .and. (neighbour_ids(i)-1 /= this%get_current_task()) ) then
          call mpi_irecv(  rcv_buf(rcv_ptrs(i)), sizmsg, &
               &  mpi_context_ieep, proc_to_comm, &
               &  mpi_context_tag, this%icontxt, rcvhd(i), istat)
          check ( istat == mpi_success )
       end if
    end do

    ! Secondly post all non-blocking sends
    do i=1, num_neighbours
       proc_to_comm = neighbour_ids(i) - 1

       ! Message size to be sent
       sizmsg = snd_ptrs(i+1)-snd_ptrs(i)

       if ( (sizmsg > 0) .and. (neighbour_ids(i)-1 /= this%get_current_task()) ) then 
          call mpi_isend(snd_buf(snd_ptrs(i)), sizmsg, &
               & mpi_context_ieep, proc_to_comm, &
               & mpi_context_tag, this%icontxt, sndhd(i), istat)
          check ( istat == mpi_success )
       end if
    end do

    ! Wait on all non-blocking receives
    do i=1, num_neighbours
       proc_to_comm = neighbour_ids(i) - 1

       ! Message size to be received
       sizmsg = rcv_ptrs(i+1)-rcv_ptrs(i)

       if ( (sizmsg > 0) .and. (neighbour_ids(i)-1 /= this%get_current_task()) ) then
          call mpi_wait(rcvhd(i), p2pstat, istat)
          check (istat == mpi_success)
       else if ( neighbour_ids(i)-1 == this%get_current_task() ) then
          if ( sizmsg /= snd_ptrs(i+1)-snd_ptrs(i) ) then 
             write(0,*) 'Fatal error in single_exchange: mismatch on self sendf', & 
                  & sizmsg, snd_ptrs(i+1)-snd_ptrs(i)
          end if
          rcv_buf( rcv_ptrs(i):rcv_ptrs(i+1)-1 ) = &
               snd_buf( snd_ptrs(i):snd_ptrs(i+1)-1 )
       end if
    end do

    ! Finally wait on all non-blocking sends
    do i=1, num_neighbours
       proc_to_comm = neighbour_ids(i) - 1

       ! Message size to be received
       sizmsg = snd_ptrs(i+1)-snd_ptrs(i)

       if ( (sizmsg > 0) .and. (neighbour_ids(i)-1 /= this%get_current_task()) ) then
          call mpi_wait(sndhd(i), p2pstat, istat)
          check ( istat == mpi_success )
       end if
    end do

    call memfree (rcvhd ,__FILE__,__LINE__) 
    call memfree (sndhd ,__FILE__,__LINE__)
  end subroutine mpi_context_neighbours_exchange_wo_pack_unpack_ieep


  !=============================================================================
  subroutine mpi_context_neighbours_exchange_wo_unpack_ip ( this, &
                                                            num_rcv, list_rcv, rcv_ptrs, rcv_buf, &
                                                            num_snd, list_snd, snd_ptrs, pack_idx,   &
                                                            x, chunk_size)
    implicit none
    class(mpi_context_t) , intent(in)    :: this
    ! Control info to receive
    integer(ip)             , intent(in)    :: num_rcv, list_rcv(num_rcv), rcv_ptrs(num_rcv+1)
    integer(ip)             , intent(out)   :: rcv_buf(:)
    ! Control info to send
    integer(ip)             , intent(in)    :: num_snd, list_snd(num_snd), snd_ptrs(num_snd+1)
    integer(ip)             , intent(in)    :: pack_idx (snd_ptrs(num_snd+1)-1)
    ! Raw data to be exchanged
    integer(ip)             , intent(in)    :: x(:)
    integer(ip)   , optional, intent(in)    :: chunk_size


    ! Communication related locals 
    integer :: i, proc_to_comm, sizmsg, istat
    integer :: p2pstat(mpi_status_size)

    ! Request handlers for non-blocking receives
    integer, allocatable :: rcvhd(:)

    ! Request handlers for non-blocking receives
    integer, allocatable :: sndhd(:)

    integer(ip), allocatable :: sndbuf(:) 

    integer(ip) :: chunk_size_


    if ( present(chunk_size) ) then
       chunk_size_ = chunk_size
    else
       chunk_size_ = 1
    end if

    call memalloc (num_rcv, rcvhd, __FILE__,__LINE__)
    call memalloc (num_snd, sndhd, __FILE__,__LINE__)

    call memalloc ((snd_ptrs(num_snd+1)-snd_ptrs(1))*chunk_size_, sndbuf, __FILE__,__LINE__)

    if ( snd_ptrs(num_snd+1)-snd_ptrs(1) > 0 ) then
      ! Pack send buffers
      call pack_ip ( snd_ptrs(num_snd+1)-snd_ptrs(1), chunk_size_, pack_idx, x, sndbuf )
    end if 
    
    ! First post all the non blocking receives   
    do i=1, num_rcv
       proc_to_comm = list_rcv(i) - 1 

       ! Message size to be received
       sizmsg = (rcv_ptrs(i+1)-rcv_ptrs(i))*chunk_size_

       if ( (sizmsg > 0) .and. (list_rcv(i)-1 /= this%get_current_task()) ) then
          call mpi_irecv(  rcv_buf((rcv_ptrs(i)-1)*chunk_size_+1), sizmsg,        &
               &  mpi_context_ip, proc_to_comm, &
               &  mpi_context_tag, this%icontxt, rcvhd(i), istat)
          check ( istat == mpi_success )
       end if
    end do

    ! Secondly post all non-blocking sends
    do i=1, num_snd
       proc_to_comm = list_snd(i) - 1

       ! Message size to be sent
       sizmsg = (snd_ptrs(i+1)-snd_ptrs(i))*chunk_size_

       if ( (sizmsg > 0) .and. (list_snd(i)-1 /= this%get_current_task()) ) then 
          call mpi_isend(sndbuf((snd_ptrs(i)-1)*chunk_size_+1), sizmsg, &
               & mpi_context_ip, proc_to_comm,    &
               & mpi_context_tag, this%icontxt, sndhd(i), istat)
          check ( istat == mpi_success )
       end if
    end do

    ! Wait on all non-blocking receives
    do i=1, num_rcv
       proc_to_comm = list_rcv(i) - 1

       ! Message size to be received
       sizmsg = (rcv_ptrs(i+1)-rcv_ptrs(i))*chunk_size_

       if ( (sizmsg > 0) .and. (list_rcv(i)-1 /= this%get_current_task()) ) then
          call mpi_wait(rcvhd(i), p2pstat, istat)
          check ( istat == mpi_success )
       else if ( list_rcv(i)-1 == this%get_current_task() ) then
          if ( sizmsg /= (snd_ptrs(i+1)-snd_ptrs(i))*chunk_size_ ) then 
             write(0,*) 'Fatal error in single_exchange: mismatch on self sendf', & 
                  & sizmsg, snd_ptrs(i+1)-snd_ptrs(i) 
             check(.false.)
          end if
          rcv_buf((rcv_ptrs(i)-1)*chunk_size_+1:(rcv_ptrs(i)-1)*chunk_size_+sizmsg) = &
               sndbuf( (snd_ptrs(i)-1)*chunk_size_+1:(snd_ptrs(i)-1)*chunk_size_+sizmsg )
       end if
    end do

    ! Finally wait on all non-blocking sends
    do i=1, num_snd
       proc_to_comm = list_snd(i) - 1

       ! Message size to be received
       sizmsg = (snd_ptrs(i+1)-snd_ptrs(i))*chunk_size_

       if ( (sizmsg > 0) .and. (list_snd(i)-1 /= this%get_current_task()) ) then
          call mpi_wait(sndhd(i), p2pstat, istat)
          check ( istat == mpi_success )
       end if
    end do

    call memfree (rcvhd,__FILE__,__LINE__) 
    call memfree (sndhd,__FILE__,__LINE__)

    call memfree (sndbuf,__FILE__,__LINE__)
  end subroutine mpi_context_neighbours_exchange_wo_unpack_ip

  !=============================================================================
  subroutine mpi_context_neighbours_exchange_variable_igp ( this, & 
       &                                                    num_rcv, list_rcv, rcv_ptrs, unpack_idx, & 
       &                                                    num_snd, list_snd, snd_ptrs, pack_idx,   &
       &                                                    x, y, ptr_chunk_size, mask)
    implicit none
    class(mpi_context_t), intent(in)    :: this
    ! Control info to receive
    integer(ip)             , intent(in)    :: num_rcv, list_rcv(num_rcv), rcv_ptrs(num_rcv+1)
    integer(ip)             , intent(in)    :: unpack_idx (rcv_ptrs(num_rcv+1)-1)
    ! Control info to send
    integer(ip)             , intent(in)    :: num_snd, list_snd(num_snd), snd_ptrs(num_snd+1)
    integer(ip)             , intent(in)    :: pack_idx (snd_ptrs(num_snd+1)-1)
    ! Raw data to be exchanged
    integer(igp)            , intent(in)    :: x(:)
    integer(igp)            , intent(inout) :: y(:)
    integer(ip)             , intent(in)    :: ptr_chunk_size(:)
    integer(igp)  , optional, intent(in)    :: mask

    ! Communication related locals 
    integer :: i, proc_to_comm, sizmsg, istat
    integer :: p2pstat(mpi_status_size)

    ! Request handlers for non-blocking receives
    integer, allocatable :: rcvhd(:)

    ! Request handlers for non-blocking receives
    integer, allocatable :: sndhd(:)

    integer(igp), allocatable :: sndbuf(:)
    integer(igp), allocatable :: rcvbuf(:)
    
    integer(ip) , allocatable :: ptr_chunk_size_snd(:)
    integer(ip) , allocatable :: ptr_chunk_size_rcv(:)
    
    call memalloc (num_rcv, rcvhd, __FILE__,__LINE__)
    call memalloc (num_snd, sndhd, __FILE__,__LINE__)
    
    call memalloc ( num_snd+1, ptr_chunk_size_snd, __FILE__, __LINE__ )
    call memalloc ( num_rcv+1, ptr_chunk_size_rcv, __FILE__, __LINE__ )
    
    call fill_ptr_snd_rcv_size( num_rcv,rcv_ptrs,unpack_idx,           &
                                      num_snd,snd_ptrs,pack_idx,             &
                                      ptr_chunk_size_rcv,ptr_chunk_size_snd, &
                                      ptr_chunk_size, ptr_chunk_size )
    
    call memalloc (ptr_chunk_size_snd(num_snd+1)-ptr_chunk_size_snd(1),sndbuf,__FILE__,__LINE__)
    call memalloc (ptr_chunk_size_rcv(num_rcv+1)-ptr_chunk_size_rcv(1),rcvbuf,__FILE__,__LINE__)

    if ( snd_ptrs(num_snd+1)-snd_ptrs(1) > 0 ) then
      ! Pack send buffers
      call pack_variable_igp ( snd_ptrs(num_snd+1)-snd_ptrs(1), ptr_chunk_size, pack_idx, x, sndbuf )
    end if 
    
    ! First post all the non blocking receives   
    do i=1, num_rcv
       proc_to_comm = list_rcv(i) - 1

       ! Message size to be received
       sizmsg = ptr_chunk_size_rcv(i+1)-ptr_chunk_size_rcv(i)

       if ( (sizmsg > 0) .and. (list_rcv(i)-1 /= this%get_current_task()) ) then
          call mpi_irecv(  rcvbuf(ptr_chunk_size_rcv(i)), sizmsg,        &
               &  mpi_context_igp, proc_to_comm,                         &
               &  mpi_context_tag, this%icontxt, rcvhd(i), istat)
          check ( istat == mpi_success )
       end if
    end do

    ! Secondly post all non-blocking sends
    do i=1, num_snd
       proc_to_comm = list_snd(i) - 1

       ! Message size to be sent
       sizmsg = ptr_chunk_size_snd(i+1)-ptr_chunk_size_snd(i)

       if ( (sizmsg > 0) .and. (list_snd(i)-1 /= this%get_current_task()) ) then 
          call mpi_isend(sndbuf(ptr_chunk_size_snd(i)), sizmsg,         &
               & mpi_context_igp, proc_to_comm,                          &
               & mpi_context_tag, this%icontxt, sndhd(i), istat)
          check ( istat == mpi_success )
       end if
    end do

    ! Wait on all non-blocking receives
    do i=1, num_rcv
       proc_to_comm = list_rcv(i) - 1

       ! Message size to be received
       sizmsg = ptr_chunk_size_rcv(i+1)-ptr_chunk_size_rcv(i)

       if ( (sizmsg > 0) .and. (list_rcv(i)-1 /= this%get_current_task()) ) then
          call mpi_wait(rcvhd(i), p2pstat, istat)
          check ( istat == mpi_success )
       else if ( list_rcv(i)-1 == this%get_current_task() ) then
          if ( sizmsg /= (ptr_chunk_size_snd(i+1)-ptr_chunk_size_snd(i)) ) then 
             write(0,*) 'Fatal error in single_exchange: mismatch on self sendf', & 
                  & sizmsg, ptr_chunk_size_snd(i+1)-ptr_chunk_size_snd(i) 
             check(.false.)     
          end if
          rcvbuf(   (ptr_chunk_size_rcv(i)+1):(ptr_chunk_size_rcv(i)+sizmsg) ) = &
            sndbuf( (ptr_chunk_size_snd(i)+1):(ptr_chunk_size_snd(i)+sizmsg) )
       end if
    end do

    ! Finally wait on all non-blocking sends
    do i=1, num_snd
       proc_to_comm = list_snd(i) - 1

       ! Message size to be received
       sizmsg = ptr_chunk_size_snd(i+1)-ptr_chunk_size_snd(i)

       if ( (sizmsg > 0) .and. (list_snd(i)-1 /= this%get_current_task()) ) then
          call mpi_wait(sndhd(i), p2pstat, istat)
          check ( istat == mpi_success )
       end if
    end do
    
    if ( rcv_ptrs(num_rcv+1)-rcv_ptrs(1) > 0 ) then 
      ! Unpack recv buffers
      call unpack_variable_igp (rcv_ptrs(num_rcv+1)-rcv_ptrs(1), ptr_chunk_size, unpack_idx, rcvbuf, y, mask )
    end if
    
    call memfree (rcvhd,__FILE__,__LINE__) 
    call memfree (sndhd,__FILE__,__LINE__)

    call memfree (sndbuf,__FILE__,__LINE__)
    call memfree (rcvbuf,__FILE__,__LINE__)
    
    call memfree ( ptr_chunk_size_snd, __FILE__, __LINE__ )
    call memfree ( ptr_chunk_size_rcv, __FILE__, __LINE__ )
    
  end subroutine mpi_context_neighbours_exchange_variable_igp
  
  !=============================================================================
  subroutine mpi_context_neighbours_exchange_variable_ip ( this, & 
       &                                                   num_rcv, list_rcv, rcv_ptrs, unpack_idx, & 
       &                                                   num_snd, list_snd, snd_ptrs, pack_idx,   &
       &                                                   x, y, ptr_chunk_size, mask)
    implicit none
    class(mpi_context_t), intent(in)    :: this
    ! Control info to receive
    integer(ip)             , intent(in)    :: num_rcv, list_rcv(num_rcv), rcv_ptrs(num_rcv+1)
    integer(ip)             , intent(in)    :: unpack_idx (rcv_ptrs(num_rcv+1)-1)
    ! Control info to send
    integer(ip)             , intent(in)    :: num_snd, list_snd(num_snd), snd_ptrs(num_snd+1)
    integer(ip)             , intent(in)    :: pack_idx (snd_ptrs(num_snd+1)-1)
    ! Raw data to be exchanged
    integer(ip)             , intent(in)    :: x(:)
    integer(ip)             , intent(inout) :: y(:)
    integer(ip)             , intent(in)    :: ptr_chunk_size(:)
    integer(ip)   , optional, intent(in)    :: mask

    ! Communication related locals 
    integer :: i, proc_to_comm, sizmsg, istat
    integer :: p2pstat(mpi_status_size)

    ! Request handlers for non-blocking receives
    integer, allocatable :: rcvhd(:)

    ! Request handlers for non-blocking receives
    integer, allocatable :: sndhd(:)

    integer(ip), allocatable :: sndbuf(:)
    integer(ip), allocatable :: rcvbuf(:)
    
    integer(ip) , allocatable :: ptr_chunk_size_snd(:)
    integer(ip) , allocatable :: ptr_chunk_size_rcv(:)
    
    call memalloc (num_rcv, rcvhd, __FILE__,__LINE__)
    call memalloc (num_snd, sndhd, __FILE__,__LINE__)
    
    call memalloc ( num_snd+1, ptr_chunk_size_snd, __FILE__, __LINE__ )
    call memalloc ( num_rcv+1, ptr_chunk_size_rcv, __FILE__, __LINE__ )
    
    call fill_ptr_snd_rcv_size( num_rcv,rcv_ptrs,unpack_idx,           &
                                num_snd,snd_ptrs,pack_idx,             &
                                ptr_chunk_size_rcv,ptr_chunk_size_snd, &
                                ptr_chunk_size, ptr_chunk_size )
    
    call memalloc (ptr_chunk_size_snd(num_snd+1)-ptr_chunk_size_snd(1),sndbuf,__FILE__,__LINE__)
    call memalloc (ptr_chunk_size_rcv(num_rcv+1)-ptr_chunk_size_rcv(1),rcvbuf,__FILE__,__LINE__)

    if ( snd_ptrs(num_snd+1)-snd_ptrs(1) > 0 ) then
      ! Pack send buffers
      call pack_variable_ip ( snd_ptrs(num_snd+1)-snd_ptrs(1), ptr_chunk_size, pack_idx, x, sndbuf )
    end if 
    
    ! First post all the non blocking receives   
    do i=1, num_rcv
       proc_to_comm = list_rcv(i) - 1

       ! Message size to be received
       sizmsg = ptr_chunk_size_rcv(i+1)-ptr_chunk_size_rcv(i)

       if ( (sizmsg > 0) .and. (list_rcv(i)-1 /= this%get_current_task()) ) then
          call mpi_irecv(  rcvbuf(ptr_chunk_size_rcv(i)), sizmsg,        &
               &  mpi_context_ip, proc_to_comm,                         &
               &  mpi_context_tag, this%icontxt, rcvhd(i), istat)
          check ( istat == mpi_success )
       end if
    end do

    ! Secondly post all non-blocking sends
    do i=1, num_snd
       proc_to_comm = list_snd(i) - 1

       ! Message size to be sent
       sizmsg = ptr_chunk_size_snd(i+1)-ptr_chunk_size_snd(i)

       if ( (sizmsg > 0) .and. (list_snd(i)-1 /= this%get_current_task()) ) then 
          call mpi_isend(sndbuf(ptr_chunk_size_snd(i)), sizmsg,         &
               & mpi_context_ip, proc_to_comm,                          &
               & mpi_context_tag, this%icontxt, sndhd(i), istat)
          check ( istat == mpi_success )
       end if
    end do

    ! Wait on all non-blocking receives
    do i=1, num_rcv
       proc_to_comm = list_rcv(i) - 1

       ! Message size to be received
       sizmsg = ptr_chunk_size_rcv(i+1)-ptr_chunk_size_rcv(i)

       if ( (sizmsg > 0) .and. (list_rcv(i)-1 /= this%get_current_task()) ) then
          call mpi_wait(rcvhd(i), p2pstat, istat)
          check ( istat == mpi_success )
       else if ( list_rcv(i)-1 == this%get_current_task() ) then
          if ( sizmsg /= (ptr_chunk_size_snd(i+1)-ptr_chunk_size_snd(i)) ) then 
             write(0,*) 'Fatal error in single_exchange: mismatch on self sendf', & 
                  & sizmsg, ptr_chunk_size_snd(i+1)-ptr_chunk_size_snd(i) 
             check(.false.)     
          end if
          rcvbuf(   (ptr_chunk_size_rcv(i)+1):(ptr_chunk_size_rcv(i)+sizmsg) ) = &
            sndbuf( (ptr_chunk_size_snd(i)+1):(ptr_chunk_size_snd(i)+sizmsg) )
       end if
    end do

    ! Finally wait on all non-blocking sends
    do i=1, num_snd
       proc_to_comm = list_snd(i) - 1

       ! Message size to be received
       sizmsg = ptr_chunk_size_snd(i+1)-ptr_chunk_size_snd(i)

       if ( (sizmsg > 0) .and. (list_snd(i)-1 /= this%get_current_task()) ) then
          call mpi_wait(sndhd(i), p2pstat, istat)
          check ( istat == mpi_success )
       end if
    end do
    
    if ( rcv_ptrs(num_rcv+1)-rcv_ptrs(1) > 0 ) then 
      ! Unpack recv buffers
      call unpack_variable_ip (rcv_ptrs(num_rcv+1)-rcv_ptrs(1), ptr_chunk_size, unpack_idx, rcvbuf, y, mask )
    end if
    
    call memfree (rcvhd,__FILE__,__LINE__) 
    call memfree (sndhd,__FILE__,__LINE__)

    call memfree (sndbuf,__FILE__,__LINE__)
    call memfree (rcvbuf,__FILE__,__LINE__)
    
    call memfree ( ptr_chunk_size_snd, __FILE__, __LINE__ )
    call memfree ( ptr_chunk_size_rcv, __FILE__, __LINE__ )
    
  end subroutine mpi_context_neighbours_exchange_variable_ip
  
  
  !=============================================================================
  subroutine mpi_context_gather_scalar_ip ( this, input_data, output_data )
    implicit none
    class(mpi_context_t), intent(in)   :: this
    integer(ip)         , intent(in)   :: input_data
    integer(ip)         , intent(out)  :: output_data(:) ! (this%get_num_tasks())
    integer  ::  istat
    call mpi_gather( input_data, 1, mpi_context_ip, output_data, 1, mpi_context_ip, mpi_context_root, this%icontxt, istat)
    check( istat == mpi_success )
  end subroutine mpi_context_gather_scalar_ip

  !=============================================================================
  subroutine mpi_context_scatter_scalar_ip ( this, input_data, output_data )
    implicit none
    class(mpi_context_t), intent(in)   :: this
    integer(ip)             , intent(in)   :: input_data(:) ! (this%get_num_tasks())
    integer(ip)             , intent(out)  :: output_data
    integer  ::  istat
    call mpi_scatter( input_data, 1, mpi_context_ip, output_data, 1, mpi_context_ip, mpi_context_root, this%icontxt, istat)
    check( istat == mpi_success )
  end subroutine mpi_context_scatter_scalar_ip

  !=============================================================================
  subroutine mpi_context_bcast_scalar_ip ( this, data )
    implicit none
    class(mpi_context_t), intent(in)    :: this
    integer(ip)         , intent(inout) :: data
    integer  ::  istat
    call mpi_bcast(data,1,mpi_context_ip,mpi_context_root,this%icontxt,istat); check( istat == mpi_success )
  end subroutine mpi_context_bcast_scalar_ip
  
  !=============================================================================
  subroutine mpi_context_bcast_scalar_ip_1D_array ( this, data )
    implicit none
    class(mpi_context_t), intent(in)    :: this
    integer(ip)         , intent(inout) :: data(:)
    integer  ::  istat
    call mpi_bcast(data,size(data),mpi_context_ip,mpi_context_root,this%icontxt,istat); check( istat == mpi_success )
  end subroutine mpi_context_bcast_scalar_ip_1D_array
  
  !=============================================================================
  subroutine mpi_context_gather_scalar_igp ( this, input_data, output_data )
    implicit none
    class(mpi_context_t), intent(in)   :: this
    integer(igp)         , intent(in)   :: input_data
    integer(igp)         , intent(out)  :: output_data(:) ! (this%get_num_tasks())
    integer  ::  istat
    call mpi_gather( input_data, 1, mpi_context_igp, output_data, 1, mpi_context_igp, mpi_context_root, this%icontxt, istat)
    check( istat == mpi_success )
  end subroutine mpi_context_gather_scalar_igp

  !=============================================================================
  subroutine mpi_context_scatter_scalar_igp ( this, input_data, output_data )
    implicit none
    class(mpi_context_t), intent(in)   :: this
    integer(igp)             , intent(in)   :: input_data(:) ! (this%get_num_tasks())
    integer(igp)             , intent(out)  :: output_data
    integer  ::  istat
    call mpi_scatter( input_data, 1, mpi_context_igp, output_data, 1, mpi_context_igp, mpi_context_root, this%icontxt, istat)
    check( istat == mpi_success )
  end subroutine mpi_context_scatter_scalar_igp

  !=============================================================================
  subroutine mpi_context_bcast_scalar_igp ( this, data )
    implicit none
    class(mpi_context_t), intent(in)    :: this
    integer(igp)         , intent(inout) :: data
    integer  ::  istat
    call mpi_bcast(data,1,mpi_context_igp,mpi_context_root,this%icontxt,istat); check( istat == mpi_success )
  end subroutine mpi_context_bcast_scalar_igp
  
  !=============================================================================
  subroutine pack_rp ( n, pack_idx, alpha, x, y )
    implicit none

    !Parameters
    integer (ip), intent(in)   :: n
    integer (ip), intent(in)   :: pack_idx(n)
    real    (rp), intent(in)   :: alpha
    real    (rp), intent(in)   :: x(*)
    real    (rp), intent(inout):: y(*)

    !Locals
    integer(ip) :: i

    if (alpha == 0.0_rp) then 
       !do nothing
    else if (alpha == 1.0_rp) then 
       do i=1,n
          y(i) = x(pack_idx(i))
       end do
    else if (alpha == -1.0_rp) then 
       do i=1,n
          y(i) = x(pack_idx(i))
       end do
    else  
       do i=1,n
          y(i) = alpha*x(pack_idx(i))
       end do
    end if

  end subroutine pack_rp

  !=============================================================================
  subroutine unpack_rp ( n, unpack_idx, beta, x, y )
    implicit none

    !Parameters
    integer(ip), intent(in)    :: n
    integer(ip), intent(in)    :: unpack_idx(n)
    real(rp)   , intent(in)    :: beta
    real(rp)   , intent(in)    :: x(*)
    real(rp)   , intent(inout) :: y(*)

    !Locals
    integer(ip) :: i

    if (beta == 0.0_rp) then
       do i=1,n
          y(unpack_idx(i)) = x(i)
       end do
    else if (beta == 1.0_rp) then
       do i=1,n
          y(unpack_idx(i)) = y(unpack_idx(i)) + x(i)
       end do
    else
       do i=1,n
          y(unpack_idx(i)) = beta*y(unpack_idx(i)) + x(i)
       end do
    end if
  end subroutine unpack_rp
  
  !=============================================================================
  subroutine unpack_rp_wo_beta ( n, chunk_size, unpack_idx, x, y )
    implicit none

    ! Parameters
    integer (ip), intent(in)     :: n
    integer (ip), intent(in)     :: chunk_size
    integer (ip), intent(in)     :: unpack_idx(n)
    real (rp)   , intent(in)    :: x(*)
    real (rp)   , intent(inout) :: y(*)

    ! Locals
    integer(ip) :: i, j, starty, endy, current
    current = 1
    do i=1,n
       starty = (unpack_idx(i)-1)*chunk_size + 1
       endy   = starty + chunk_size - 1
       do j=starty, endy
          y(j) = x(current)
          current = current + 1
       end do
    end do
  end subroutine unpack_rp_wo_beta
  
  !=============================================================================
  subroutine pack_ip ( n, chunk_size, pack_idx, x, y )
    implicit none

    ! Parameters
    integer (ip), intent(in)     :: n
    integer (ip), intent(in)     :: chunk_size
    integer (ip), intent(in)     :: pack_idx(n)
    integer (ip), intent(in)    :: x(*)
    integer (ip), intent(inout) :: y(*)

    ! Locals
    integer(ip) :: i, j, startx, endx
    integer(ip) :: current
    current=1
    do i=1,n
       startx = (pack_idx(i)-1)*chunk_size + 1
       endx   = startx + chunk_size - 1
       do j=startx, endx
          y(current) = x(j)
          current = current + 1
       end do
    end do
  end subroutine pack_ip
  
  !=============================================================================
  subroutine pack_rp_wo_alpha ( n, chunk_size, pack_idx, x, y )
    implicit none

    ! Parameters
    integer (ip), intent(in)     :: n
    integer (ip), intent(in)     :: chunk_size
    integer (ip), intent(in)     :: pack_idx(n)
    real (rp), intent(in)    :: x(*)
    real (rp), intent(inout) :: y(*)

    ! Locals
    integer(ip) :: i, j, startx, endx
    integer(ip) :: current
    current=1
    do i=1,n
       startx = (pack_idx(i)-1)*chunk_size + 1
       endx   = startx + chunk_size - 1
       do j=startx, endx
          y(current) = x(j)
          current = current + 1
       end do
    end do
  end subroutine pack_rp_wo_alpha
  
  !=============================================================================
  subroutine unpack_ip ( n, chunk_size, unpack_idx, x, y )
    implicit none

    ! Parameters
    integer (ip), intent(in)     :: n
    integer (ip), intent(in)     :: chunk_size
    integer (ip), intent(in)     :: unpack_idx(n)
    integer (ip), intent(in)    :: x(*)
    integer (ip), intent(inout) :: y(*)

    ! Locals
    integer(ip) :: i, j, starty, endy, current
    current = 1
    do i=1,n
       starty = (unpack_idx(i)-1)*chunk_size + 1
       endy   = starty + chunk_size - 1
       do j=starty, endy
          y(j) = x(current)
          current = current + 1
       end do
    end do
  end subroutine unpack_ip

  !=============================================================================
  subroutine pack_igp ( n, chunk_size, pack_idx, x, y )
    implicit none

    !Parameters
    integer (ip), intent(in)     :: n
    integer (ip), intent(in)     :: chunk_size
    integer (ip), intent(in)     :: pack_idx(n)
    integer (igp), intent(in)    :: x(*)
    integer (igp), intent(inout) :: y(*)

    !Locals
    integer(ip) :: i, j, startx, endx
    integer(ip) :: current
    current=1
    do i=1,n
       startx = (pack_idx(i)-1)*chunk_size + 1
       endx   = startx + chunk_size - 1
       do j=startx, endx
          y(current) = x(j)
          current = current + 1
       end do
    end do
  end subroutine pack_igp

  !=============================================================================
  subroutine pack_variable_igp ( n, ptr_chunk_size, pack_idx, x, y )
    implicit none

    !Parameters
    integer (ip), intent(in)     :: n
    integer (ip), intent(in)     :: ptr_chunk_size(:)
    integer (ip), intent(in)     :: pack_idx(n)
    integer (igp), intent(in)    :: x(*)
    integer (igp), intent(inout) :: y(*)

    !Locals
    integer(ip) :: i, j, startx, endx
    integer(ip) :: current
    current=1
    do i=1,n
       startx = ptr_chunk_size(pack_idx(i))
       endx   = ptr_chunk_size(pack_idx(i)+1)-1
       do j=startx, endx
          y(current) = x(j)
          current = current + 1
       end do
    end do
  end subroutine pack_variable_igp
  
  !=============================================================================
  subroutine pack_variable_ip ( n, ptr_chunk_size, pack_idx, x, y )
    implicit none

    !Parameters
    integer (ip), intent(in)     :: n
    integer (ip), intent(in)     :: ptr_chunk_size(:)
    integer (ip), intent(in)     :: pack_idx(n)
    integer (ip), intent(in)     :: x(*)
    integer (ip), intent(inout)  :: y(*)

    !Locals
    integer(ip) :: i, j, startx, endx
    integer(ip) :: current
    current=1
    do i=1,n
       startx = ptr_chunk_size(pack_idx(i))
       endx   = ptr_chunk_size(pack_idx(i)+1)-1
       do j=startx, endx
          y(current) = x(j)
          current = current + 1
       end do
    end do
  end subroutine pack_variable_ip
  
  !=============================================================================
  subroutine pack_variable_rp ( n, ptr_chunk_size, pack_idx, x, y )
    implicit none

    !Parameters
    integer (ip), intent(in)     :: n
    integer (ip), intent(in)     :: ptr_chunk_size(:)
    integer (ip), intent(in)     :: pack_idx(n)
    real (rp)   , intent(in)     :: x(*)
    real (rp)   , intent(inout)  :: y(*)

    !Locals
    integer(ip) :: i, j, startx, endx
    integer(ip) :: current
    current=1
    do i=1,n
       startx = ptr_chunk_size(pack_idx(i))
       endx   = ptr_chunk_size(pack_idx(i)+1)-1
       do j=startx, endx
          y(current) = x(j)
          current = current + 1
       end do
    end do
  end subroutine pack_variable_rp
  
  !=============================================================================
  subroutine unpack_igp ( n, chunk_size, unpack_idx, x, y, mask )
    implicit none

    !Parameters
    integer (ip), intent(in)     :: n
    integer (ip), intent(in)     :: chunk_size
    integer (ip), intent(in)     :: unpack_idx(n)
    integer (igp), intent(in)    :: x(*)
    integer (igp), intent(inout) :: y(*)
    integer (igp), optional, intent(in) :: mask

    !Locals
    integer(ip) :: i, j, starty, endy, current
    current = 1
    do i=1,n
       starty = (unpack_idx(i)-1)*chunk_size + 1
       endy   = starty + chunk_size - 1
       do j=starty, endy
          if (present(mask)) then
            if ( x(current) /= mask ) then
              y(j) = x(current)
            end if
          else
            y(j) = x(current)
          end if
          current = current + 1
       end do
    end do
  end subroutine unpack_igp
  
  !=============================================================================
  subroutine unpack_variable_igp ( n, ptr_chunk_size, unpack_idx, x, y, mask )
    implicit none

    !Parameters
    integer (ip), intent(in)     :: n
    integer (ip), intent(in)     :: ptr_chunk_size(:)
    integer (ip), intent(in)     :: unpack_idx(n)
    integer (igp), intent(in)    :: x(*)
    integer (igp), intent(inout) :: y(*)
    integer (igp), optional, intent(in) :: mask

    !Locals
    integer(ip) :: i, j, starty, endy, current
    current = 1
    do i=1,n
       starty = ptr_chunk_size(unpack_idx(i))
       endy   = ptr_chunk_size(unpack_idx(i)+1)-1
       do j=starty, endy
          if (present(mask)) then
            if ( x(current) /= mask ) then
              y(j) = x(current)
            end if
          else
            y(j) = x(current)
          end if
          current = current + 1
       end do
    end do
  end subroutine unpack_variable_igp
  
    !=============================================================================
  subroutine unpack_variable_ip ( n, ptr_chunk_size, unpack_idx, x, y, mask )
    implicit none

    !Parameters
    integer (ip), intent(in)     :: n
    integer (ip), intent(in)     :: ptr_chunk_size(:)
    integer (ip), intent(in)     :: unpack_idx(n)
    integer (ip), intent(in)    :: x(*)
    integer (ip), intent(inout) :: y(*)
    integer (ip), optional, intent(in) :: mask

    !Locals
    integer(ip) :: i, j, starty, endy, current
    current = 1
    do i=1,n
       starty = ptr_chunk_size(unpack_idx(i))
       endy   = ptr_chunk_size(unpack_idx(i)+1)-1
       do j=starty, endy
          if (present(mask)) then
            if ( x(current) /= mask ) then
              y(j) = x(current)
            end if
          else
            y(j) = x(current)
          end if
          current = current + 1
       end do
    end do
  end subroutine unpack_variable_ip
  
  !=============================================================================
  subroutine unpack_variable_rp ( n, ptr_chunk_size, unpack_idx, x, y )
    implicit none

    !Parameters
    integer (ip), intent(in)     :: n
    integer (ip), intent(in)     :: ptr_chunk_size(:)
    integer (ip), intent(in)     :: unpack_idx(n)
    real (rp)   , intent(in)     :: x(*)
    real (rp)   , intent(inout)  :: y(*)

    !Locals
    integer(ip) :: i, j, starty, endy, current
    current = 1
    do i=1,n
       starty = ptr_chunk_size(unpack_idx(i))
       endy   = ptr_chunk_size(unpack_idx(i)+1)-1
       do j=starty, endy
          y(j) = x(current)
          current = current + 1
       end do
    end do
  end subroutine unpack_variable_rp
  
  !=============================================================================
  subroutine fill_ptr_snd_rcv_size ( num_rcv,rcv_ptrs,unpack_idx,           &
                                     num_snd,snd_ptrs,pack_idx,             &
                                     ptr_rcv_size,ptr_snd_size,             &
                                     ptr_chunk_size_rcv,ptr_chunk_size_snd )
    implicit none

    integer(ip), intent(in)    :: num_rcv, rcv_ptrs(num_rcv+1)
    integer(ip), intent(in)    :: unpack_idx (rcv_ptrs(num_rcv+1)-1)
    integer(ip), intent(in)    :: num_snd, snd_ptrs(num_snd+1)
    integer(ip), intent(in)    :: pack_idx (snd_ptrs(num_snd+1)-1)
    integer(ip), intent(inout) :: ptr_rcv_size(:)
    integer(ip), intent(inout) :: ptr_snd_size(:)
    integer(ip), intent(in)    :: ptr_chunk_size_rcv(:)
    integer(ip), intent(in)    :: ptr_chunk_size_snd(:)
    
    integer(ip) :: i,j,k
    
    ptr_snd_size = 0
    ptr_rcv_size = 0
    
    ptr_snd_size(1) = 1
    ptr_rcv_size(1) = 1
    
    do i = 1,num_rcv
      do j = rcv_ptrs(i),rcv_ptrs(i+1)-1
        k = unpack_idx(j)
        ptr_rcv_size(i+1) = ptr_rcv_size(i+1) + & 
                               ptr_chunk_size_rcv(k+1) - ptr_chunk_size_rcv(k)
      end do
    end do
    
    do i = 1,num_rcv
      ptr_rcv_size(i+1) = ptr_rcv_size(i+1) + ptr_rcv_size(i)
    end do
    
    do i = 1,num_snd
      do j = snd_ptrs(i),snd_ptrs(i+1)-1
        k = pack_idx(j)
        ptr_snd_size(i+1) = ptr_snd_size(i+1) + & 
                               ptr_chunk_size_snd(k+1) - ptr_chunk_size_snd(k)
      end do
    end do
    
    do i = 1,num_snd
      ptr_snd_size(i+1) = ptr_snd_size(i+1) + ptr_snd_size(i)
    end do
    
  end subroutine fill_ptr_snd_rcv_size
  
  !=============================================================================
  subroutine mpi_context_send_ip ( this, rcv_task, data )
    implicit none
    class(mpi_context_t), intent(in)    :: this
    integer(ip)         , intent(in)    :: rcv_task
    integer(ip)         , intent(in)    :: data
    integer :: recv_rank, istat
    massert(rcv_task<this%get_num_tasks(),'Wrong task number in mpi_context_send_ip')
    recv_rank = rcv_task
    call mpi_send(data, 1, mpi_context_ip, recv_rank,  &
         &        mpi_context_tag, this%icontxt, istat)
    mcheck( istat == mpi_success, 'Error in mpi_context_send_ip' )
  end subroutine mpi_context_send_ip

  subroutine mpi_context_rcv_ip ( this, send_task, data )
    implicit none
    class(mpi_context_t) , intent(in)    :: this
    integer(ip)          , intent(inout) :: send_task
    integer(ip)          , intent(inout) :: data
    integer :: send_rank, istat
    if(send_task>0) then
       massert(send_task<this%get_num_tasks(),'Wrong task number in mpi_context_root_send_rcv_ip')
       send_rank = send_task
       call mpi_recv(data, 1, mpi_context_ip, send_rank,  &
            &      mpi_context_tag, this%icontxt, mpi_context_status, istat)
       mcheck( istat == mpi_success, 'Error in mpi_context_rcv_ip'  )
    else
       call mpi_recv(data, 1, mpi_context_ip, mpi_any_source,  &
            &      mpi_context_tag, this%icontxt, mpi_context_status, istat)
       mcheck( istat == mpi_success, 'Error in mpi_context_rcv_ip'  )
       send_task = mpi_context_status(mpi_source)
    end if
  end subroutine mpi_context_rcv_ip

  !=============================================================================
  subroutine mpi_context_send_igp ( this, rcv_task, data )
    implicit none
    class(mpi_context_t), intent(in)    :: this
    integer(ip)         , intent(in)    :: rcv_task
    integer(igp)        , intent(in)    :: data
    integer :: recv_rank, istat
    massert(rcv_task<this%get_num_tasks(),'Wrong task number in mpi_context_send_ip')
    recv_rank = rcv_task
    call mpi_send(data, 1, mpi_context_ip, recv_rank,  &
         &        mpi_context_tag, this%icontxt, istat)
    mcheck( istat == mpi_success, 'Error in mpi_context_send_ip' )
  end subroutine mpi_context_send_igp

  subroutine mpi_context_rcv_igp ( this, send_task, data )
    implicit none
    class(mpi_context_t) , intent(in)    :: this
    integer(ip)          , intent(inout) :: send_task
    integer(igp)         , intent(inout) :: data
    integer :: send_rank, istat
    if(send_task>0) then
       massert(send_task<this%get_num_tasks(),'Wrong task number in mpi_context_root_send_rcv_ip')
       send_rank = send_task
       call mpi_recv(data, 1, mpi_context_igp, send_rank,  &
            &      mpi_context_tag, this%icontxt, mpi_context_status, istat)
       mcheck( istat == mpi_success, 'Error in mpi_context_rcv_ip'  )
    else
       call mpi_recv(data, 1, mpi_context_igp, mpi_any_source,  &
            &      mpi_context_tag, this%icontxt, mpi_context_status, istat)
       mcheck( istat == mpi_success, 'Error in mpi_context_rcv_ip'  )
       send_task = mpi_context_status(mpi_source)
    end if
  end subroutine mpi_context_rcv_igp
  
  !=============================================================================
  subroutine mpi_context_send_rp ( this, rcv_task, data )
    implicit none
    class(mpi_context_t), intent(in)    :: this
    integer(ip)         , intent(in)    :: rcv_task
    real(rp)         , intent(in)    :: data
    integer :: recv_rank, istat
    massert(rcv_task<this%get_num_tasks(),'Wrong task number in mpi_context_send_rp')
    recv_rank = rcv_task
    call mpi_send(data, 1, mpi_context_rp, recv_rank,  &
         &        mpi_context_tag, this%icontxt, istat)
    mcheck( istat == mpi_success, 'Error in mpi_context_send_rp' )
  end subroutine mpi_context_send_rp

  subroutine mpi_context_rcv_rp ( this, send_task, data )
    implicit none
    class(mpi_context_t) , intent(in)    :: this
    integer(ip)          , intent(inout) :: send_task
    real(rp)          , intent(inout) :: data
    integer :: send_rank, istat
    if(send_task>0) then
       massert(send_task<this%get_num_tasks(),'Wrong task number in mpi_context_root_send_rcv_rp')
       send_rank = send_task
       call mpi_recv(data, 1, mpi_context_rp, send_rank,  &
            &      mpi_context_tag, this%icontxt, mpi_context_status, istat)
       mcheck( istat == mpi_success, 'Error in mpi_context_rcv_rp'  )
    else
       call mpi_recv(data, 1, mpi_context_rp, mpi_any_source,  &
            &      mpi_context_tag, this%icontxt, mpi_context_status, istat)
       mcheck( istat == mpi_success, 'Error in mpi_context_rcv_rp'  )
       send_task = mpi_context_status(mpi_source)
    end if
  end subroutine mpi_context_rcv_rp

  !=============================================================================
  subroutine mpi_context_send_ip_1D_array ( this, rcv_task, data )
    implicit none
    class(mpi_context_t), intent(in)    :: this
    integer(ip)         , intent(in)    :: rcv_task
    integer(ip)         , intent(in)    :: data(:)
    integer :: recv_rank, istat
    massert(rcv_task<this%get_num_tasks(),'Wrong task number in mpi_context_send_ip')
    recv_rank = rcv_task
    call mpi_send(data, size(data), mpi_context_ip, recv_rank,  &
         &        mpi_context_tag, this%icontxt, istat)
    mcheck( istat == mpi_success, 'Error in mpi_context_send_ip' )
  end subroutine mpi_context_send_ip_1D_array

  subroutine mpi_context_rcv_ip_1D_array ( this, send_task, data)
    implicit none
    class(mpi_context_t) , intent(in)    :: this
    integer(ip)          , intent(inout) :: send_task
    integer(ip)          , intent(inout) :: data(:)
    integer :: send_rank, istat
    if(send_task>0) then
       massert(send_task<this%get_num_tasks(),'Wrong task number in mpi_context_root_send_rcv_ip')
       send_rank = send_task
       call mpi_recv(data, size(data), mpi_context_ip, send_rank,  &
            &      mpi_context_tag, this%icontxt, mpi_context_status, istat)
       mcheck( istat == mpi_success, 'Error in mpi_context_rcv_ip'  )
    else
       call mpi_recv(data, size(data), mpi_context_ip, mpi_any_source,  &
            &      mpi_context_tag, this%icontxt, mpi_context_status, istat)
       mcheck( istat == mpi_success, 'Error in mpi_context_rcv_ip'  )
       send_task = mpi_context_status(mpi_source)
    end if
  end subroutine mpi_context_rcv_ip_1D_array

 !=============================================================================
  subroutine mpi_context_send_igp_1D_array ( this, rcv_task, data )
    implicit none
    class(mpi_context_t), intent(in)    :: this
    integer(ip)         , intent(in)    :: rcv_task
    integer(igp)        , intent(in)    :: data(:)
    integer :: recv_rank, istat
    massert(rcv_task<this%get_num_tasks(),'Wrong task number in mpi_context_send_igp')
    recv_rank = rcv_task
    call mpi_send(data, size(data), mpi_context_igp, recv_rank,  &
         &        mpi_context_tag, this%icontxt, istat)
    mcheck( istat == mpi_success, 'Error in mpi_context_send_igp' )
  end subroutine mpi_context_send_igp_1D_array

  subroutine mpi_context_rcv_igp_1D_array ( this, send_task, data)
    implicit none
    class(mpi_context_t) , intent(in)    :: this
    integer(ip)          , intent(inout) :: send_task
    integer(igp)          , intent(inout) :: data(:)
    integer :: send_rank, istat
    if(send_task>0) then
       massert(send_task<this%get_num_tasks(),'Wrong task number in mpi_context_root_send_rcv_igp')
       send_rank = send_task
       call mpi_recv(data, size(data), mpi_context_igp, send_rank,  &
            &      mpi_context_tag, this%icontxt, mpi_context_status, istat)
       mcheck( istat == mpi_success, 'Error in mpi_context_rcv_igp'  )
    else
       call mpi_recv(data, size(data), mpi_context_igp, mpi_any_source,  &
            &      mpi_context_tag, this%icontxt, mpi_context_status, istat)
       mcheck( istat == mpi_success, 'Error in mpi_context_rcv_igp'  )
       send_task = mpi_context_status(mpi_source)
    end if
  end subroutine mpi_context_rcv_igp_1D_array
  
  !=============================================================================
  subroutine mpi_context_send_rp_1D_array ( this, rcv_task, data )
    implicit none
    class(mpi_context_t), intent(in)    :: this
    integer(ip)         , intent(in)    :: rcv_task
    real(rp)         , intent(in)    :: data(:)
    integer :: recv_rank, istat
    massert(rcv_task<this%get_num_tasks(),'Wrong task number in mpi_context_send_rp')
    recv_rank = rcv_task
    call mpi_send(data, size(data), mpi_context_rp, recv_rank,  &
         &        mpi_context_tag, this%icontxt, istat)
    mcheck( istat == mpi_success, 'Error in mpi_context_send_rp' )
  end subroutine mpi_context_send_rp_1D_array

  subroutine mpi_context_rcv_rp_1D_array ( this, send_task, data)
    implicit none
    class(mpi_context_t) , intent(in)    :: this
    integer(ip)          , intent(inout) :: send_task
    real(rp)          , intent(inout) :: data(:)
    integer :: send_rank, istat
    if(send_task>0) then
       massert(send_task<this%get_num_tasks(),'Wrong task number in mpi_context_root_send_rcv_rp')
       send_rank = send_task
       call mpi_recv(data, size(data), mpi_context_rp, send_rank,  &
            &      mpi_context_tag, this%icontxt, mpi_context_status, istat)
       mcheck( istat == mpi_success, 'Error in mpi_context_rcv_rp'  )
    else
       call mpi_recv(data, size(data), mpi_context_rp, mpi_any_source,  &
            &      mpi_context_tag, this%icontxt, mpi_context_status, istat)
       mcheck( istat == mpi_success, 'Error in mpi_context_rcv_rp'  )
       send_task = mpi_context_status(mpi_source)
    end if
  end subroutine mpi_context_rcv_rp_1D_array

  !=============================================================================
  subroutine mpi_context_root_send_master_rcv_ip ( this, input_data, output_data )
    implicit none
    class(mpi_context_t), intent(in)      :: this
    integer(ip)         , intent(in)      :: input_data
    integer(ip)         , intent(inout)   :: output_data
    integer :: send_rank, recv_rank, istat
    send_rank = mpi_context_root
    recv_rank = this%get_num_tasks()-1
    if(this%get_current_task()==send_rank) then
       call mpi_send(input_data, 1, mpi_context_ip, recv_rank,  &
               & mpi_context_tag, this%icontxt, istat); check( istat == mpi_success )
    else if(this%get_current_task()==recv_rank) then
       call mpi_recv(output_data, 1, mpi_context_ip, send_rank,  &
               & mpi_context_tag, this%icontxt, mpi_context_status, istat); check( istat == mpi_success )
    end if
    end subroutine mpi_context_root_send_master_rcv_ip

  !=============================================================================
  subroutine mpi_context_root_send_master_rcv_ip_1D_array ( this, input_data, output_data )
    implicit none
    class(mpi_context_t), intent(in)      :: this
    integer(ip)         , intent(in)      :: input_data(:)
    integer(ip)         , intent(inout)   :: output_data(:)
    integer :: send_rank, recv_rank, istat
    send_rank = mpi_context_root
    recv_rank = this%get_num_tasks()-1
    if(this%get_current_task()==send_rank) then
       call mpi_send(input_data, size(input_data), mpi_context_ip, recv_rank,  &
               & mpi_context_tag, this%icontxt, istat); check( istat == mpi_success )
    else if(this%get_current_task()==recv_rank) then
       call mpi_recv(output_data, size(output_data), mpi_context_ip, send_rank,  &
               & mpi_context_tag, this%icontxt, mpi_context_status, istat); check( istat == mpi_success )
    end if
  end subroutine mpi_context_root_send_master_rcv_ip_1D_array

  !=============================================================================
  subroutine mpi_context_root_send_master_rcv_rp ( this, input_data, output_data )
    implicit none
    class(mpi_context_t), intent(in)      :: this   
    real(rp)            , intent(in)      :: input_data
    real(rp)            , intent(inout)   :: output_data
    integer :: send_rank, recv_rank, istat
    send_rank = mpi_context_root
    recv_rank = this%get_num_tasks()-1
    if(this%get_current_task()==send_rank) then
       call mpi_send(input_data, 1, mpi_context_rp, recv_rank,  &
               & mpi_context_tag, this%icontxt, istat); check( istat == mpi_success )
    else if(this%get_current_task()==recv_rank) then
       call mpi_recv(output_data, 1, mpi_context_rp, send_rank,  &
               & mpi_context_tag, this%icontxt, mpi_context_status, istat); check( istat == mpi_success )
    end if
  end subroutine mpi_context_root_send_master_rcv_rp

  !=============================================================================
  subroutine mpi_context_root_send_master_rcv_rp_1D_array ( this, input_data, output_data )
    implicit none
    class(mpi_context_t), intent(in)      :: this
    real(rp)            , intent(in)      :: input_data(:)
    real(rp)            , intent(inout)   :: output_data(:)
    integer :: send_rank, recv_rank, istat
    send_rank = mpi_context_root
    recv_rank = this%get_num_tasks()-1
    if(this%get_current_task()==send_rank) then
       call mpi_send(input_data, size(input_data), mpi_context_rp, recv_rank,  &
               & mpi_context_tag, this%icontxt, istat); check( istat == mpi_success )
    else if(this%get_current_task()==recv_rank) then
       call mpi_recv(output_data, size(output_data), mpi_context_rp, send_rank,  &
               & mpi_context_tag, this%icontxt, mpi_context_status, istat); check( istat == mpi_success )
    end if
  end subroutine mpi_context_root_send_master_rcv_rp_1D_array
  
  !=============================================================================
  subroutine mpi_context_root_send_master_rcv_logical ( this, input_data, output_data )
    implicit none
    class(mpi_context_t), intent(in)      :: this
    logical             , intent(in)      :: input_data
    logical             , intent(inout)   :: output_data
    integer :: send_rank, recv_rank, istat
    send_rank = mpi_context_root
    recv_rank = this%get_num_tasks()-1
    if(this%get_current_task()==send_rank) then
       call mpi_send(input_data, 1, mpi_context_lg, recv_rank,  &
               & mpi_context_tag, this%icontxt, istat); check( istat == mpi_success )
    else if(this%get_current_task()==recv_rank) then
       call mpi_recv(output_data, 1, mpi_context_lg, send_rank,  &
               & mpi_context_tag, this%icontxt, mpi_context_status, istat); check( istat == mpi_success )
    end if
  end subroutine mpi_context_root_send_master_rcv_logical
  
  !=============================================================================
  !=============================================================================
  subroutine mpi_context_gather_to_master_ip ( this, input_data, output_data )
    implicit none
    class(mpi_context_t), intent(in)   :: this
    integer(ip)         , intent(in)   :: input_data
    integer(ip)         , intent(out)  :: output_data(:) ! (this%get_num_tasks())
    integer  :: istat, master
    master = this%get_num_tasks() - 1 
    call mpi_gather( input_data, 1, mpi_context_ip, output_data, 1, mpi_context_ip, master, this%icontxt, istat)
    check( istat == mpi_success )
  end subroutine mpi_context_gather_to_master_ip

  !=============================================================================
  subroutine mpi_context_gather_to_master_igp ( this, input_data, output_data )
    implicit none
    class(mpi_context_t), intent(in)   :: this
    integer(igp)        , intent(in)   :: input_data
    integer(igp)        , intent(out)  :: output_data(:) ! (this%get_num_tasks())
    integer ::  istat, master
    master = this%get_num_tasks() - 1 
    call mpi_gather( input_data, 1, mpi_context_igp, output_data, 1, mpi_context_igp, master, this%icontxt, istat)
    check( istat == mpi_success )
  end subroutine mpi_context_gather_to_master_igp

  !=============================================================================
  subroutine mpi_context_gather_to_master_ip_1D_array ( this, input_data_size, input_data, output_data )
    implicit none
    class(mpi_context_t), intent(in)   :: this
    integer(ip)         , intent(in)   :: input_data_size
    integer(ip)         , intent(in)   :: input_data(input_data_size)
    integer(ip)         , intent(out)  :: output_data(:)
    integer ::  istat, master
    master    = this%get_num_tasks() - 1 
    call mpi_gather( input_data,  input_data_size, mpi_context_ip, &
         & output_data, input_data_size, mpi_context_ip, master, this%icontxt, istat)
    check( istat == mpi_success )
  end subroutine mpi_context_gather_to_master_ip_1D_array

  !=============================================================================
  subroutine mpi_context_gather_to_masterv_ip_1D_array ( this, input_data_size, input_data, recv_counts, displs, output_data )
    implicit none
    class(mpi_context_t), intent(in)   :: this
    integer(ip)             , intent(in)   :: input_data_size
    integer(ip)             , intent(in)   :: input_data(input_data_size)
    integer(ip)             , intent(in)   :: recv_counts(:) ! (this%get_num_tasks())
    integer(ip)             , intent(in)   :: displs(:) ! (this%get_num_tasks())
    integer(ip)             , intent(out)  :: output_data(:)
    integer                :: istat, master
    master    = this%get_num_tasks() - 1 
    call mpi_gatherv( input_data, input_data_size, mpi_context_ip, &
         & output_data, recv_counts, displs, mpi_context_ip, master, this%icontxt, istat)
    check( istat == mpi_success )
  end subroutine mpi_context_gather_to_masterv_ip_1D_array

  !=============================================================================
  subroutine mpi_context_gather_to_masterv_igp_1D_array ( this, input_data_size, input_data, recv_counts, displs, output_data )
    implicit none
    class(mpi_context_t), intent(in)   :: this
    integer(ip)         , intent(in)   :: input_data_size
    integer(igp)        , intent(in)   :: input_data(input_data_size)
    integer(ip)         , intent(in)   :: recv_counts(:) ! (this%get_num_tasks())
    integer(ip)         , intent(in)   :: displs(:) ! (this%get_num_tasks())
    integer(igp)        , intent(out)  :: output_data(:)
    integer :: istat, master
    master    = this%get_num_tasks() - 1 
    call mpi_gatherv( input_data, input_data_size, mpi_context_igp, &
         & output_data, recv_counts, displs, mpi_context_igp, master, this%icontxt, istat)
    check( istat == mpi_success )
  end subroutine mpi_context_gather_to_masterv_igp_1D_array

  !=============================================================================
  subroutine mpi_context_gather_to_masterv_rp_1D_array ( this, input_data_size, input_data, recv_counts, displs, output_data )
    implicit none
    class(mpi_context_t), intent(in)   :: this
    integer(ip)         , intent(in)   :: input_data_size
    real(rp)            , intent(in)   :: input_data(input_data_size)
    integer(ip)         , intent(in)   :: recv_counts(:) ! (this%get_num_tasks())
    integer(ip)         , intent(in)   :: displs(:) ! (this%get_num_tasks())
    real(rp)            , intent(out)  :: output_data(:)
    integer :: istat, master
    master = this%get_num_tasks() - 1 
    call mpi_gatherv( input_data , input_data_size, mpi_context_rp, &
         & output_data, recv_counts, displs, mpi_context_rp, master, this%icontxt, istat)
    check( istat == mpi_success )
  end subroutine mpi_context_gather_to_masterv_rp_1D_array

  !=============================================================================
  subroutine mpi_context_gather_to_masterv_rp_2D_array ( this, input_data, recv_counts, displs, output_data )
    implicit none
    class(mpi_context_t), intent(in)   :: this
    real(rp)            , intent(in)   :: input_data(:,:)
    integer(ip)         , intent(in)   :: recv_counts(:) ! (this%get_num_tasks())
    integer(ip)         , intent(in)   :: displs(:) ! (this%get_num_tasks())
    real(rp)            , intent(out)  :: output_data(:)
    integer :: istat, master
    master = this%get_num_tasks() - 1 
    call mpi_gatherv( input_data , size(input_data,1)*size(input_data,2), mpi_context_rp, &
         & output_data, recv_counts, displs, mpi_context_rp, master, this%icontxt, istat)
    check( istat == mpi_success )
  end subroutine mpi_context_gather_to_masterv_rp_2D_array

  !=============================================================================
  subroutine mpi_context_scatter_from_master_ip ( this, input_data, output_data )
    implicit none
    class(mpi_context_t), intent(in)   :: this
    integer(ip)         , intent(in)   :: input_data(:) ! (this%get_num_tasks())
    integer(ip)         , intent(out)  :: output_data
    integer  :: istat, master
    master = this%get_num_tasks() - 1 
    call mpi_scatter( input_data, 1, mpi_context_ip, output_data, 1, mpi_context_ip, master, this%icontxt, istat)
    check( istat == mpi_success )
  end subroutine mpi_context_scatter_from_master_ip

  !=============================================================================
  subroutine mpi_context_scatter_from_masterv_ip_1D_array ( this, input_data, send_counts, displs, output_data_size, output_data )
    implicit none
    class(mpi_context_t), intent(in)   :: this
    integer(ip)         , intent(in)   :: input_data(:)
    integer(ip)         , intent(in)   :: send_counts(:) ! (this%get_num_tasks())
    integer(ip)         , intent(in)   :: displs(:) ! (this%get_num_tasks())
    integer(ip)         , intent(in)   :: output_data_size
    integer(ip)         , intent(out)  :: output_data(output_data_size)
    integer :: istat, master
    master = this%get_num_tasks() - 1 
    call mpi_scatterv( input_data, send_counts, displs, mpi_context_ip, &
         & output_data, output_data_size, mpi_context_ip, master, this%icontxt, istat)
    check( istat == mpi_success )
  end subroutine mpi_context_scatter_from_masterv_ip_1D_array
  
  !=============================================================================
  subroutine mpi_context_scatter_from_masterv_rp_1D_array ( this, input_data, send_counts, displs, output_data_size, output_data )
    implicit none
    class(mpi_context_t), intent(in)   :: this
    real(rp)            , intent(in)   :: input_data(:)
    integer(ip)         , intent(in)   :: send_counts(:) ! (this%get_num_tasks())
    integer(ip)         , intent(in)   :: displs(:) ! (this%get_num_tasks())
    integer(ip)         , intent(in)   :: output_data_size
    real(rp)            , intent(out)  :: output_data(output_data_size)
    integer :: istat, master
    master = this%get_num_tasks() - 1 
    call mpi_scatterv( input_data, send_counts, displs, mpi_context_rp, &
         & output_data, output_data_size, mpi_context_rp, master, this%icontxt, istat)
    check( istat == mpi_success )
  end subroutine mpi_context_scatter_from_masterv_rp_1D_array

end module mpi_context_names
