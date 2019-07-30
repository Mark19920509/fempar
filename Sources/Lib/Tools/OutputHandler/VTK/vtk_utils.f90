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
!* Author: Víctor Sande Veiga
! Date: 2016-11-29
! Version: 0.0.1
! Category: IO
!
!--------------------------------------------------------------------- 
!### Public procedures used by [[vtk_output_handler_t(type)]] type
!
! Contains the following public entities:
! [[vtk_utils_names(module)]]
!--------------------------------------------------------------------- 
module vtk_utils_names
!---------------------------------------------------------------------
!* Author: Víctor Sande Veiga
! Date: 2016-11-29
! Version: 0.0.1
! Category: IO
!
!--------------------------------------------------------------------- 
!### Public procedures used by [[vtk_output_handler_t(type)]] type
! 
! Contains the following public procedures:
! [[create_directory(function)]], 
! [[topology_to_vtk_celltype(function)]], 
! [[get_vtk_output_directory_name(function)]], 
! [[get_vtk_output_path(function)]], 
! [[get_pvd_output_path(function)]], 
! [[get_vtk_filename(function)]], 
! [[get_pvtu_filename(function)]], 
! [[get_pvd_filename(function)]]
!--------------------------------------------------------------------- 

USE types_names
USE IR_Precision,       only: str, I1P
USE iso_fortran_env,    only: error_unit
USE iso_c_binding,      only: c_int, c_null_char
USE reference_fe_names, only: topology_hex, topology_tet
USE vtk_parameters_names

implicit none
#include "debug.i90"
private

    interface
        function mkdir_recursive(path) bind(c,name="mkdir_recursive")
            use iso_c_binding
            integer(kind=c_int) :: mkdir_recursive
            character(kind=c_char,len=1), intent(IN) :: path(*)
        end function mkdir_recursive
    end interface

    ! File extensions and time prefix
    character(len=5), parameter :: time_prefix = 'time_'
    character(len=4), parameter :: vtk_ext     = '.vtu'
    character(len=4), parameter :: pvd_ext     = '.pvd'
    character(len=5), parameter :: pvtu_ext    = '.pvtu'

public :: create_directory
public :: topology_to_vtk_celltype
public :: nnodes_to_vtk_celltype
public :: get_vtk_output_directory_name
public :: get_vtk_output_path
public :: get_pvd_output_path
public :: get_vtk_filename
public :: get_pvtu_filename
public :: get_pvd_filename

