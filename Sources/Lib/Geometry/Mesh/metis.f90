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
module metis_names
  use types_names
  use iso_c_binding
  implicit none

  !------------------------------------------------------------------!
  ! An iso_c_bindings based Fortran2003 interface to metis (V5.1.0)  !
  !------------------------------------------------------------------!

!!$/* The maximum length of the options[] array */
!!$#define METIS_NOPTIONS          40
     integer(c_int), parameter ::  METIS_NOPTIONS    =  40
 

!!$/*------------------------------------------------------------------------
!!$* Enum type definitions 
!!$*-------------------------------------------------------------------------*/
!!$/*! Return codes */
!!$typedef enum {
!!$  METIS_OK              = 1,    /*!< Returned normally */
!!$  METIS_ERROR_INPUT     = -2,   /*!< Returned due to erroneous inputs and/or options */
!!$  METIS_ERROR_MEMORY    = -3,   /*!< Returned due to insufficient memory */
!!$  METIS_ERROR           = -4    /*!< Some other errors */
!!$} rstatus_et; 
!!$
     integer(c_int), parameter ::  METIS_OK    =  1
     integer(c_int), parameter ::  METIS_ERROR_INPUT  = -2
     integer(c_int), parameter ::  METIS_ERROR_MEMORY = -3
     integer(c_int), parameter ::  METIS_ERROR = -4

!!$
!!$/*! Operation type codes */
!!$typedef enum {
!!$  METIS_OP_PMETIS,       
!!$  METIS_OP_KMETIS,
!!$  METIS_OP_OMETIS
!!$} moptype_et;
!!$
     integer(c_int), parameter :: METIS_OP_PMETIS = 0       
     integer(c_int), parameter :: METIS_OP_KMETIS = 1 
     integer(c_int), parameter :: METIS_OP_OMETIS = 2
!!$
!!$/*! Options codes (i.e., options[]) */
!!$typedef enum {
!!$  METIS_OPTION_PTYPE,
!!$  METIS_OPTION_OBJTYPE,
!!$  METIS_OPTION_CTYPE,
!!$  METIS_OPTION_IPTYPE,
!!$  METIS_OPTION_RTYPE,
!!$  METIS_OPTION_DBGLVL,
!!$  METIS_OPTION_NITER,
!!$  METIS_OPTION_NCUTS,
!!$  METIS_OPTION_SEED,
!!$  METIS_OPTION_NO2HOP,
!!$  METIS_OPTION_MINCONN,
!!$  METIS_OPTION_CONTIG,
!!$  METIS_OPTION_COMPRESS,
!!$  METIS_OPTION_CCORDER,
!!$  METIS_OPTION_PFACTOR,
!!$  METIS_OPTION_NSEPS,
!!$  METIS_OPTION_UFACTOR,
!!$  METIS_OPTION_NUMBERING,
!!$
!!$  /* Used for command-line parameter purposes */
!!$  METIS_OPTION_HELP,
!!$  METIS_OPTION_TPWGTS,
!!$  METIS_OPTION_NCOMMON,
!!$  METIS_OPTION_NOOUTPUT,
!!$  METIS_OPTION_BALANCE,
!!$  METIS_OPTION_GTYPE,
!!$  METIS_OPTION_UBVEC
!!$} moptions_et;
!!$
     integer(c_int), parameter :: METIS_OPTION_PTYPE = 0 
     integer(c_int), parameter :: METIS_OPTION_OBJTYPE = 1
     integer(c_int), parameter :: METIS_OPTION_CTYPE = 2
     integer(c_int), parameter :: METIS_OPTION_IPTYPE = 3
     integer(c_int), parameter :: METIS_OPTION_RTYPE = 4
     integer(c_int), parameter :: METIS_OPTION_DBGLVL = 5
     integer(c_int), parameter :: METIS_OPTION_NITER = 6
     integer(c_int), parameter :: METIS_OPTION_NCUTS = 7
     integer(c_int), parameter :: METIS_OPTION_SEED = 8
     integer(c_int), parameter :: METIS_OPTION_NO2HOP = 9
     integer(c_int), parameter :: METIS_OPTION_MINCONN = 10
     integer(c_int), parameter :: METIS_OPTION_CONTIG = 11
     integer(c_int), parameter :: METIS_OPTION_COMPRESS = 12
     integer(c_int), parameter :: METIS_OPTION_CCORDER = 13
     integer(c_int), parameter :: METIS_OPTION_PFACTOR = 14
     integer(c_int), parameter :: METIS_OPTION_NSEPS = 15
     integer(c_int), parameter :: METIS_OPTION_UFACTOR = 16
     integer(c_int), parameter :: METIS_OPTION_NUMBERING = 17
     
     integer(c_int), parameter :: METIS_OPTION_HELP = 18
     integer(c_int), parameter :: METIS_OPTION_TPWGTS = 19
     integer(c_int), parameter :: METIS_OPTION_NCOMMON = 20
     integer(c_int), parameter :: METIS_OPTION_NOOUTPUT = 21
     integer(c_int), parameter :: METIS_OPTION_BALANCE = 22
     integer(c_int), parameter :: METIS_OPTION_GTYPE = 23
     integer(c_int), parameter :: METIS_OPTION_UBVEC = 24

