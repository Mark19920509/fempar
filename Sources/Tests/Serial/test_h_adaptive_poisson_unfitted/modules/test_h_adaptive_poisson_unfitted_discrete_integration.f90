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
module poisson_unfitted_cG_discrete_integration_names
  use fempar_names
  use unfitted_temporary_names
  use poisson_analytical_functions_names
  use unfitted_triangulations_names
  use unfitted_fe_spaces_names
  use piecewise_cell_map_names
  use blas77_interfaces_names
  use gen_eigenvalue_solver_names

  implicit none
# include "debug.i90"
  private
  type, extends(discrete_integration_t) :: poisson_unfitted_cG_discrete_integration_t
     type(poisson_analytical_functions_t), pointer :: analytical_functions => NULL()
     type(fe_function_t)                          , pointer :: fe_function => NULL()    
     logical :: unfitted_boundary_is_dirichlet = .true.
     logical :: is_constant_nitches_beta       = .false.
   contains
     procedure :: set_analytical_functions
     procedure :: set_fe_function
     procedure :: set_unfitted_boundary_is_dirichlet
     procedure :: set_is_constant_nitches_beta
     procedure :: integrate_galerkin
  end type poisson_unfitted_cG_discrete_integration_t

  public :: poisson_unfitted_cG_discrete_integration_t

contains

!========================================================================================
  subroutine set_analytical_functions ( this, analytical_functions )
     implicit none
     class(poisson_unfitted_cG_discrete_integration_t)    , intent(inout) :: this
     type(poisson_analytical_functions_t), target, intent(in)    :: analytical_functions
     this%analytical_functions => analytical_functions
  end subroutine set_analytical_functions

!========================================================================================
  subroutine set_unfitted_boundary_is_dirichlet ( this, is_dirichlet )
     implicit none
     class(poisson_unfitted_cG_discrete_integration_t)    , intent(inout) :: this
     logical, intent(in) :: is_dirichlet
     this%unfitted_boundary_is_dirichlet = is_dirichlet
  end subroutine set_unfitted_boundary_is_dirichlet

!========================================================================================
  subroutine set_is_constant_nitches_beta ( this, is_constant )
     implicit none
     class(poisson_unfitted_cG_discrete_integration_t)    , intent(inout) :: this
     logical, intent(in) :: is_constant
     this%is_constant_nitches_beta = is_constant
  end subroutine set_is_constant_nitches_beta

!========================================================================================
  subroutine set_fe_function (this, fe_function)
     implicit none
     class(poisson_unfitted_cG_discrete_integration_t)       , intent(inout) :: this
     type(fe_function_t)                             , target, intent(in)    :: fe_function
     this%fe_function => fe_function
  end subroutine set_fe_function

