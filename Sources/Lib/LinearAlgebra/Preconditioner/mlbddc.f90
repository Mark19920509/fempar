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

module mlbddc_names
 ! Tools
 use types_names
 use list_types_names
 use allocatable_array_names
 use FPL
 
 ! Integration related modules
 use triangulation_names
 use fe_space_names
 use fe_operator_names
 
 ! Linear Algebra related modules
 use operator_names
 use par_scalar_array_names
 use serial_scalar_array_names
 use vector_space_names
 use vector_names
 
 use matrix_names
 use base_sparse_matrix_names
 use sparse_matrix_parameters_names
 use sparse_matrix_names
 use par_sparse_matrix_names
 use direct_solver_names
 use direct_solver_parameters_names

#ifdef ENABLE_BLAS
 use blas77_interfaces_names
#endif

#ifdef ENABLE_LAPACK
 use lapack77_interfaces_names
#endif
  
 ! Parallel communication-related data structures
 use environment_names
 
 implicit none
# include "debug.i90"
 private

 character(len=*), parameter :: mlbddc_dirichlet_solver_params            = "mlbddc_dirichlet_solver_params"
 character(len=*), parameter :: mlbddc_neumann_solver_params              = "mlbddc_neumann_solver_params"
 character(len=*), parameter :: mlbddc_coarse_matrix_params               = "mlbddc_coarse_matrix_params"
 character(len=*), parameter :: mlbddc_coarse_matrix_symmetric_storage    = "mlbddc_coarse_matrix_symmetric_storage"
 character(len=*), parameter :: mlbddc_coarse_matrix_is_symmetric         = "mlbddc_coarse_matrix_is_symmetric"
 character(len=*), parameter :: mlbddc_coarse_matrix_sign                 = "mlbddc_coarse_matrix_sign"
 character(len=*), parameter :: mlbddc_coarse_solver_params               = "mlbddc_coarse_solver_params"
 
 integer(ip), parameter :: BASE_MLBDDC_STATE_START    = 0
 integer(ip), parameter :: BASE_MLBDDC_STATE_CREATED  = 1
 integer(ip), parameter :: BASE_MLBDDC_STATE_SYMBOLIC = 2 ! Symbolic data already computed
 integer(ip), parameter :: BASE_MLBDDC_STATE_NUMERIC  = 3 ! Numerical data already computed

  !-----------------------------------------------------------------
  ! State transition diagram for type(base_mlbddc_t)
  !-----------------------------------------------------------------
  ! Input State         | Action                | Output State 
  !-----------------------------------------------------------------
  ! Start               | create                | Created
  ! Start               | free_clean            | Start
  ! Start               | free_symbolic         | Start
  ! Start               | free_numeric          | Start
  ! Start               | update_matrix         | Start ! it does nothing

 
  ! Created             | symbolic_setup        | Symbolic         ! perform symbolic_setup()
  ! Created             | numerical_setup       | Numeric          ! perform symbolic_setup()+numerical_setup()
  ! Created             | apply                 | Numeric          ! perform symbolic_setup()+numerical_setup()
  ! Created             | free_clean            | Start
  ! Created             | free_symbolic         | Created          ! it does nothing
  ! Created             | free_numeric          | Created          ! it does nothing
  ! Created             | update_matrix         | Created          ! it does nothing

  ! Symbolic            | symbolic_setup                        | Symbolic         ! it does nothing
  ! Symbolic            | numerical_setup                       | Numeric          ! perform numerical_setup() 
  ! Symbolic            | apply                                 | Numeric          ! perform numerical_setup()
  ! Symbolic            | free_clean                            | Start
  ! Symbolic            | free_symbolic                         | Created
  ! Symbolic            | free_numeric                          | Symbolic         ! it does nothing
  ! Symbolic            | update_matrix + same_nonzero_pattern  | Symbolic         ! it does nothing
  ! Symbolic            | update_matrix + !same_nonzero_pattern | Symbolic         ! free_symbolic()+symbolic_setup()
    
    
  ! Numeric             | symbolic_setup                        | Numeric          ! it does nothing
  ! Numeric             | numeric_setup                         | Numeric          ! it does nothing
  ! Numeric             | apply                                 | Numeric          ! it does nothing
  ! Numeric             | free_numeric                          | Symbolic
  ! Numeric             | free_symbolic                         | Created
  ! Numeric             | free_clean                            | Start
  ! Numeric             | update_matrix + same_nonzero_pattern  | Numeric          ! free_numerical_setup()+numerical_setup()
  ! Numeric             | update_matrix + !same_nonzero_pattern | Numeric          ! free_numerical_setup()+free_symbolic_setup()
                                                                                   ! symbolic_setup()+numeric_setup()
 type, abstract, extends(operator_t) :: base_mlbddc_t
   private
   
   integer(ip)                                 :: state  = BASE_MLBDDC_STATE_START
   
   class(environment_t), pointer               :: environment => NULL()

   ! Constraint matrix (to be filled by a process to be customized by the user)
   type(coo_sparse_matrix_t)                   :: constraint_matrix
   
   ! Constrained Neumann problem-related member variables
   ! B = [ A C^T ]
   !     [ C   0 ]
   type(direct_solver_t)                       :: constrained_neumann_solver
   type(sparse_matrix_t)                       :: constrained_neumann_matrix
   
   ! Dirichlet problem-related member variables
   ! A => [ A_II A_IG ]
   !      [ A_GI A_GG ]
   type(direct_solver_t)                       :: dirichlet_solver
   type(sparse_matrix_t)                       :: A_II
   type(sparse_matrix_t)                       :: A_IG
   type(sparse_matrix_t)                       :: A_GI
   type(sparse_matrix_t)                       :: A_GG
   
   ! Weighting operator
   real(rp), allocatable                       :: W(:)
   
   ! Coarse-grid problem related member variables
   real(rp), allocatable                       :: phi(:,:)
  
   ! Coarse-grid matrix. It is temporarily stored in a type(par_sparse_matrix_t)
   ! data structure, although, in my opinion, in the seek of extensibility, 
   ! some sort of operator is required here that plays the same role as
   ! type(fe_nonlinear_operator_t) on L1 tasks. It will be a nullified pointer on 
   ! L1 tasks, and associated via target allocation in the case of L2-Ln tasks.
   type(par_sparse_matrix_t)     , pointer     :: coarse_grid_matrix => NULL()

   type(direct_solver_t)                       :: coarse_solver
   
   ! Next level in the preconditioning hierarchy. It will be a nullified pointer on 
   ! L1 tasks, and associated via target allocation in the case of L2-Ln tasks.
   type(mlbddc_coarse_t)         , pointer     :: mlbddc_coarse   => NULL()

   ! Pointer to parameter_list_t to be re-directed e.g. to TBPs of type(coarse_fe_handler_t).
   ! This pointer is set-up during mlbddc_t%create() and re-used in the rest of stages.
   ! Therefore, type(parameter_list_t) to which type(mlbddc_t) points to MUST NOT BE
   ! freed before type(mlbddc_t). It must contain at least three (key,value) pairs, with each 
   ! value being in turn a (sub) parameter list
   type(parameterlist_t)         , pointer     :: mlbddc_params   => NULL()
 contains
 
   ! State transition handling-related TBPs
   procedure, non_overridable, private :: set_state_start              => base_mlbddc_set_state_start
   procedure, non_overridable, private :: set_state_created            => base_mlbddc_set_state_created
   procedure, non_overridable, private :: set_state_symbolic           => base_mlbddc_set_state_symbolic
   procedure, non_overridable, private :: set_state_numeric            => base_mlbddc_set_state_numeric
   procedure, non_overridable, private :: state_is_start               => base_mlbddc_state_is_start
   procedure, non_overridable, private :: state_is_created             => base_mlbddc_state_is_created
   procedure, non_overridable, private :: state_is_symbolic            => base_mlbddc_state_is_symbolic
   procedure, non_overridable, private :: state_is_numeric             => base_mlbddc_state_is_numeric
 
 
   ! Parameter treatment-related TBPs
   procedure, non_overridable, private :: assert_dirichlet_solver_params                   => base_mlbddc_assert_dirichlet_solver_params 
   procedure, non_overridable, private :: assert_neumann_solver_params                     => base_mlbddc_assert_neumann_solver_params 
   procedure, non_overridable, private :: parse_or_transfer_coarse_matrix_params           => base_mlbddc_parse_or_transfer_coarse_matrix_params 
   procedure, non_overridable, private :: assert_coarse_solver_params                      => base_mlbddc_assert_coarse_solver_params 

   ! Symbolic setup-related TBPs
   procedure, non_overridable          :: symbolic_setup                                   => base_mlbddc_symbolic_setup
   procedure,                  private :: setup_constraint_matrix                          => base_mlbddc_setup_constraint_matrix
   procedure,                  private :: setup_weighting_operator                         => base_mlbddc_setup_weighting_operator
   procedure, non_overridable, private :: symbolic_setup_dirichlet_problem                 => base_mlbddc_symbolic_setup_dirichlet_problem
   procedure, non_overridable, private :: symbolic_setup_dirichlet_solver                  => base_mlbddc_symbolic_setup_dirichlet_solver
   procedure, non_overridable, private :: symbolic_setup_constrained_neumann_problem       => base_mlbddc_symbolic_setup_constrained_neumann_problem
   procedure, non_overridable, private :: symbolic_setup_constrained_neumann_solver        => base_mlbddc_symbolic_setup_constrained_neumann_solver
   procedure, non_overridable, private :: symbolic_setup_coarse_grid_matrix                => base_mlbddc_symbolic_setup_coarse_grid_matrix
   procedure, non_overridable, private :: coarse_grid_matrix_symbolic_assembly             => base_mlbddc_coarse_grid_matrix_symbolic_assembly 
   procedure, non_overridable, private :: symbolic_setup_mlbddc_coarse                     => base_mlbddc_symbolic_setup_mlbddc_coarse
   procedure, non_overridable, private :: symbolic_setup_coarse_solver                     => base_mlbddc_symbolic_setup_coarse_solver

   ! Numerical setup-related TBPs
   procedure, non_overridable          :: numerical_setup                                  => base_mlbddc_numerical_setup
   procedure, non_overridable, private :: numerical_setup_dirichlet_problem                => base_mlbddc_numerical_setup_dirichlet_problem
   procedure, non_overridable, private :: numerical_setup_dirichlet_solver                 => base_mlbddc_numerical_setup_dirichlet_solver
   procedure, non_overridable, private :: numerical_setup_constrained_neumann_problem      => base_mlbddc_numerical_constrained_neumann_problem
   procedure, non_overridable, private :: numerical_setup_constrained_neumann_solver       => base_mlbddc_numerical_setup_constrained_neumann_solver
   procedure, non_overridable, private :: allocate_coarse_grid_basis                       => base_mlbddc_allocate_coarse_grid_basis
   procedure, non_overridable, private :: setup_coarse_grid_basis                          => base_mlbddc_setup_coarse_grid_basis
   procedure, non_overridable, private :: compute_subdomain_elmat                          => base_mlbddc_compute_subdomain_elmat
   procedure, non_overridable, private :: compute_and_gather_subdomain_elmat               => base_mlbddc_compute_and_gather_subdomain_elmat
   procedure, non_overridable, private :: compute_subdomain_elmat_counts_and_displs        => base_mlbddc_compute_subdomain_elmat_counts_and_displs
   procedure, non_overridable, private :: numerical_setup_coarse_grid_matrix               => base_mlbddc_numerical_setup_coarse_grid_matrix
   procedure, non_overridable, private :: coarse_grid_matrix_numerical_assembly            => base_mlbddc_coarse_grid_matrix_numerical_assembly 
   procedure, non_overridable, private :: numerical_setup_mlbddc_coarse                    => base_mlbddc_numerical_setup_mlbddc_coarse
   procedure, non_overridable, private :: numerical_setup_coarse_solver                    => base_mlbddc_numerical_setup_coarse_solver

    ! Apply related TBPs
    procedure                           :: apply                                           => base_mlbddc_apply
    procedure                           :: apply_add                                       => base_mlbddc_apply_add
    procedure, non_overridable, private :: apply_par_scalar_array                          => base_mlbddc_apply_par_scalar_array
    procedure, non_overridable, private :: solve_coarse_problem                            => base_mlbddc_solve_coarse_problem
    procedure, non_overridable, private :: compute_coarse_correction                       => base_mlbddc_compute_coarse_correction
    procedure, non_overridable, private :: setup_coarse_grid_residual                      => base_mlbddc_setup_coarse_grid_residual
    procedure, non_overridable, private :: compute_coarse_dofs_values                      => base_mlbddc_compute_coarse_dofs_values
    procedure, non_overridable, private :: compute_and_gather_coarse_dofs_values           => base_mlbddc_compute_and_gather_coarse_dofs_values
    procedure, non_overridable, private :: compute_coarse_dofs_values_counts_and_displs    => base_mlbddc_compute_coarse_dofs_values_counts_and_displs
    procedure, non_overridable, private :: coarse_grid_residual_assembly                   => base_mlbddc_coarse_grid_residual_assembly
    procedure, non_overridable, private :: scatter_and_interpolate_coarse_grid_correction  => base_mlbddc_scatter_and_interpolate_coarse_grid_correction
    procedure, non_overridable, private :: scatter_coarse_grid_correction                  => base_mlbddc_scatter_coarse_grid_correction
    procedure, non_overridable, private :: fill_coarse_dofs_values_scattered               => base_mlbddc_fill_coarse_dofs_values_scattered
    procedure, non_overridable, private :: interpolate_coarse_grid_correction              => base_mlbddc_interpolate_coarse_grid_correction
    procedure, non_overridable, private :: solve_dirichlet_problem                         => base_mlbddc_solve_dirichlet_problem
    procedure, non_overridable, private :: apply_A_GI                                      => base_mlbddc_apply_A_GI
    procedure, non_overridable, private :: apply_A_IG                                      => base_mlbddc_apply_A_IG
    procedure, non_overridable, private :: solve_constrained_neumann_problem               => base_mlbddc_solve_constrained_neumann_problem
    procedure,                  private :: apply_weighting_operator_and_comm               => base_mlbddc_apply_weighting_operator_and_comm
    procedure,                  private :: apply_transpose_weighting_operator              => base_mlbddc_apply_transpose_weighting_operator
    procedure, non_overridable, private :: create_interior_interface_views                 => base_mlbddc_create_interior_interface_views
   
   ! Free-related TBPs
   procedure, non_overridable          :: free                                             => base_mlbddc_free
   procedure, non_overridable          :: free_clean                                       => base_mlbddc_free_clean
   procedure, non_overridable          :: free_symbolic_setup                              => base_mlbddc_free_symbolic_setup
   procedure, non_overridable          :: free_symbolic_setup_dirichlet_problem            => base_mlbddc_free_symbolic_setup_dirichlet_problem
   procedure, non_overridable          :: free_symbolic_setup_dirichlet_solver             => base_mlbddc_free_symbolic_setup_dirichlet_solver
   procedure, non_overridable          :: free_symbolic_setup_constrained_neumann_problem  => base_mlbddc_free_symbolic_setup_constrained_neumann_problem
   procedure, non_overridable          :: free_symbolic_setup_constrained_neumann_solver   => base_mlbddc_free_symbolic_setup_constrained_neumann_solver
   procedure, non_overridable          :: free_symbolic_setup_coarse_solver                => base_mlbddc_free_symbolic_setup_coarse_solver
    
   procedure, non_overridable          :: free_numerical_setup                             => base_mlbddc_free_numerical_setup
   procedure, non_overridable          :: free_numerical_setup_dirichlet_problem           => base_mlbddc_free_numerical_setup_dirichlet_problem
   procedure, non_overridable          :: free_numerical_setup_dirichlet_solver            => base_mlbddc_free_numerical_setup_dirichlet_solver
   procedure, non_overridable          :: free_numerical_setup_constrained_neumann_problem => base_mlbddc_free_numerical_setup_constrained_neumann_problem
   procedure, non_overridable          :: free_numerical_setup_constrained_neumann_solver  => base_mlbddc_free_numerical_setup_constrained_neumann_solver
   procedure, non_overridable          :: free_coarse_grid_basis                           => base_mlbddc_free_coarse_grid_basis
   procedure, non_overridable          :: free_numerical_setup_coarse_solver               => base_mlbddc_free_numerical_setup_coarse_solver
   
   
   procedure, non_overridable, private :: am_i_l1_task                                     => base_mlbddc_am_i_l1_task
   procedure                           :: is_linear                                        => base_mlbddc_is_linear
   procedure, private                  :: get_par_environment                              => base_mlbddc_get_par_environment
   procedure, private                  :: set_par_environment                              => base_mlbddc_set_par_environment
   
   ! TBPs which are though to be overrided by sub_classes
   procedure, private                  :: get_par_sparse_matrix                            => base_mlbddc_get_par_sparse_matrix
   procedure, private                  :: get_fe_space                                     => base_mlbddc_get_fe_space
   procedure, private                  :: is_operator_associated                           => base_mlbddc_is_operator_associated
   procedure, private                  :: nullify_operator                                 => base_mlbddc_nullify_operator
   procedure, private                  :: create_vector_spaces                             => base_mlbddc_create_vector_spaces
