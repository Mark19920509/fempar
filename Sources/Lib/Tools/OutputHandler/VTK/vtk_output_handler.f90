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
!---------------------------------------------------------------------
!*Author: Víctor Sande
! Date: 2016-11-28
! Version: 0.0.1
! Category: IO
!
!---------------------------------------------------------------------
!### Software subsystem implementing the VTK IO layer.
!
! Contains the following public entities:
! [[vtk_output_handler_names(module)]]
! 
! @note Look at [[base_output_handler_names(module)]] to see the
! *state transition diagram*
!---------------------------------------------------------------------
module vtk_output_handler_names
!---------------------------------------------------------------------
!*Author: Víctor Sande
! Date: 2016-11-28
! Version: 0.0.1
! Category: IO
!
!---------------------------------------------------------------------
!### Software subsystem implementing the VTK IO layer.
!
! Contains the following public entities:
! [[vtk_output_handler_t(type)]]
! 
!---------------------------------------------------------------------
USE types_names
USE memor_names
USE lib_vtk_io
USE environment_names
USE vtk_utils_names
USE base_output_handler_names
USE output_handler_fe_field_names
USE output_handler_parameters_names
USE output_handler_field_generator_names
USE vtk_parameters_names
USE FPL,                        only: ParameterList_t
USE fe_space_names,             only: serial_fe_space_t
USE output_handler_patch_names, only: patch_subcell_accessor_t
USE IR_Precision,               only: I1P, str


implicit none
#include "debug.i90"
private

    type, extends(base_output_handler_t) :: vtk_output_handler_t
    !-----------------------------------------------------------------
    !*Author: Víctor Sande
    ! Date: 2016-11-28
    ! Version: 0.0.1
    ! Category: IO
    ! 
    !-----------------------------------------------------------------
    !### Read/write VTK mesh files and results
    !
    ! [[vtk_output_handler_t(type)]] is a fully functional
    ! entity which extends from [[base_output_handler_t(type)]] and 
    ! implements its deferred procedures.
    !
    ! This data type uses LibVTKIO in order to perform VTK IO.
    !
    ! @note It's desirable to manage the state transition only from
    !       [[base_output_handler_t(type)]] type.
    ! 
    !-----------------------------------------------------------------
    private 
        character(:), allocatable                             :: FilePrefix
        character(:), allocatable                             :: Path
        character(:), allocatable                             :: vtk_format
        logical                                               :: StaticGrid
        real(rp),                                 allocatable :: X(:)
        real(rp),                                 allocatable :: Y(:)
        real(rp),                                 allocatable :: Z(:)
        integer(ip),                              allocatable :: Offset(:)
        integer(I1P),                             allocatable :: CellTypes(:)
        integer(ip),                              allocatable :: Connectivities(:)
        type(output_handler_fe_field_2D_value_t), allocatable :: FieldValues(:)
        type(output_handler_fe_field_1D_value_t), allocatable :: CellValues(:)
        real(rp),                                 allocatable :: Times(:)
        integer(ip)                                           :: num_steps = 0
        integer(ip)                                           :: node_offset  = 0
        integer(ip)                                           :: cell_offset  = 0
    contains
    private
        procedure, non_overridable        :: resize_times_if_needed         => vtk_output_handler_resize_times_if_needed
        procedure, non_overridable        :: write_vtu                      => vtk_output_handler_write_vtu
        procedure, non_overridable        :: write_pvtu                     => vtk_output_handler_write_pvtu
        procedure, non_overridable        :: write_pvd                      => vtk_output_handler_write_pvd
        procedure,                 public :: create_body                    => vtk_output_handler_create_body
        procedure,                 public :: open_body                      => vtk_output_handler_open_body
        procedure,                 public :: append_time_step               => vtk_output_handler_append_time_step
        procedure,                 public :: write                          => vtk_output_handler_write
        procedure                         :: allocate_cell_and_nodal_arrays => vtk_output_handler_allocate_cell_and_nodal_arrays
        procedure                         :: append_cell                    => vtk_output_handler_append_cell
        procedure,                 public :: close_body                     => vtk_output_handler_close_body
        procedure                         :: free_body                      => vtk_output_handler_free_body
    end type

public :: vtk_output_handler_t

