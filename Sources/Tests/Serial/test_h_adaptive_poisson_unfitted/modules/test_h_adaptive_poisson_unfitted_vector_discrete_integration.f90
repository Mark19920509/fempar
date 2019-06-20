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
module vector_poisson_discrete_integration_names
  use fempar_names
  use unfitted_temporary_names
  use vector_poisson_analytical_functions_names
  use unfitted_triangulations_names
  use unfitted_fe_spaces_names
  use piecewise_cell_map_names
  use blas77_interfaces_names
  use gen_eigenvalue_solver_names
  
  implicit none
# include "debug.i90"
  private
  type, extends(discrete_integration_t) :: vector_poisson_discrete_integration_t
     private
     type(vector_poisson_analytical_functions_t), pointer :: analytical_functions => NULL()
     type(fe_function_t)                        , pointer :: fe_function => NULL()    
     logical :: unfitted_boundary_is_dirichlet = .true.
     logical :: is_constant_nitches_beta       = .false.
   contains
     procedure :: set_analytical_functions
     procedure :: set_fe_function
     procedure :: set_unfitted_boundary_is_dirichlet
     procedure :: set_is_constant_nitches_beta
     procedure :: integrate_galerkin
  end type vector_poisson_discrete_integration_t
  
  public :: vector_poisson_discrete_integration_t
  