!!$
!!$/*! Partitioning Schemes */
!!$typedef enum {
!!$  METIS_PTYPE_RB, 
!!$  METIS_PTYPE_KWAY                
!!$} mptype_et;
     
     integer(c_int), parameter :: METIS_PTYPE_RB = 0
     integer(c_int), parameter :: METIS_PTYPE_KWAY = 1

!!$
!!$/*! Graph types for meshes */
!!$typedef enum {
!!$  METIS_GTYPE_DUAL,
!!$  METIS_GTYPE_NODAL               
!!$} mgtype_et;
!!$

     integer(c_int), parameter :: METIS_GTYPE_DUAL  = 0
     integer(c_int), parameter :: METIS_GTYPE_NODAL = 1
     

!!$/*! Coarsening Schemes */
!!$typedef enum {
!!$  METIS_CTYPE_RM,
!!$  METIS_CTYPE_SHEM
!!$} mctype_et;
!!$

     integer(c_int), parameter :: METIS_CTYPE_RM = 0
     integer(c_int), parameter :: METIS_CTYPE_SHEM = 1

!!$/*! Initial partitioning schemes */
!!$typedef enum {
!!$  METIS_IPTYPE_GROW,
!!$  METIS_IPTYPE_RANDOM,
!!$  METIS_IPTYPE_EDGE,
!!$  METIS_IPTYPE_NODE,
!!$  METIS_IPTYPE_METISRB
!!$} miptype_et;
!!$
     integer(c_int), parameter :: METIS_IPTYPE_GROW = 0
     integer(c_int), parameter :: METIS_IPTYPE_RANDOM = 1
     integer(c_int), parameter :: METIS_IPTYPE_EDGE = 2
     integer(c_int), parameter :: METIS_IPTYPE_NODE = 3
     integer(c_int), parameter :: METIS_IPTYPE_METISRB = 4

!!$
!!$/*! Refinement schemes */
!!$typedef enum {
!!$  METIS_RTYPE_FM,
!!$  METIS_RTYPE_GREEDY,
!!$  METIS_RTYPE_SEP2SIDED,
!!$  METIS_RTYPE_SEP1SIDED
!!$} mrtype_et;
!!$
     
     integer(c_int), parameter :: METIS_RTYPE_FM = 0
     integer(c_int), parameter :: METIS_RTYPE_GREEDY = 1
     integer(c_int), parameter :: METIS_RTYPE_SEP2SIDED = 2
     integer(c_int), parameter :: METIS_RTYPE_SEP1SIDED = 3 
     
