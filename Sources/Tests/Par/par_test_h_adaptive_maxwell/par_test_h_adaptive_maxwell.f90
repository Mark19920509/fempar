program par_test_h_adaptive_maxwell
  use fempar_names
  use par_test_h_adaptive_maxwell_driver_names
  implicit none
  integer(ip) :: i
  type(par_test_h_adaptive_maxwell_fe_driver_t), save :: test_driver
  type(mpi_context_t) :: world_context 
  
  call world_context%create()
  call fempar_init()  
  call test_driver%parse_command_line_parameters()
  call test_driver%setup_environment(world_context)
  do i = 1,1
    call test_driver%setup_timers()
    call test_driver%run_simulation()
    call test_driver%report_timers()
    call test_driver%free_timers()
  end do
  call test_driver%free_environment()
  call fempar_finalize()
  call world_context%free(finalize=.true.)
  
end program par_test_h_adaptive_maxwell