contains
   
  subroutine set_analytical_functions ( this, analytical_functions )
     implicit none
     class(vector_poisson_discrete_integration_t) , intent(inout) :: this
     type(vector_poisson_analytical_functions_t), target, intent(in)    :: analytical_functions
     this%analytical_functions => analytical_functions
  end subroutine set_analytical_functions

  subroutine set_unfitted_boundary_is_dirichlet ( this, is_dirichlet )
     implicit none
     class(vector_poisson_discrete_integration_t)    , intent(inout) :: this
     logical, intent(in) :: is_dirichlet
     this%unfitted_boundary_is_dirichlet = is_dirichlet
  end subroutine set_unfitted_boundary_is_dirichlet

  subroutine set_is_constant_nitches_beta ( this, is_constant )
     implicit none
     class(vector_poisson_discrete_integration_t)    , intent(inout) :: this
     logical, intent(in) :: is_constant
     this%is_constant_nitches_beta = is_constant
  end subroutine set_is_constant_nitches_beta

  subroutine set_fe_function (this, fe_function)
     implicit none
     class(vector_poisson_discrete_integration_t), intent(inout) :: this
     type(fe_function_t)                          , target, intent(in)    :: fe_function
     this%fe_function => fe_function
  end subroutine set_fe_function

  subroutine integrate_galerkin ( this, fe_space, assembler )
    implicit none
    class(vector_poisson_discrete_integration_t), intent(in)    :: this
    class(serial_fe_space_t)                    , intent(inout) :: fe_space
    class(assembler_t)                          , intent(inout) :: assembler

    class(fe_cell_iterator_t), allocatable  :: fe
    type(cell_map_t)         , pointer      :: cell_map
    type(quadrature_t)       , pointer      :: quad
    type(point_t)            , pointer      :: quad_coords(:)
    type(cell_integrator_t)  , pointer      :: cell_int_u
    type(vector_field_t)     , allocatable  :: shape_values_u(:,:)
    type(tensor_field_t)     , allocatable  :: shape_gradients_u(:,:)
    real(rp)                 , allocatable  :: elmat(:,:), elvec(:)
    class(vector_function_t) , pointer      :: source_term_u
    type(vector_field_t)                    :: source_term_value_u
    type(tensor_field_t)                    :: epsi_u
    type(tensor_field_t)                    :: epsi_v

    integer(ip)  :: istat
    integer(ip)  :: qpoint, num_quad_points
    integer(ip)  :: idof, jdof, num_dofs
    real(rp)     :: dV

    real(rp), parameter :: viscosity = 1.0
    integer(ip), parameter :: U_FIELD_ID = 1

    ! For Neumann facet integration
    class(fe_facet_iterator_t), allocatable :: fe_facet
    type(tensor_field_t) :: exact_sol_gradient_u
    type(vector_field_t) :: normals(2)

    !! For Nitsche
    real(rp)    :: dS
    real(rp)    :: tau
    class(vector_function_t)   , pointer      :: exact_sol_u
    type(vector_field_t)                      :: exact_sol_value_u
    type(piecewise_cell_map_t) , pointer      :: pw_cell_map
    type(vector_field_t)       , allocatable  :: boundary_shape_values_u(:,:)
    type(tensor_field_t)       , allocatable  :: boundary_shape_gradients_u(:,:)
    type(vector_field_t)                      :: normal_vec

    !class(scalar_function_t) , pointer      :: exact_sol
    !type(piecewise_cell_map_t) , pointer :: pw_cell_map
    !real(rp)            , allocatable  :: boundary_shape_values(:,:)
    !type(vector_field_t), allocatable  :: boundary_shape_gradients(:,:)
    !type(vector_field_t)               :: exact_gradient_gp
    !type(vector_field_t)               :: normal_vec
    !real(rp)                           :: normal_d
    !class(reference_fe_t), pointer :: ref_fe
    !class(quadrature_t), pointer :: nodal_quad
    !real(rp), allocatable :: elmatB(:,:), elmatV(:,:), elmatB_pre(:,:)
    !real(rp), allocatable, target :: shape2mono(:,:)
    !real(rp), pointer :: shape2mono_fixed(:,:)
    !real(rp), parameter::beta_coef=2.0_rp
    !real(rp) :: beta
    !real(rp) :: exact_sol_gp
    !real(rp), pointer :: lambdas(:,:)
    !type(gen_eigenvalue_solver_t) :: eigs

    assert (associated(this%analytical_functions))
    assert (associated(this%fe_function))

    call fe_space%create_fe_cell_iterator(fe)

    source_term_u => this%analytical_functions%get_source_term()
    exact_sol_u   => this%analytical_functions%get_solution_function()

    num_dofs = fe_space%get_max_num_dofs_on_a_cell()
    call memalloc ( num_dofs, num_dofs, elmat, __FILE__, __LINE__ )
    call memalloc ( num_dofs, elvec, __FILE__, __LINE__ )

    call fe%first()
    do while ( .not. fe%has_finished() )

       call fe%update_integration()

       quad            => fe%get_quadrature()
       num_quad_points =  quad%get_num_quadrature_points()
       cell_map        => fe%get_cell_map()
       cell_int_u      => fe%get_cell_integrator(U_FIELD_ID)
       quad_coords     => cell_map%get_quadrature_points_coordinates()

       call cell_int_u%get_values(shape_values_u)
       call cell_int_u%get_gradients(shape_gradients_u)

       elmat(:,:) = 0.0_rp
       elvec(:)   = 0.0_rp
       do qpoint = 1, num_quad_points

         dV = cell_map%get_det_jacobian(qpoint) * quad%get_weight(qpoint)

         do idof = 1, fe%get_num_dofs_field(U_FIELD_ID)
           epsi_v = (shape_gradients_u(idof,qpoint))
           do jdof= 1, fe%get_num_dofs_field(U_FIELD_ID)
             epsi_u = (shape_gradients_u(jdof,qpoint))
             elmat(idof,jdof) = elmat(idof,jdof) + dV * double_contract(epsi_v,viscosity*epsi_u)
           end do
         end do

         call source_term_u%get_value(quad_coords(qpoint),source_term_value_u)
         do idof = 1, fe%get_num_dofs_field(U_FIELD_ID)
           elvec(idof) = elvec(idof) + dV * shape_values_u(idof,qpoint) * source_term_value_u
         end do

       end do

       if (fe%is_cut()) then

         call fe%update_boundary_integration()

         quad            => fe%get_boundary_quadrature()
         num_quad_points = quad%get_num_quadrature_points()
         pw_cell_map     => fe%get_boundary_piecewise_cell_map()
         quad_coords     => pw_cell_map%get_quadrature_points_coordinates()
         cell_int_u      => fe%get_boundary_cell_integrator(U_FIELD_ID)

         call cell_int_u%get_values(boundary_shape_values_u)
         call cell_int_u%get_gradients(boundary_shape_gradients_u)

         tau = 100.0/cell_map%compute_h(1)

         do qpoint = 1, num_quad_points

           dS = pw_cell_map%get_det_jacobian(qpoint) * quad%get_weight(qpoint)
           call pw_cell_map%get_normal(qpoint,normal_vec)
           call exact_sol_u%get_value(quad_coords(qpoint),exact_sol_value_u)

           do idof = 1, fe%get_num_dofs_field(U_FIELD_ID)
             do jdof = 1, fe%get_num_dofs_field(U_FIELD_ID)
               elmat(idof,jdof) = elmat(idof,jdof) + dS * tau * boundary_shape_values_u(idof,qpoint) * boundary_shape_values_u(jdof,qpoint)
               elmat(idof,jdof) = elmat(idof,jdof) - dS * ( viscosity * boundary_shape_gradients_u(jdof,qpoint) * boundary_shape_values_u(idof,qpoint) ) * normal_vec
               elmat(idof,jdof) = elmat(idof,jdof) - dS * ( viscosity * boundary_shape_gradients_u(idof,qpoint) * boundary_shape_values_u(jdof,qpoint) ) * normal_vec
             end do
           end do

           do idof = 1, fe%get_num_dofs_field(U_FIELD_ID)
             elvec(idof) = elvec(idof) + dS * tau * boundary_shape_values_u(idof,qpoint) * exact_sol_value_u
             elvec(idof) = elvec(idof) - dS * ( viscosity * boundary_shape_gradients_u(idof,qpoint) * exact_sol_value_u ) * normal_vec
           end do

         end do

       end if

       call fe%assembly( this%fe_function, elmat, elvec, assembler )
       call fe%next()

    end do

    ! Integrate Neumann boundary conditions
    call fe_space%create_fe_facet_iterator(fe_facet)

    ! Loop in faces
    do while ( .not. fe_facet%has_finished() )

      ! Skip faces that are not in the Neumann boundary
      if ( fe_facet%get_set_id() /= -1 ) then
        call fe_facet%next(); cycle
      end if

      ! Update FE-integration related data structures
      call fe_facet%update_integration()

      quad            => fe_facet%get_quadrature()
      num_quad_points = quad%get_num_quadrature_points()

      ! Get quadrature coordinates to evaluate boundary value
      quad_coords => fe_facet%get_quadrature_points_coordinates()

      ! Get shape functions at quadrature points
      call fe_facet%get_values(1,shape_values_u,U_FIELD_ID)

      ! Compute element vector
      !facemat = 0.0_rp
      !facevec = 0.0_rp
      elmat = 0.0_rp
      elvec = 0.0_rp
      do qpoint = 1, num_quad_points

        dS = fe_facet%get_det_jacobian(qpoint) * quad%get_weight(qpoint)
        call fe_facet%get_normal(qpoint,normals)
        call exact_sol_u%get_gradient(quad_coords(qpoint),exact_sol_gradient_u)

        do idof = 1, fe_facet%get_num_dofs_field(1,U_FIELD_ID)
           elvec(idof) = elvec(idof) + dS * ( viscosity * exact_sol_gradient_u * shape_values_u(idof,qpoint) )*normals(1)
        end do

      end do

      ! We need to use the fe for assembly in order to apply the constraints
      call fe_facet%get_cell_around(1,fe)
      call fe%assembly(elmat, elvec, assembler )

      call fe_facet%next()
    end do

    call fe_space%free_fe_facet_iterator(fe_facet)

    if (allocated(shape_values_u    )) deallocate  (shape_values_u          , stat=istat); check(istat==0)
    if (allocated(shape_gradients_u )) deallocate  (shape_gradients_u       , stat=istat); check(istat==0)

    if (allocated(boundary_shape_values_u    )) deallocate  (boundary_shape_values_u          , stat=istat); check(istat==0)
    if (allocated(boundary_shape_gradients_u )) deallocate  (boundary_shape_gradients_u       , stat=istat); check(istat==0)

    !if (allocated(boundary_shape_values   )) call memfree(boundary_shape_values   , __FILE__, __LINE__)
    !if (allocated(boundary_shape_gradients)) deallocate  (boundary_shape_gradients, stat=istat); check(istat==0);
    !call memfree ( elmatB_pre, __FILE__, __LINE__ )
    !call memfree ( elmatB, __FILE__, __LINE__ )
    !call memfree ( elmatV, __FILE__, __LINE__ )
    !call memfree ( shape2mono, __FILE__, __LINE__ )
    !call eigs%free()

    call memfree ( elmat, __FILE__, __LINE__ )
    call memfree ( elvec, __FILE__, __LINE__ )
    call fe_space%free_fe_cell_iterator(fe)
  end subroutine integrate_galerkin
  
end module vector_poisson_discrete_integration_names