!!$
!!$/*! Debug Levels */
!!$typedef enum {
!!$  METIS_DBG_INFO       = 1,       /*!< Shows various diagnostic messages */
!!$  METIS_DBG_TIME       = 2,       /*!< Perform timing analysis */
!!$  METIS_DBG_COARSEN    = 4,   /*!< Show the coarsening progress */
!!$  METIS_DBG_REFINE     = 8,   /*!< Show the refinement progress */
!!$  METIS_DBG_IPART      = 16,    /*!< Show info on initial partitioning */
!!$  METIS_DBG_MOVEINFO   = 32,    /*!< Show info on vertex moves during refinement */
!!$  METIS_DBG_SEPINFO    = 64,    /*!< Show info on vertex moves during sep refinement */
!!$  METIS_DBG_CONNINFO   = 128,     /*!< Show info on minimization of subdomain connectivity */
!!$  METIS_DBG_CONTIGINFO = 256,     /*!< Show info on elimination of connected components */ 
!!$  METIS_DBG_MEMORY     = 2048,    /*!< Show info related to wspace allocation */
!!$} mdbglvl_et;
!!$
  integer(c_int), parameter :: METIS_DBG_INFO       = 1    ! /*!< Shows various diagnostic messages */
  integer(c_int), parameter :: METIS_DBG_TIME       = 2    ! /*!< Perform timing analysis */
  integer(c_int), parameter :: METIS_DBG_COARSEN    = 4    ! /*!< Show the coarsening progress */
  integer(c_int), parameter :: METIS_DBG_REFINE     = 8    ! /*!< Show the refinement progress */
  integer(c_int), parameter :: METIS_DBG_IPART      = 16   ! /*!< Show info on initial partitioning */
  integer(c_int), parameter :: METIS_DBG_MOVEINFO   = 32   ! /*!< Show info on vertex moves during refinement */
  integer(c_int), parameter :: METIS_DBG_SEPINFO    = 64   ! /*!< Show info on vertex moves during sep refinement */
  integer(c_int), parameter :: METIS_DBG_CONNINFO   = 128  ! /*!< Show info on minimization of subdomain connectivity */
  integer(c_int), parameter :: METIS_DBG_CONTIGINFO = 256  ! /*!< Show info on elimination of connected components */ 
  integer(c_int), parameter :: METIS_DBG_MEMORY     = 2048 ! /*!< Show info related to wspace allocation */

!!$
!!$/* Types of objectives */
!!$typedef enum {
!!$  METIS_OBJTYPE_CUT,
!!$  METIS_OBJTYPE_VOL,
!!$  METIS_OBJTYPE_NODE
!!$} mobjtype_et;

  integer(c_int), parameter :: METIS_OBJTYPE_CUT =  0 
  integer(c_int), parameter :: METIS_OBJTYPE_VOL =  1
  integer(c_int), parameter :: METIS_OBJTYPE_NODE = 2 


#ifdef ENABLE_METIS
#ifndef METIS_LONG_INTEGERS

  interface
     function metis_nodend(nvtxs,xadj,adjncy,vwgt,options,perm,iperm) & 
        & bind(c,NAME='METIS_NodeND')
       use iso_c_binding
       implicit none
       integer(c_int) :: metis_nodend
       type(c_ptr), value :: nvtxs
       type(c_ptr), value :: xadj, adjncy, vwgt, options, perm, iperm
     end function metis_nodend
     function metis_partgraphkway(nvtxs,ncon,xadj,adjncy,vwgt,vsize,adjwgt,nparts,tptwgts,ubvec,options,objval,part) &
        & bind(c,NAME='METIS_PartGraphKway')
       use iso_c_binding
       implicit none
       integer(c_int) :: metis_partgraphkway
       type(c_ptr), value :: nvtxs, ncon, nparts, objval, part
       type(c_ptr), value :: xadj, adjncy, vwgt, vsize, adjwgt, options
       type(c_ptr), value :: tptwgts, ubvec 
       ! WARNING: metis.h, #define REALTYPEWIDTH 64 REQUIRED !!!
     end function metis_partgraphkway
     function metis_partgraphrecursive(nvtxs,ncon,xadj,adjncy,vwgt,vsize,adjwgt,nparts,tptwgts,ubvec,options,objval,part) &
        & bind(c,NAME='METIS_PartGraphRecursive')
       use iso_c_binding
       implicit none
       integer(c_int) :: metis_partgraphrecursive
       type(c_ptr), value :: nvtxs, ncon, nparts, objval, part
       type(c_ptr), value :: xadj, adjncy, vwgt, vsize, adjwgt, options
       type(c_ptr), value :: tptwgts, ubvec 
       ! WARNING: metis.h, #define REALTYPEWIDTH 64 REQUIRED !!!
     end function metis_partgraphrecursive
     
     function metis_setdefaultoptions(options) bind(c,NAME='METIS_SetDefaultOptions')
       use iso_c_binding
       implicit none
       integer(c_int)      :: metis_setdefaultoptions
       type(c_ptr), value  :: options
     end function metis_setdefaultoptions
  end interface

#else
  ! TODO (done by A.F.M. in his private 64-bit copy of Fempar)
#endif

#else
contains 
  ! Public by default
  subroutine enable_metis_error_message
    implicit none
    write (0,*) 'Error: Fempar was not compiled with -DENABLE_METIS'
    write (0,*) "Error: You must activate this cpp macro in order to use Fempar's interface to Metis(5)"
    call runend
  end subroutine enable_metis_error_message
#endif 

end module metis_names