!========================================================================================
  subroutine integrate_galerkin ( this, fe_space, assembler )
    implicit none
    class(poisson_unfitted_cG_discrete_integration_t), intent(in)    :: this
    class(serial_fe_space_t)         , intent(inout) :: fe_space
    class(assembler_t)      , intent(inout) :: assembler

    ! FE space traversal-related data types
    ! TODO We need this because the accesors and iterators are not polymorphic
    class(fe_cell_iterator_t), allocatable :: fe

    ! FE integration-related data types
    type(cell_map_t)           , pointer :: cell_map
    type(piecewise_cell_map_t) , pointer :: pw_cell_map
    type(quadrature_t)       , pointer :: quad
    type(point_t)            , pointer :: quad_coords(:)
    type(cell_integrator_t), pointer :: cell_int
    type(vector_field_t), allocatable  :: shape_gradients(:,:)
    real(rp)            , allocatable  :: shape_values(:,:)
    real(rp)            , allocatable  :: boundary_shape_values(:,:)
    type(vector_field_t), allocatable  :: boundary_shape_gradients(:,:)
    type(vector_field_t)               :: exact_gradient_gp
    type(vector_field_t)               :: normal_vec
    real(rp)                           :: normal_d

    ! FE matrix and vector i.e., A_K + f_K
    real(rp), allocatable              :: elmat(:,:), elvec(:)

    integer(ip)  :: istat
    integer(ip)  :: qpoint, num_quad_points
    integer(ip)  :: idof, jdof, num_dofs
    real(rp)     :: dV, dS
    real(rp)     :: source_term_value

    class(scalar_function_t), pointer :: source_term
    class(scalar_function_t), pointer :: exact_sol

    ! For Neumann facet integration
    class(fe_facet_iterator_t), allocatable :: fe_facet
    !real(rp), allocatable :: facemat(:,:,:,:), facevec(:,:)
    type(vector_field_t) :: exact_sol_gradient
    type(vector_field_t) :: normals(2)

    ! For Nitsche
    class(reference_fe_t), pointer :: ref_fe
    class(quadrature_t), pointer :: nodal_quad
    real(rp), allocatable :: elmatB(:,:), elmatV(:,:), elmatB_pre(:,:)
    real(rp), allocatable, target :: shape2mono(:,:)
    real(rp), pointer :: shape2mono_fixed(:,:)
    real(rp), parameter::beta_coef=2.0_rp
    real(rp) :: beta
    real(rp) :: exact_sol_gp
    real(rp), pointer :: lambdas(:,:)
    type(gen_eigenvalue_solver_t) :: eigs

    assert (associated(this%analytical_functions))
    assert (associated(this%fe_function))

    call fe_space%create_fe_cell_iterator(fe)

    source_term => this%analytical_functions%get_source_term()
    exact_sol   => this%analytical_functions%get_solution_function()

    ! Find the first non-void FE
    call fe%first_local_non_void(1)

    ! TODO We assume that all non-void FEs are the same...
    num_dofs = fe%get_num_dofs()
    call memalloc ( num_dofs, num_dofs, elmat, __FILE__, __LINE__ )
    call memalloc ( num_dofs, elvec, __FILE__, __LINE__ )

    !call memalloc ( num_dofs, num_dofs, 2, 2, facemat, __FILE__, __LINE__ )
    !call memalloc ( num_dofs,              2, facevec, __FILE__, __LINE__ )

    !This is for the Nitsche's BCs
    ! TODO  We assume same ref element for all cells, and for all fields
    ref_fe => fe%get_reference_fe(1)
    nodal_quad => ref_fe%get_nodal_quadrature()
    call memalloc ( num_dofs, num_dofs  , shape2mono, __FILE__, __LINE__ )
    call evaluate_monomials(nodal_quad,degree=this%analytical_functions%get_degree(),topology=ref_fe%get_topology(),monomials=shape2mono)    
    ! TODO  We assume that the constant monomial is the first
    shape2mono_fixed => shape2mono(:,2:)
    ! Allocate the eigenvalue solver
    call eigs%create(num_dofs - 1)

    call memalloc ( num_dofs, num_dofs, elmatB_pre, __FILE__, __LINE__ )
    call memalloc ( num_dofs-1, num_dofs-1, elmatB, __FILE__, __LINE__ )
    call memalloc ( num_dofs-1, num_dofs-1, elmatV, __FILE__, __LINE__ )

    call fe%first()
    do while ( .not. fe%has_finished() )

       ! Update FE-integration related data structures
       call fe%update_integration()

       !WARNING This has to be inside the loop
       quad            => fe%get_quadrature()
       num_quad_points = quad%get_num_quadrature_points()
       cell_map          => fe%get_cell_map()
       cell_int         => fe%get_cell_integrator(1)
       num_dofs = fe%get_num_dofs()


       ! Get quadrature coordinates to evaluate source_term
       quad_coords => cell_map%get_quadrature_points_coordinates()

       ! Compute element matrix and vector
       elmat = 0.0_rp
       elvec = 0.0_rp
       call cell_int%get_gradients(shape_gradients)
       call cell_int%get_values(shape_values)
       do qpoint = 1, num_quad_points
          dV = cell_map%get_det_jacobian(qpoint) * quad%get_weight(qpoint)
          do idof = 1, num_dofs
             do jdof = 1, num_dofs
                ! A_K(i,j) = (grad(phi_i),grad(phi_j))
                elmat(idof,jdof) = elmat(idof,jdof) + dV * shape_gradients(jdof,qpoint) * shape_gradients(idof,qpoint)
             end do
          end do

          ! Source term
          call source_term%get_value(quad_coords(qpoint),source_term_value)
          do idof = 1, num_dofs
             elvec(idof) = elvec(idof) + dV * source_term_value * shape_values(idof,qpoint)
          end do
       end do

       if (fe%is_cut()) then

         call fe%update_boundary_integration()

         ! Get info on the unfitted boundary for integrating BCs
         quad            => fe%get_boundary_quadrature()
         num_quad_points = quad%get_num_quadrature_points()
         pw_cell_map       => fe%get_boundary_piecewise_cell_map()
         quad_coords     => pw_cell_map%get_quadrature_points_coordinates()
         cell_int         => fe%get_boundary_cell_integrator(1)
         call cell_int%get_values(boundary_shape_values)
         call cell_int%get_gradients(boundary_shape_gradients)

         if (.not. this%unfitted_boundary_is_dirichlet) then
           ! Neumann BCs unfitted boundary
           do qpoint = 1, num_quad_points

             ! Surface measure
             dS = pw_cell_map%get_det_jacobian(qpoint) * quad%get_weight(qpoint)

             ! Value of the gradient of the solution at the boundary
             call exact_sol%get_gradient(quad_coords(qpoint),exact_gradient_gp)

             ! Get the boundary normals
             call pw_cell_map%get_normal(qpoint,normal_vec)

             ! Normal derivative
             ! It is save to do so in 2d only if the 3rd component is set to 0
             ! in at least one of the 2 vectors
             normal_d = normal_vec*exact_gradient_gp

             ! Integration
              do idof = 1, num_dofs
                 elvec(idof) = elvec(idof) + normal_d * boundary_shape_values(idof,qpoint) * dS
              end do

           end do

         else ! Nitsche on the unfitted boundary

           ! Nitsche beta
           if (.not. this%is_constant_nitches_beta) then

             ! Integrate the matrix associated with the normal derivatives
             elmatB_pre(:,:)=0.0_rp
             do qpoint = 1, num_quad_points
               dS = pw_cell_map%get_det_jacobian(qpoint) * quad%get_weight(qpoint)
               call pw_cell_map%get_normal(qpoint,normal_vec)
                do idof = 1, num_dofs
                   do jdof = 1, num_dofs
                      ! B_K(i,j) = (n*grad(phi_i),n*grad(phi_j))_{\partial\Omega}
                      elmatB_pre(idof,jdof) = elmatB_pre(idof,jdof) + &
                        dS *( (normal_vec*boundary_shape_gradients(jdof,qpoint)) * (normal_vec*boundary_shape_gradients(idof,qpoint)) )
                   end do
                end do
             end do

             ! Compute the matrices without the kernel
             call At_times_B_times_A(shape2mono_fixed,elmat,elmatV)
             call At_times_B_times_A(shape2mono_fixed,elmatB_pre,elmatB)

             ! Solve the eigenvalue problem
             lambdas => eigs%solve(elmatB,elmatV,istat)
             if (istat .ne. 0) then
               write(*,*) 'istat = ', istat
               write(*,*) 'lid   = ', fe%get_gid()
               write(*,*) 'elmatB = '
               do idof = 1,size(elmatB,1)
                 write(*,*) elmatB(idof,:)
               end do
               write(*,*) 'elmatV = '
               do idof = 1,size(elmatV,1)
                 write(*,*) elmatV(idof,:)
               end do
             end if
             check(istat == 0)

             ! The eigenvalue should be real. Thus, it is save to take only the real part.
             beta = beta_coef*maxval(lambdas(:,1))

           else

             beta = 100.0/cell_map%compute_h(1) 

           end if


           assert(beta>=0)

           ! Once we have the beta, we can compute Nitsche's terms
           do qpoint = 1, num_quad_points

             ! Get info at quadrature point
             dS = pw_cell_map%get_det_jacobian(qpoint) * quad%get_weight(qpoint)
             call pw_cell_map%get_normal(qpoint,normal_vec)
             call exact_sol%get_value(quad_coords(qpoint),exact_sol_gp)

             ! Elem matrix
              do idof = 1, num_dofs
                 do jdof = 1, num_dofs
                    ! A_K(i,j)=(beta*phi_i,phi_j)_{\partial\Omega} - (phi_i,n*grad(phi_j))_{\partial\Omega}  - (phi_j,n*grad(phi_i))_{\partial\Omega}
                    elmat(idof,jdof) = elmat(idof,jdof) &
                      + dS*beta*(boundary_shape_values(idof,qpoint)*boundary_shape_values(jdof,qpoint)) &
                      - dS*(boundary_shape_values(idof,qpoint)*(normal_vec*boundary_shape_gradients(jdof,qpoint))) &
                      - dS*(boundary_shape_values(jdof,qpoint)*(normal_vec*boundary_shape_gradients(idof,qpoint)))
                 end do
              end do

              ! Elem vector
              do idof = 1, num_dofs
                 ! f_k(i) = (beta*ufun,phi_i)_{\partial\Omega} - (ufun,n*grad(phi_i))_{\partial\Omega}
                 elvec(idof) = elvec(idof) &
                   + dS*beta*exact_sol_gp*boundary_shape_values(idof,qpoint) &
                   - dS*exact_sol_gp*(normal_vec*boundary_shape_gradients(idof,qpoint))
              end do

           end do

         end if !Nitsche's case

       end if ! Only for cut elems

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
      call fe_facet%get_values(1,shape_values,1)

      ! Compute element vector
      !facemat = 0.0_rp
      !facevec = 0.0_rp
      elmat = 0.0_rp
      elvec = 0.0_rp
      do qpoint = 1, num_quad_points

        dS = fe_facet%get_det_jacobian(qpoint) * quad%get_weight(qpoint)
        call fe_facet%get_normal(qpoint,normals)
        call exact_sol%get_gradient(quad_coords(qpoint),exact_sol_gradient)

        do idof = 1, fe_facet%get_num_dofs_field(1,1)
           elvec(idof) = elvec(idof) + dS * ( exact_sol_gradient*normals(1) ) * shape_values(idof,qpoint)
        end do

      end do

      ! We need to use the fe for assembly in order to apply the constraints
      call fe_facet%get_cell_around(1,fe)
      call fe%assembly(elmat, elvec, assembler )

      !call fe_facet%assembly( facemat, facevec, assembler )
      call fe_facet%next()
    end do

    call fe_space%free_fe_facet_iterator(fe_facet)

    if (allocated(shape_values            )) call memfree(shape_values            , __FILE__, __LINE__)
    if (allocated(boundary_shape_values   )) call memfree(boundary_shape_values   , __FILE__, __LINE__)
    if (allocated(shape_gradients         )) deallocate  (shape_gradients         , stat=istat); check(istat==0);
    if (allocated(boundary_shape_gradients)) deallocate  (boundary_shape_gradients, stat=istat); check(istat==0);

    !call memfree ( facemat, __FILE__, __LINE__ )
    !call memfree ( facevec, __FILE__, __LINE__ )

    call memfree ( elmat, __FILE__, __LINE__ )
    call memfree ( elvec, __FILE__, __LINE__ )
    call memfree ( elmatB_pre, __FILE__, __LINE__ )
    call memfree ( elmatB, __FILE__, __LINE__ )
    call memfree ( elmatV, __FILE__, __LINE__ )
    call memfree ( shape2mono, __FILE__, __LINE__ )
    call eigs%free()
    call fe_space%free_fe_cell_iterator(fe)
  end subroutine integrate_galerkin

end module poisson_unfitted_cG_discrete_integration_names
