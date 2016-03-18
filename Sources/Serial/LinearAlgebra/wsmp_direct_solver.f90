module wsmp_direct_solver_names
    ! Serial modules
    USE types_names
    USE memor_names
    USE sparse_matrix_names
    USE serial_scalar_array_names
    USE base_direct_solver_names
    USE FPL

    implicit none
# include "debug.i90"
  
    private

    type, extends(base_direct_solver_t) :: wsmp_direct_solver_t
    private

    contains
    private
        procedure, public :: is_linear               => wsmp_direct_solver_is_linear
        procedure, public :: free_clean_body         => wsmp_direct_solver_free_clean_body
        procedure, public :: free_symbolic_body      => wsmp_direct_solver_free_symbolic_body
        procedure, public :: free_numerical_body     => wsmp_direct_solver_free_numerical_body
        procedure         :: initialize              => wsmp_direct_solver_initialize
        procedure         :: set_defaults            => wsmp_direct_solver_set_defaults
        procedure, public :: set_parameters_from_pl  => wsmp_direct_solver_set_parameters_from_pl
        procedure, public :: symbolic_setup_body     => wsmp_direct_solver_symbolic_setup_body
        procedure, public :: numerical_setup_body    => wsmp_direct_solver_numerical_setup_body
        procedure, public :: solve_body              => wsmp_direct_solver_solve_body
    end type

contains

    subroutine wsmp_direct_solver_initialize(this)
        class(wsmp_direct_solver_t),   intent(inout) :: this
    end subroutine wsmp_direct_solver_initialize

    subroutine wsmp_direct_solver_set_defaults(this)
        class(wsmp_direct_solver_t),   intent(inout) :: this
    end subroutine wsmp_direct_solver_set_defaults

    subroutine wsmp_direct_solver_set_parameters_from_pl(this, parameter_list)
        class(wsmp_direct_solver_t),  intent(inout) :: this
        type(ParameterList_t),        intent(in)    :: parameter_list
    end subroutine wsmp_direct_solver_set_parameters_from_pl

    subroutine wsmp_direct_solver_symbolic_setup_body(this)
        class(wsmp_direct_solver_t), intent(inout) :: this
    end subroutine wsmp_direct_solver_symbolic_setup_body

    subroutine wsmp_direct_solver_numerical_setup_body(this)
        class(wsmp_direct_solver_t), intent(inout) :: this
    end subroutine wsmp_direct_solver_numerical_setup_body

    function wsmp_direct_solver_is_linear(this) result(is_linear)
        class(wsmp_direct_solver_t), intent(inout) :: this
        logical                                            :: is_linear
    end function wsmp_direct_solver_is_linear

    subroutine wsmp_direct_solver_solve_body(op, x, y)
        class(wsmp_direct_solver_t),  intent(inout) :: op
        class(serial_scalar_array_t), intent(in)    :: x
        class(serial_scalar_array_t), intent(inout) :: y
    end subroutine wsmp_direct_solver_solve_body

    subroutine wsmp_direct_solver_free_clean_body(this)
        class(wsmp_direct_solver_t), intent(inout) :: this
    end subroutine wsmp_direct_solver_free_clean_body

    subroutine wsmp_direct_solver_free_symbolic_body(this)
        class(wsmp_direct_solver_t), intent(inout) :: this
    end subroutine wsmp_direct_solver_free_symbolic_body

    subroutine wsmp_direct_solver_free_numerical_body(this)
        class(wsmp_direct_solver_t), intent(inout) :: this
    end subroutine wsmp_direct_solver_free_numerical_body

end module wsmp_direct_solver_names