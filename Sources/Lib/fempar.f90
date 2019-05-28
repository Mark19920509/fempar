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
module fempar_names
  ! Tools
  use types_names
  use list_types_names
  use memor_names
  use allocatable_array_names
  use stdio_names
  use hash_table_names
  use postpro_names
  use environment_names 
  use environment_parameters_names 
  use execution_context_names
  use mpi_context_names
  use mpi_omp_context_names
  use serial_context_names
  use flap, only : command_line_interface
  use FPL
  use timer_names
  use fempar_parameter_handler_names
  use base_output_handler_names
  use output_handler_names
  use output_handler_parameters_names
  use output_handler_field_generator_names
  use output_handler_patch_names
  use output_handler_fe_cell_function_names
  use vtk_parameters_names
  use xh5_parameters_names
  use std_vector_names
  

  ! Geometry
  use metis_interface_names
  use mesh_distribution_names
  use mesh_distribution_parameters_names
  use triangulation_names
  use triangulation_parameters_names
  use p4est_triangulation_names
  use p4est_triangulation_parameters_names

  use cell_import_names
  use mesh_names
  use geometry_names
  use uniform_hex_mesh_generator_names
  use uniform_hex_mesh_generator_parameters_names

  ! Linear Algebra
  use iterative_linear_solver_names
  use iterative_linear_solver_parameters_names
  use iterative_linear_solver_creational_methods_dictionary_names
  use sparse_matrix_names
  use serial_scalar_array_names
  use serial_block_array_names
  use operator_names
  use vector_space_names
  use vector_names
  use matrix_names
  use array_names
  use block_sparse_matrix_names
  use block_preconditioner_l_names
  use block_preconditioner_u_names
  use block_preconditioner_lu_names
  use block_operator_names
  use block_vector_names
  use linear_solver_names
  use nonlinear_solver_names
  use direct_solver_names
  use direct_solver_parameters_names
  use direct_solver_creational_methods_dictionary_names
  
  
  use par_scalar_array_names
  use par_block_array_names
  use par_sparse_matrix_names
  use mlbddc_names
  use jacobi_preconditioner_names
  
  ! Integration 
  use reference_fe_names
  use field_names
  use polynomial_names
  use fe_space_names
  use fe_space_parameters_names
  use fe_cell_function_names
  use fe_cell_predicate_library_names
  use fe_facet_function_names
  use conditions_names
  use discrete_integration_names
  use assembler_names
  use fe_operator_names
  use function_names
  use function_library_names
  use function_parser_names
  use error_norms_names
  use error_estimator_names
  use refinement_strategy_names
  use block_layout_names
  use time_stepping_names
  
contains

  subroutine FEMPAR_INIT()
    call meminit()
    call FPL_Init()                                                       ! FPL Wrapper factory list initialization
    call the_direct_solver_creational_methods_dictionary%Init()           ! Direct solver creational methods dictionary initialization
    call the_iterative_linear_solver_creational_methods_dictionary%Init() ! Iterative linear solver creational methods dictionary initialization
    call sparse_matrix_prototype_reset()                                  ! Set to default type the sparse matrix prototype
    call output_handler_prototype_reset()                                 ! Set to default type the output prototype
!    call parameter_handler%create( &                                      ! Parameter handler default initialization
!                            description="FEMPAR (Finite Element Multiphysics PARallel solvers)")
  end subroutine


  subroutine FEMPAR_FINALIZE()
    call parameter_handler%free()                                       ! Free the parameter handler
    call FPL_Finalize()                                                   ! Free FPL Wrapper factory list
    call the_direct_solver_creational_methods_dictionary%Free()           ! Free Direct solver creational methods dictionary
    call the_iterative_linear_solver_creational_methods_dictionary%Free() ! Free Iterative linear solver creational methods dictionary
    call sparse_matrix_prototype_free()                                   ! Free the sparse matrix prototype
    call output_handler_prototype_free()                                  ! Free the output handler prototype
    call memstatus()
  end subroutine


end module fempar_names