end type base_mlbddc_t
 
 type, extends(base_mlbddc_t) :: mlbddc_t
   !<graph: false
   private
   ! Pointer to parameter_list_t to be re-directed to TBPs of type(coarse_fe_handler_t)
   ! This pointer is set-up during mlbddc_t%create() and re-used in the rest of stages.
   ! Therefore, type(parameter_list_t) to which type(mlbddc_t) points to MUST NOT BE
   ! freed before type(mlbddc_t)
   type(parameterlist_t)            , pointer :: parameter_list
   
   ! Pointer to the fe_nonlinear_operator_t this mlbddc_t instance has been created from
   type(fe_operator_t)    , pointer :: fe_nonlinear_operator => NULL()
 contains
    procedure, non_overridable          :: create                                          => mlbddc_create
    procedure,                  private :: create_vector_spaces                            => mlbddc_create_vector_spaces

    ! Symbolic-setup related TBPs
    procedure,                  private :: setup_constraint_matrix                         => mlbddc_setup_constraint_matrix
    procedure,                  private :: setup_weighting_operator                        => mlbddc_setup_weighting_operator

    ! Apply weighting related TBPs
    procedure,                  private :: apply_weighting_operator_and_comm                  => mlbddc_apply_weighting_operator_and_comm
    procedure,                  private :: apply_transpose_weighting_operator                 => mlbddc_apply_transpose_weighting_operator

    ! Update-matrix related TBPs
    procedure                           :: update_matrix                                   => mlbddc_update_matrix
    procedure                           :: reallocate_after_remesh                         => mlbddc_reallocate_after_remesh

    ! Miscellaneous 
    procedure, private                  :: get_par_sparse_matrix                            => mlbddc_get_par_sparse_matrix
    procedure, private                  :: get_fe_space                                     => mlbddc_get_fe_space
    procedure, private                  :: get_par_fe_space                                 => mlbddc_get_par_fe_space
    procedure                 , private :: is_operator_associated                           => mlbddc_is_operator_associated
    procedure                 , private :: nullify_operator                                 => mlbddc_nullify_operator 
 end type mlbddc_t
  
 type, extends(base_mlbddc_t) :: mlbddc_coarse_t 
   private
   ! Some sort of operator is required here that plays the role of type(mlbddc_t)%fe_affine_operator.
   ! This operator should be built on the previous level and passed here. Let us use the 
   ! coarse_fe_space built on the previous level in the mean time.
   type(coarse_fe_space_t)       , pointer     :: fe_space          => NULL()
   type(par_sparse_matrix_t)     , pointer     :: par_sparse_matrix => NULL()
 contains
 
   procedure, non_overridable          :: create                                            => mlbddc_coarse_create
   procedure, private                  :: create_vector_spaces                              => mlbddc_coarse_create_vector_spaces
   
   
   ! Symbolic setup-related TBPs
   procedure,                  private :: setup_constraint_matrix                           => mlbddc_coarse_setup_constraint_matrix
   procedure,                  private :: setup_weighting_operator                          => mlbddc_coarse_setup_weighting_operator
   
   ! Apply weighting related TBPs
   procedure,                  private :: apply_weighting_operator_and_comm                  => mlbddc_coarse_apply_weighting_operator_and_comm
   procedure,                  private :: apply_transpose_weighting_operator                 => mlbddc_coarse_apply_transpose_weighting_operator
      
          
   procedure, private                  :: get_par_sparse_matrix                            => mlbddc_coarse_get_par_sparse_matrix
   procedure, private                  :: get_fe_space                                     => mlbddc_coarse_get_fe_space
   procedure, private                  :: get_coarse_fe_space                              => mlbddc_coarse_get_coarse_fe_space
   procedure                 , private :: is_operator_associated                           => mlbddc_coarse_is_operator_associated
   procedure                 , private :: nullify_operator                                 => mlbddc_coarse_nullify_operator 
 end type mlbddc_coarse_t
 
 public :: mlbddc_t
 public :: mlbddc_dirichlet_solver_params, mlbddc_neumann_solver_params, mlbddc_coarse_solver_params
 public :: mlbddc_coarse_matrix_params, mlbddc_coarse_matrix_symmetric_storage, mlbddc_coarse_matrix_is_symmetric, mlbddc_coarse_matrix_sign
 public :: setup_mlbddc_parameters_from_reference_parameters