contains


    subroutine vtk_output_handler_create_body(this, parameter_list)
    !-----------------------------------------------------------------
    !< Open procedure. Set parameters from parameter list and args
    !-----------------------------------------------------------------
        class(vtk_output_handler_t),     intent(inout) :: this
        type(ParameterList_t), optional, intent(in)    :: parameter_list
        integer(ip)                                    :: FPLError
    !-----------------------------------------------------------------
        ! Set defaults
        this%vtk_format = output_handler_vtk_format_default
        this%StaticGrid = output_handler_vtk_static_grid_default

        if(present(parameter_list)) then
            if(parameter_list%isPresent(output_handler_vtk_format_key)) then
                assert(parameter_list%isAssignable(output_handler_vtk_format_key, 'string'))
                FPLError   = parameter_list%GetAsString(Key=output_handler_vtk_format_key, String=this%vtk_format)
                assert(FPLError == 0)
            endif

            if(parameter_list%isPresent(output_handler_static_grid_key)) then
                assert(parameter_list%isAssignable(output_handler_static_grid_key, this%StaticGrid))
                FPLError   = parameter_list%Get(Key=output_handler_static_grid_key, Value=this%StaticGrid)
                assert(FPLError == 0)
            endif
        endif
    end subroutine vtk_output_handler_create_body


    subroutine vtk_output_handler_free_body(this)
    !-----------------------------------------------------------------
    !< Free procedure
    !-----------------------------------------------------------------
        class(vtk_output_handler_t), intent(inout) :: this
        integer(ip)                                :: i
    !-----------------------------------------------------------------
        if(allocated(this%Path))           deallocate(this%Path)
        if(allocated(this%FilePrefix))     deallocate(this%FilePrefix)
        if(allocated(this%vtk_format))     deallocate(this%vtk_format)
        if(allocated(this%X))              call memfree(this%X,              __FILE__, __LINE__)
        if(allocated(this%Y))              call memfree(this%Y,              __FILE__, __LINE__)
        if(allocated(this%Z))              call memfree(this%Z,              __FILE__, __LINE__)
        if(allocated(this%Offset))         call memfree(this%Offset,         __FILE__, __LINE__)
        if(allocated(this%CellTypes))      call memfree(this%CellTypes,      __FILE__, __LINE__)
        if(allocated(this%Connectivities)) call memfree(this%Connectivities, __FILE__, __LINE__)
        if(allocated(this%Times))          call memfree(this%Times,          __FILE__, __LINE__)
        if(allocated(this%FieldValues)) then
            do i=1, size(this%Fieldvalues)
                call this%FieldValues(i)%Free()
            enddo
            deallocate(this%FieldValues)
        endif
        if(allocated(this%CellValues)) then
            do i=1, size(this%Cellvalues)
                call this%CellValues(i)%Free()
            enddo
            deallocate(this%CellValues)
        endif
        this%node_offset  = 0
        this%cell_offset  = 0
        this%num_steps = 0
    end subroutine vtk_output_handler_free_body


    subroutine vtk_output_handler_open_body(this, dir_path, prefix)
    !-----------------------------------------------------------------
    !< Open procedure. Set parameters from parameter list and args
    !-----------------------------------------------------------------
        class(vtk_output_handler_t),     intent(inout) :: this
        character(len=*),                intent(in)    :: dir_path
        character(len=*),                intent(in)    :: prefix
    !-----------------------------------------------------------------
        this%Path       = dir_path
        this%FilePrefix = prefix
    end subroutine vtk_output_handler_open_body


    subroutine vtk_output_handler_resize_times_if_needed(this, num_steps)
    !-----------------------------------------------------------------
    !< Resize Times steps array if needed for the new num_steps
    !-----------------------------------------------------------------
        class(vtk_output_handler_t), intent(inout) :: this
        integer(ip),                 intent(in)    :: num_steps
        integer(ip)                                :: new_size 
    !-----------------------------------------------------------------
        if(.not. allocated(this%Times)) then
            call memalloc(100, this%times, __FILE__, __LINE__)
        elseif(num_steps > size(this%Times)) then
            new_size = int(1.5*size(this%Times))
            call memrealloc(new_size,this%Times,__FILE__,__LINE__)
        endif
    end subroutine vtk_output_handler_resize_times_if_needed

    
    subroutine vtk_output_handler_append_time_step(this, value)
    !-----------------------------------------------------------------
    !< Append a new time step
    !-----------------------------------------------------------------
        class(vtk_output_handler_t), intent(inout) :: this
        real(rp),                    intent(in)    :: value
        class(serial_fe_space_t),        pointer   :: fe_space
        type(environment_t),             pointer   :: environment
    !-----------------------------------------------------------------
        fe_space          => this%get_fe_space()
        assert(associated(fe_space))
        environment   => fe_space%get_environment()
        assert(associated(environment))

        if( environment%am_i_l1_task()) then
            this%num_steps = this%num_steps + 1
            call this%resize_times_if_needed(this%num_steps)
            this%Times(this%num_steps) = value
        endif
        this%node_offset = 0
        this%cell_offset = 0
    end subroutine vtk_output_handler_append_time_step


    subroutine vtk_output_handler_allocate_cell_and_nodal_arrays(this)
    !-----------------------------------------------------------------
    !< Allocate cell and nodal arrays
    !-----------------------------------------------------------------
        class(vtk_output_handler_t), intent(inout) :: this
        integer(ip)                                :: num_nodes
        integer(ip)                                :: num_cells
        type(output_handler_fe_field_t), pointer   :: field
        type(output_handler_field_generator_info_t), pointer :: field_generator
        integer(ip)                                :: i
    !-----------------------------------------------------------------
        num_nodes = this%get_num_nodes()
        num_cells = this%get_num_cells()
        if(allocated(this%X)) then
            call memrealloc(num_nodes, this%X,              __FILE__, __LINE__)
        else
            call memalloc(  num_nodes, this%X,              __FILE__, __LINE__)
        endif
        if(allocated(this%Y)) then
            call memrealloc(num_nodes, this%Y,              __FILE__, __LINE__)
        else
            call memalloc(  num_nodes, this%Y,              __FILE__, __LINE__)
        endif
        if(allocated(this%Z)) then
            call memrealloc(num_nodes, this%Z,              __FILE__, __LINE__,0.0_rp)
        else
            call memalloc(  num_nodes, this%Z,              __FILE__, __LINE__,0.0_rp)
        endif
        if(allocated(this%Offset)) then
            call memrealloc(num_cells, this%Offset,         __FILE__, __LINE__)
        else
            call memalloc(  num_cells, this%Offset,         __FILE__, __LINE__)
        endif
        if(allocated(this%CellTypes)) then
            call memrealloc(num_cells, this%CellTypes,      __FILE__, __LINE__)
        else
            call memalloc(  num_cells, this%CellTypes,      __FILE__, __LINE__)
        endif
        if(allocated(this%Connectivities)) then
            call memrealloc(num_nodes, this%Connectivities, __FILE__, __LINE__)
        else
            call memalloc(  num_nodes, this%Connectivities, __FILE__, __LINE__)
        endif
        do i=1, this%get_num_fields()
            field => this%get_fe_field(i)
            call this%FieldValues(i)%create(field%get_num_components(), this%get_num_nodes())
            call this%FieldValues(i)%init(0.0_rp)
        end do
        do i=1, this%get_num_field_generators()
            field_generator => this%get_field_generator(i)
            call this%FieldValues(this%get_num_fields()+i)%create(field_generator%get_num_components(), this%get_num_nodes())
            call this%FieldValues(this%get_num_fields()+i)%init(0.0_rp)
        end do
        do i=1, this%get_num_cell_vectors()
            call this%CellValues(i)%create(1, this%get_num_cells())
            call this%CellValues(i)%init(0.0_rp)
        enddo
    end subroutine vtk_output_handler_allocate_cell_and_nodal_arrays


    subroutine vtk_output_handler_append_cell(this, subcell_accessor)
    !-----------------------------------------------------------------
    !< Append cell data to global arrays
    !-----------------------------------------------------------------
        class(vtk_output_handler_t), intent(inout) :: this
        type(patch_subcell_accessor_t), intent(in) :: subcell_accessor
        real(rp),    allocatable                   :: Coordinates(:,:)
        integer(ip), allocatable                   :: Connectivity(:)
        real(rp),                        pointer   :: FieldValue(:,:)
        real(rp),                        pointer   :: CellValue(:)
        integer(ip)                                :: num_vertices
        integer(ip)                                :: num_dims
        integer(ip)                                :: num_fields
        integer(ip)                                :: num_field_generators
        integer(ip)                                :: num_cell_vectors
        integer(ip)                                :: num_components
        integer(ip)                                :: i
    !-----------------------------------------------------------------
        num_vertices     = subcell_accessor%get_num_vertices()
        num_dims   = subcell_accessor%get_num_dims()
        num_fields       = this%get_num_fields()
        num_field_generators = this%get_num_field_generators()
        num_cell_vectors = this%get_num_cell_vectors()

        if(.not. this%StaticGrid .or. this%num_steps <= 1) then 
            call subcell_accessor%get_coordinates(this%X(this%node_offset+1:this%node_offset+num_vertices), &
                                                  this%Y(this%node_offset+1:this%node_offset+num_vertices), &
                                                  this%Z(this%node_offset+1:this%node_offset+num_vertices))

            this%Connectivities(this%node_offset+1:this%node_offset+num_vertices) = &
                                (/(i, i=this%node_offset, this%node_offset+num_vertices-1)/)
        endif

        do i=1, num_fields+num_field_generators
            num_components = this%FieldValues(i)%get_num_components()
            FieldValue => this%FieldValues(i)%get_value()
            call subcell_accessor%get_field(i, FieldValue(1:num_components,this%node_offset+1:this%node_offset+num_vertices))
        enddo

        this%node_offset = this%node_offset + num_vertices
        this%cell_offset = this%cell_offset + 1

        do i=1, num_cell_vectors
            CellValue => this%CellValues(i)%get_value()
            call subcell_accessor%get_cell_vector(i, CellValue(this%cell_offset:this%cell_offset))
        enddo

        this%Offset(this%cell_offset) = this%node_offset
        this%CellTypes(this%cell_offset) = topology_to_vtk_celltype(subcell_accessor%get_cell_type(), num_dims)

    end subroutine vtk_output_handler_append_cell


    subroutine vtk_output_handler_write(this)
    !-----------------------------------------------------------------
    !< Fill global arrays and Write VTU and PVTU files
    !-----------------------------------------------------------------
        class(vtk_output_handler_t), intent(inout) :: this
        character(len=:), allocatable              :: path
        class(serial_fe_space_t),        pointer   :: fe_space
        type(environment_t),             pointer   :: environment
        integer(ip)                                :: E_IO, i
        integer(ip)                                :: me, np
    !-----------------------------------------------------------------
        fe_space    => this%get_fe_space()
        assert(associated(fe_space))
        environment => fe_space%get_environment()
        assert(associated(environment))
        !call environment%info(me, np)
        me = environment%get_l1_rank()
        np = environment%get_l1_size()

        if( environment%am_i_l1_task()) then

            assert(allocated(this%Path) .and. allocated(this%FilePrefix))
            if(.not. allocated(this%FieldValues)) allocate(this%FieldValues(this%get_num_fields()+this%get_num_field_generators()))
            if(.not. allocated(this%CellValues)) allocate(this%CellValues(this%get_num_cell_vectors()))

            call this%fill_data(update_mesh = (.not. this%StaticGrid .or. this%num_steps <= 1))

            if(this%num_steps > 0) then
                path     = get_vtk_output_path(trim(adjustl(this%Path)), this%Times(this%num_steps))
            else
                path     = get_vtk_output_path(trim(adjustl(this%Path)), vtk_default_step_value)
            endif

            if( me == vtk_default_root_task) then
                E_IO     = create_directory(path, me)
                check(E_IO == 0)
            endif

            call environment%l1_barrier()

            ! Write VTU
            call this%write_vtu(path, this%FilePrefix, me)
    
            ! Write PVTU and PVD only in root task
            if( me == vtk_default_root_task) then
                call this%write_pvtu(path, this%FilePrefix, np)
                call this%write_pvd(this%Path, this%FilePrefix)
            endif

        endif
    end subroutine vtk_output_handler_write


    subroutine vtk_output_handler_write_vtu(this, dir_path, prefix, task_id)
    !-----------------------------------------------------------------
    !< Write the vtu file 
    !-----------------------------------------------------------------
        class(vtk_output_handler_t),     intent(in) :: this
        character(len=*),                intent(in) :: dir_path
        character(len=*),                intent(in) :: prefix
        integer(ip),                     intent(in) :: task_id
        character(len=:), allocatable               :: filename
        type(output_handler_fe_field_t),    pointer :: field
        type(output_handler_field_generator_info_t), pointer :: field_generator
        type(output_handler_cell_vector_t), pointer :: cell_vector
        integer(ip)                                 :: num_components
        integer(ip)                                 :: file_id
        real(rp), pointer                           :: FieldValue(:,:)
        real(rp), pointer                           :: CellValue(:)
        integer(ip)                                 :: E_IO, i
    !-----------------------------------------------------------------
        E_IO = 0
        filename = get_vtk_filename(prefix, task_id)
        ! Write VTU
        E_IO = VTK_INI_XML(output_format = this%vtk_format, &
                   filename = dir_path//'/'//filename,      &
                   mesh_topology = 'UnstructuredGrid',      &
                   cf=file_id)
        assert(E_IO == 0)
        E_IO = VTK_GEO_XML(NN = this%get_num_nodes(), &
                           NC = this%get_num_cells(), &
                           X  = this%X,                  &
                           Y  = this%Y,                  &
                           Z  = this%Z,                  &
                           cf = file_id)
        assert(E_IO == 0)
        E_IO = VTK_CON_XML(NC        = this%get_num_cells(), &
                           connect   = this%Connectivities,     &
                           offset    = this%Offset,             &
                           cell_type = this%CellTypes,          &
                           cf        = file_id)
        assert(E_IO == 0)

        E_IO = VTK_DAT_XML(var_location='Node',var_block_action='OPEN', cf=file_id)
        assert(E_IO == 0)
        do i=1, this%get_num_fields()
            field => this%get_fe_field(i)
            FieldValue => this%FieldValues(i)%get_value()
            num_components = size(FieldValue,1)
            E_IO = VTK_VAR_XML(NC_NN=this%get_num_nodes(), N_COL=num_components, varname=field%get_name(), var=FieldValue, cf=file_id)
            assert(E_IO == 0)
        enddo
        do i=1, this%get_num_field_generators()
            field_generator => this%get_field_generator(i)
            FieldValue => this%FieldValues(this%get_num_fields()+i)%get_value()
            num_components = size(FieldValue,1)
            E_IO = VTK_VAR_XML(NC_NN=this%get_num_nodes(), N_COL=num_components, varname=field_generator%get_name(), var=FieldValue, cf=file_id)
            assert(E_IO == 0)
        enddo
        E_IO = VTK_DAT_XML(var_location='Node', var_block_action='CLOSE', cf=file_id)
        assert(E_IO == 0)

        E_IO = VTK_DAT_XML(var_location='Cell',var_block_action='OPEN', cf=file_id)
        assert(E_IO == 0)
        do i=1, this%get_num_cell_vectors()
            cell_vector => this%get_cell_vector(i)
            CellValue => this%CellValues(i)%get_value()
            E_IO = VTK_VAR_XML(NC_NN=this%get_num_cells(), varname=cell_vector%get_name(), var=CellValue, cf=file_id)
            assert(E_IO == 0)
        enddo
        E_IO = VTK_DAT_XML(var_location='Cell', var_block_action='CLOSE', cf=file_id)
        assert(E_IO == 0)

        E_IO = VTK_GEO_XML(cf=file_id)
        assert(E_IO == 0)
        E_IO = VTK_END_XML(cf=file_id)
        assert(E_IO == 0)
    end subroutine vtk_output_handler_write_vtu


    subroutine vtk_output_handler_write_pvtu(this, dir_path, prefix, num_parts)
    !-----------------------------------------------------------------
    !< Write the pvtu file containing the number of parts
    !< (only root processor)
    !-----------------------------------------------------------------
        class(vtk_output_handler_t),    intent(in)  :: this
        character(len=*),               intent(in)  :: dir_path
        character(len=*),               intent(in)  :: prefix
        integer(ip),                    intent(in)  :: num_parts
        character(len=:), allocatable               :: path
        character(len=:), allocatable               :: filename
        class(serial_fe_space_t),           pointer :: fe_space
        type(environment_t),                pointer :: environment
        type(output_handler_fe_field_t),    pointer :: field
        type(output_handler_field_generator_info_t), pointer :: field_generator
        type(output_handler_cell_vector_t), pointer :: cell_vector
        integer(ip)                                 :: file_id
        integer(ip)                                 :: E_IO
        integer(ip)                                 :: me, np, i
    !-----------------------------------------------------------------
        E_IO = 0
        filename = trim(adjustl(get_pvtu_filename(prefix)))
        path = trim(adjustl(dir_path))

        E_IO = PVTK_INI_XML(filename      = path//'/'//filename, &
                            mesh_topology = 'PUnstructuredGrid', &
                            tp            = 'Float64',           &
                            cf            = file_id)
        assert(E_IO == 0)
        do i=0, num_parts-1
            E_IO = PVTK_GEO_XML(source=trim(adjustl(get_vtk_filename(prefix, i))), cf=file_id)
            assert(E_IO == 0)
        enddo

        E_IO = PVTK_DAT_XML(var_location = 'Node', var_block_action = 'OPEN', cf=file_id)
        assert(E_IO == 0)
        ! Write point data fields
        do i=1, this%get_num_fields()
            field => this%get_fe_field(i)
            E_IO = PVTK_VAR_XML(varname = trim(adjustl(field%get_name())),             &
                                tp      = 'Float64',                                   &
                                Nc      = this%FieldValues(i)%get_num_components(), &
                                cf      = file_id )
            assert(E_IO == 0)
        enddo
        ! Write point data fields
        do i=1, this%get_num_field_generators()
            field_generator => this%get_field_generator(i)
            E_IO = PVTK_VAR_XML(varname = trim(adjustl(field_generator%get_name())),             &
                                tp      = 'Float64',                                   &
                                Nc      = this%FieldValues(i+this%get_num_fields())%get_num_components(), &
                                cf      = file_id )
            assert(E_IO == 0)
        enddo
        
        E_IO = PVTK_DAT_XML(var_location = 'Node', var_block_action = 'CLOSE', cf=file_id)
        assert(E_IO == 0)

        E_IO = PVTK_DAT_XML(var_location = 'Cell', var_block_action = 'OPEN', cf=file_id)
        assert(E_IO == 0)
        ! Write point data fields
        do i=1, this%get_num_cell_vectors()
            cell_vector => this%get_cell_vector(i)
            E_IO = PVTK_VAR_XML(varname = trim(adjustl(cell_vector%get_name())),       &
                                tp      = 'Float64',                                   &
                                Nc      = 1,                                           &
                                cf      = file_id )
            assert(E_IO == 0)
        enddo
        E_IO = PVTK_DAT_XML(var_location = 'Cell', var_block_action = 'CLOSE', cf=file_id)
        assert(E_IO == 0)

        E_IO = PVTK_END_XML(cf = file_id)
        assert(E_IO == 0)

    end subroutine vtk_output_handler_write_pvtu


    subroutine vtk_output_handler_write_pvd(this, dir_path, prefix)
    !-----------------------------------------------------------------
    !< Write the PVD file referencing several PVTU files in a timeline
    !< (only root processor)
    !-----------------------------------------------------------------
        class(vtk_output_handler_t), intent(inout) :: this
        character(len=*),            intent(in)    :: dir_path
        character(len=*),            intent(in)    :: prefix
        character(len=:), allocatable              :: pvtu_path
        character(len=:), allocatable              :: pvtu_filename
        integer(ip)                                :: file_id
        integer(ip)                                :: step
        integer(ip)                                :: E_IO
    !-----------------------------------------------------------------
        E_IO = 0

        E_IO = PVD_INI_XML(filename=trim(adjustl(dir_path))//'/'//trim(adjustl(get_pvd_filename(prefix))), cf=file_id)
        assert(E_IO==0)
        if(allocated(this%Times)) then
            ! Transient simulation
            assert(size(this%Times,1) >= this%num_steps)
            do step=1, this%num_steps
                pvtu_path     = trim(adjustl(get_vtk_output_directory_name(this%Times(step))))
                pvtu_filename = trim(adjustl(get_pvtu_filename(prefix)))
                E_IO = PVD_DAT_XML(filename=pvtu_path//'/'//pvtu_filename, timestep=this%Times(step), cf=file_id)
                assert(E_IO==0)
            enddo
        else
            ! Static simulation
            pvtu_path     = trim(adjustl(get_vtk_output_directory_name(vtk_default_step_value)))
            pvtu_filename = trim(adjustl(get_pvtu_filename(prefix)))
            E_IO = PVD_DAT_XML(filename=pvtu_path//'/'//pvtu_filename, timestep=vtk_default_step_value, cf=file_id)
            assert(E_IO==0)
        endif
        E_IO = PVD_END_XML(cf=file_id)
        assert(E_IO==0)

    end subroutine vtk_output_handler_write_pvd


    subroutine vtk_output_handler_close_body(this)
    !-----------------------------------------------------------------
    !< Close procedure
    !-----------------------------------------------------------------
        class(vtk_output_handler_t), intent(inout) :: this
    !-----------------------------------------------------------------
        this%num_steps = 0
        if(allocated(this%Times)) call memfree(this%Times, __FILE__, __LINE__)
    end subroutine vtk_output_handler_close_body


end module vtk_output_handler_names