contains

    function create_directory(path, task_id) result(error)
    !-----------------------------------------------------------------
    !< The root process create a hierarchy of directories
    !-----------------------------------------------------------------
        character(len=*),            intent(in)    :: path
        integer(ip),                 intent(in)    :: task_id
        integer(kind=c_int)                        :: error
    !-----------------------------------------------------------------
        error = 0

        error = mkdir_recursive(path//C_NULL_CHAR)
        check ( error == 0 ) 
    end function create_directory


    function topology_to_vtk_celltype(topology, dimension) result(cell_type)
    !-----------------------------------------------------------------
    !< Translate the topology type of the reference_fe_geo into VTK cell type
    !-----------------------------------------------------------------
        character(len=*),            intent(in)    :: topology
        integer(ip),                 intent(in)    :: dimension
        integer(I1P)                               :: cell_type
    !-----------------------------------------------------------------
        if(topology == topology_hex) then 
            if(dimension == 2) then
                cell_type = vtk_pixel
            elseif(dimension == 3) then
                cell_type = vtk_voxel
            endif
        elseif(topology == topology_tet) then
            if(dimension == 2) then
                cell_type = vtk_triangle
            elseif(dimension == 3) then
                cell_type = vtk_tetra
            endif
        else
            write(error_unit,*) 'Topology_to_vtk_CellType: Topology not supported ('//trim(adjustl(topology))//')'
            check(.false.)    
        endif
    end function topology_to_vtk_celltype


    function nnodes_to_vtk_celltype(nnodes, dimension) result(cell_type)
    !-----------------------------------------------------------------
    !< Translate the nnodes into VTK cell type
    !-----------------------------------------------------------------
        integer(ip),                 intent(in)    :: nnodes
        integer(ip),                 intent(in)    :: dimension
        integer(I1P)                               :: cell_type
    !-----------------------------------------------------------------

        if(dimension == 2) then
            if(nnodes == 3) then 
                cell_type = vtk_triangle
            elseif(nnodes == 4) then
                cell_type = vtk_pixel
            else
                write(error_unit,*) 'nnodes_to_vtk_CellType: Nnodes not supported: ', nnodes
                check(.false.)    
            endif
        elseif(dimension == 3) then
            if(nnodes == 4) then 
                cell_type = vtk_tetra
            elseif(nnodes == 8) then
                cell_type = vtk_voxel
            else
                write(error_unit,*) 'nnodes_to_vtk_CellType: Nnodes not supported: ', nnodes
                check(.false.)    
            endif
        else
            write(error_unit,*) 'nnodes_to_vtk_CellType: Dimension not supported: ', dimension
            check(.false.)    
        endif
    end function nnodes_to_vtk_celltype


    function get_vtk_output_directory_name(time_step) result(path)
    !-----------------------------------------------------------------
    !< Build time output dir name for the vtk files in each timestep
    !-----------------------------------------------------------------
        real(rp),          intent(in)    :: time_step
        character(len=:), allocatable    :: path
    !-----------------------------------------------------------------
        path = time_prefix//trim(adjustl(str(no_sign=.true., n=time_step)))
    end function get_vtk_output_directory_name


    function get_vtk_output_path(dir_path, time_step) result(path)
    !-----------------------------------------------------------------
    !< Build time output dir path for the vtk files in each timestep
    !-----------------------------------------------------------------
        character(len=*),  intent(in)    :: dir_path
        real(rp),          intent(in)    :: time_step
        character(len=:), allocatable    :: path
    !-----------------------------------------------------------------
        assert(len_trim(dir_path)>0)
        path = trim(adjustl(dir_path))//'/'//get_vtk_output_directory_name(time_step)
    end function get_vtk_output_path


    function get_pvd_output_path(dir_path, time_step) result(path)
    !-----------------------------------------------------------------
    !< Build output dir path for the PVD files
    !-----------------------------------------------------------------
        character(len=*), intent(in)    :: dir_path
        real(RP),         intent(in)    :: time_step
        character(len=:), allocatable   :: path
    !-----------------------------------------------------------------
        assert(len_trim(dir_path)>0)
        path = time_prefix//trim(adjustl(str(no_sign=.true., n=time_step)))
    end function get_pvd_output_path


    function get_vtk_filename(prefix, part) result(filename)
    !-----------------------------------------------------------------
    !< Build VTK filename
    !-----------------------------------------------------------------
        character(len=*),  intent(in) :: prefix
        integer(ip),       intent(in) :: part
        character(len=:), allocatable :: filename
    !-----------------------------------------------------------------
        assert(len_trim(prefix)>0)
        filename = trim(adjustl(prefix))//'_'//trim(adjustl(str(no_sign=.true., n=part)))//vtk_ext
    end function get_vtk_filename


    function get_pvtu_filename(prefix) result(filename)
    !-----------------------------------------------------------------
    !< Build pvtu filename
    !-----------------------------------------------------------------
        character(len=*),   intent(in) :: prefix
        character(len=:), allocatable  :: filename
    !-----------------------------------------------------------------
        assert(len_trim(prefix)>0)
        filename = trim(adjustl(prefix))//pvtu_ext
    end function get_pvtu_filename


    function get_pvd_filename(prefix) result(filename)
    !-----------------------------------------------------------------
    !< Build pvtu filename
    !-----------------------------------------------------------------
        character(len=*),   intent(in) :: prefix
        character(len=:), allocatable  :: filename
    !-----------------------------------------------------------------
        assert(len_trim(prefix)>0)
        filename = trim(adjustl(prefix))//pvd_ext
    end function get_pvd_filename

end module vtk_utils_names