contains
    subroutine setup_mlbddc_parameters_from_reference_parameters(environment, reference_parameters, mlbddc_parameters)
      implicit none
      type(environment_t)          , intent(in)    :: environment
      type(parameterlist_t)        , intent(in)    :: reference_parameters
      type(parameterlist_t), target, intent(inout) :: mlbddc_parameters
      integer(ip) :: ilev
      type(parameterlist_t), pointer :: current
      type(parameterlist_t), pointer :: dirichlet
      type(parameterlist_t), pointer :: neumann
      type(parameterlist_t), pointer :: coarse
      call mlbddc_parameters%free()
      call mlbddc_parameters%init()
      current => mlbddc_parameters
      if ( environment%get_l1_size() == 1 ) then
         ! When there is a single task at level L1, the stiffness matrix 
         ! is not actually distributed among processors. In such a degenerated 
         ! case mlbddc extracts the parameters to be used for the solver of the
         ! (non-distributed) matrix directly from the list, i.e., it does not extract it
         ! from the sublist corresponding to neither dirichlet_..., neumann_..., and coarse_solver
         ! parameters
         current = reference_parameters
      end if
      do ilev=1, environment%get_num_levels()-1
         ! Set current level Dirichlet solver parameters
         dirichlet => current%NewSubList(key=mlbddc_dirichlet_solver_params)
         dirichlet = reference_parameters
         ! Set current level Neumann solver parameters
         neumann   => current%NewSubList(key=mlbddc_neumann_solver_params)
         neumann   = reference_parameters
         ! Generate a new sublist for the next level
         coarse    => current%NewSubList(key=mlbddc_coarse_solver_params) 
         current   => coarse 
      end do
      ! Set coarsest-grid solver parameters
      coarse = reference_parameters
    end subroutine setup_mlbddc_parameters_from_reference_parameters
    
#include "sbm_base_mlbddc.i90"
#include "sbm_mlbddc.i90"
#include "sbm_mlbddc_coarse.i90"

end module mlbddc_names
