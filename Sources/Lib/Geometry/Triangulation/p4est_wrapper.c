/* Module file taken "AS-IS" and adapted to FEMPAR needs from p4est_wrapper.c 
   https://github.com/cburstedde/hopest 4feed803f0c61564203a7bc3f2ca1a6adb63d3cd */

/*
  This file is part of hopest.
  hopest is a Fortran/C library and application for high-order mesh
  preprocessing and interfacing to the p4est apaptive mesh library.

  Copyright (C) 2014 by the developers.

  hopest is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  hopest is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with hopest; if not, write to the Free Software Foundation, Inc.,
  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/ 

#ifdef ENABLE_P4EST

#ifdef SC_ENABLE_MPI
#include <mpi.h>
#endif

#include <sc.h>
#include <p4est.h>
#include <p4est_extended.h>
#include <p4est_mesh.h>
#include <p4est_bits.h>
#include <p4est_base.h>
#include <p4est_communication.h>
#include "p4est_wrapper.h"
#include <p8est.h>
#include <p8est_extended.h>
#include <p8est_mesh.h>
#include <p8est_bits.h>
#include <p8est_communication.h>
#include <p8est_iterate.h>
#ifndef SC_ENABLE_MPI
  static int sc_mpi_initialized   = 0;
#else
  static int sc_p4est_initialized = 0;
#endif

// Init p4est environment 
// Gets a Fortran communicator and transform it into a C communicator
// http://stackoverflow.com/questions/42530620/how-to-pass-mpi-communicator-handle-from-fortran-to-c-using-iso-c-binding
#ifdef SC_ENABLE_MPI
void F90_p4est_init(const MPI_Fint Fcomm, const int SC_LOG_LEVEL)
#else
void F90_p4est_init(const int dummy, const int SC_LOG_LEVEL)
#endif
{
#ifndef SC_ENABLE_MPI
  /* Initialize MPI; see sc_mpi.h.
   * If configure --enable-mpi is given these are true MPI calls.
   * Else these are dummy functions that simulate a single-processor run. */
  int mpiret;
  
  // Assume that we have a dummy main program called p4est_init_environment
  int argc      = 1;
  char ** argv  = (char *[]) {"p4est_init_environment"};
  
  if (!sc_mpi_initialized)
  {
    mpiret = sc_MPI_Init (&argc, &argv);
    SC_CHECK_MPI (mpiret==1);
    /* These 2x functions are optional.  If called they store the MPI rank as a
     * static variable so subsequent global p4est log messages are only issued
     * from processor zero.  Here we turn off most of the logging; see sc.h. */
    sc_init (sc_MPI_COMM_WORLD, 1, 1, NULL, SC_LOG_LEVEL);
    p4est_init (NULL, SC_LOG_LEVEL);  
    sc_mpi_initialized = 1;
  }
#else
  /* These 2x functions are optional.  If called they store the MPI rank as a
   * static variable so subsequent global p4est log messages are only issued
   * from processor zero.  Here we turn off most of the logging; see sc.h. */
  if (!sc_p4est_initialized) 
  {
    MPI_Comm Ccomm;
    Ccomm = MPI_Comm_f2c(Fcomm); // Convert Fortran->C communicator
    sc_init (Ccomm, 1, 1, NULL, SC_LOG_LEVEL);
    p4est_init (NULL, SC_LOG_LEVEL);
    sc_p4est_initialized = 1;
  }
#endif  
}

// Finalize p4est_environment
void F90_p4est_finalize()
{
#ifndef SC_ENABLE_MPI
    int mpiret;
    if ( sc_mpi_initialized )
    {    
        sc_finalize ();   
        mpiret = sc_MPI_Finalize ();
        SC_CHECK_MPI (mpiret);    
        sc_mpi_initialized = 0;
    } 
#else  
    if ( sc_p4est_initialized )
    {
      sc_finalize ();
      sc_p4est_initialized = 0;
    }
#endif    
}

void F90_p4est_connectivity_new_unitsquare(p4est_connectivity_t **p4est_connectivity)
{
  F90_p4est_connectivity_destroy(p4est_connectivity);
  *p4est_connectivity = p4est_connectivity_new_unitsquare();
  P4EST_ASSERT (p4est_connectivity_is_valid (*p4est_connectivity));
}


void F90_p8est_connectivity_new_unitcube(p8est_connectivity_t **p8est_connectivity)
{
  F90_p8est_connectivity_destroy(p8est_connectivity);
  *p8est_connectivity = p8est_connectivity_new_unitcube();
  P4EST_ASSERT (p8est_connectivity_is_valid (*p8est_connectivity));
}

/* set_bounding_box_limits:
   p4est_connectivity_t, INOUT :: p4est_conn           = already created as new_unit_square or new_unit_cube
   double(6)           , IN    :: bounding_box_limits  = user defined bouding box limits sorted as
                                                        [ x_min, y_min, z_min, x_max, y_max, z_max ]
                                                        (length = 2 * NUM_DIMS = 6)
 * The vertices in a p4est/p8est quadrant are numbered according to the 'z filling curve', thus the minumum
   and the maximum correspon to the binary figure at the 'idim' position. Where, min = 0 and max = 1.
   See following table:
    0 ->  0  0  0 :  z_min | y_min | x_min
    1 ->  0  0  1 :  z_min | y_min | x_max
    2 ->  0  1  0 :  z_min | y_max | x_min
    3 ->  0  1  1 :  z_min | y_max | x_max
    4 ->  1  0  0 :  z_max | y_min | x_min
    5 ->  1  0  1 :  z_max | y_min | x_max
    6 ->  1  1  0 :  z_max | y_max | x_min
    7 ->  1  1  1 :  z_max | y_max | x_max

  * bound = ( ivertex >> idim ) % 2 : must be 0 or 1, ie, min or max
*/

void F90_p4est_connectivity_set_bounding_box_limits ( p4est_connectivity_t ** p4est_conn,
                                                      const double          * bounding_box_limits )
{
    int bound;
    int ivertex;
    int idim;
    const int num_dims = 3;
    const int bin_base = 2;
    
    for ( ivertex = 0; ivertex < (*p4est_conn)->num_vertices; ivertex ++ )
    {
        for ( idim = 0; idim < num_dims; idim ++ )
        {
            bound = ( ivertex >> idim ) % bin_base ;
            (*p4est_conn)->vertices [ ivertex * num_dims + idim ] = bounding_box_limits[ bound * num_dims + idim ];
        }
    }
    
}


#ifdef SC_ENABLE_MPI
void F90_p4est_new ( const MPI_Fint Fcomm, 
                     p4est_connectivity_t *conn,
                     p4est_t              **p4est_out)
#else
void F90_p4est_new ( const int dummy_comm,
                     p4est_connectivity_t *conn,
                     p4est_t              **p4est_out)
#endif
{
  p4est_t* p4est;
  P4EST_ASSERT (p4est_connectivity_is_valid (conn));
  F90_p4est_destroy(p4est_out);
#ifndef SC_ENABLE_MPI
  /* Create a forest that is not refined; it consists of the root octant. */                                        
  p4est = p4est_new (sc_MPI_COMM_WORLD, conn, 0, NULL, NULL);
#else
  MPI_Comm Ccomm;                       // Should we remove the MPI_Comm once created??? Not done yet ...
  Ccomm = MPI_Comm_f2c(Fcomm);          // Convert Fortran->C communicator
  p4est = p4est_new (Ccomm, conn, 0, NULL, NULL);
#endif
  *p4est_out = p4est;
}

#ifdef SC_ENABLE_MPI
void F90_p8est_new ( const MPI_Fint Fcomm, 
                     p8est_connectivity_t *conn,
                     p8est_t              **p8est_out)
#else
void F90_p8est_new ( const int dummy_comm,
                     p8est_connectivity_t *conn,
                     p8est_t              **p8est_out)
#endif
{
  p8est_t* p8est;
  P4EST_ASSERT (p8est_connectivity_is_valid (conn));
  F90_p8est_destroy(p8est_out);
#ifndef SC_ENABLE_MPI
  /* Create a forest that is not refined; it consists of the root octant. */                                        
  p8est = p8est_new (sc_MPI_COMM_WORLD, conn, 0, NULL, NULL);
#else
  MPI_Comm Ccomm;                       // Should we remove the MPI_Comm once created??? Not done yet ...
  Ccomm = MPI_Comm_f2c(Fcomm);          // Convert Fortran->C communicator
  p8est = p8est_new (Ccomm, conn, 0, NULL, NULL);
#endif
  
  
  *p8est_out = p8est;
}


void init_fn_callback_2d(p4est_t * p4est,p4est_topidx_t which_tree,p4est_quadrant_t * quadrant)
{
    p4est_tree_t       *tree;
    p4est_quadrant_t   *q;
    sc_array_t         *quadrants;
    int                *user_pointer;
    int                *quadrant_data;
    int                 output;
    
    P4EST_ASSERT(which_tree == 0);
    
    // Extract a reference to the first (and uniquely allowed) tree
    tree = p4est_tree_array_index (p4est->trees,0);
    quadrants = &(tree->quadrants);
    q = p4est_quadrant_array_index(quadrants, current_quadrant_index);
    P4EST_ASSERT(p4est_quadrant_compare(q,quadrant) == 0);
    user_pointer  = (int *) p4est->user_pointer;
    quadrant_data = (int *) quadrant->p.user_data;
    *quadrant_data = user_pointer[current_quadrant_index];
    current_quadrant_index = (current_quadrant_index+1) % (quadrants->elem_count);    
}

void init_fn_callback_3d(p8est_t * p8est,p4est_topidx_t which_tree,p8est_quadrant_t * quadrant)
{
    p8est_tree_t       *tree;
    p8est_quadrant_t   *q;
    sc_array_t         *quadrants;
    int                *user_pointer;
    int                *quadrant_data;
    int                 output;
    
    P4EST_ASSERT(which_tree == 0);
    
    // Extract a reference to the first (and uniquely allowed) tree
    tree = p8est_tree_array_index (p8est->trees,0);
    quadrants = &(tree->quadrants);
    q = p8est_quadrant_array_index(quadrants, current_quadrant_index);
    P4EST_ASSERT(p8est_quadrant_compare(q,quadrant) == 0);
    user_pointer  = (int *) p8est->user_pointer;
    quadrant_data = (int *) quadrant->p.user_data;
    *quadrant_data = user_pointer[current_quadrant_index];
    current_quadrant_index = (current_quadrant_index+1) % (quadrants->elem_count);    
}


void F90_p4est_set_user_pointer(int * user_data, p4est_t * p4est) 
{
    p4est_reset_data(p4est,sizeof(int),init_fn_callback_2d,(void *)user_data);
}

void F90_p8est_set_user_pointer(int * user_data, p8est_t * p8est) 
{
    p8est_reset_data(p8est,sizeof(int),init_fn_callback_3d,(void *)user_data);
}

void F90_p4est_mesh_new(const int k_ghost_cells, 
                        p4est_t        *p4est,
                        p4est_ghost_t **ghost_out,
                        p4est_mesh_t  **mesh_out )
{
  p4est_mesh_t       *mesh;
  p4est_ghost_t      *ghost;
  
  P4EST_ASSERT(k_ghost_cells >= 0 &&  k_ghost_cells <= 1);
  
  F90_p4est_mesh_destroy(mesh_out);
  F90_p4est_ghost_destroy(ghost_out);

  //create ghost layer and mesh
  switch (k_ghost_cells)
  {
      case 0:
          ghost = p4est_ghost_new (p4est, P4EST_CONNECT_FULL);
          mesh = p4est_mesh_new (p4est,ghost,P4EST_CONNECT_FULL);
          break;
      case 1:
          ghost = p4est_ghost_new (p4est, P4EST_CONNECT_FACE);
          mesh = p4est_mesh_new (p4est,ghost,P4EST_CONNECT_FACE);
          break;
  }
  
  //return mesh and ghost as pointer address;
  *mesh_out=(p4est_mesh_t *)mesh;
  *ghost_out=(p4est_ghost_t *)ghost;
}

void F90_p8est_mesh_new(const int k_ghost_cells,
                        p8est_t        *p8est,
                        p8est_ghost_t **ghost_out,
                        p8est_mesh_t  **mesh_out )
{
  p8est_mesh_t       *mesh;
  p8est_ghost_t      *ghost;
  
  P4EST_ASSERT(k_ghost_cells >= 0 &&  k_ghost_cells <= 1);
  
  F90_p8est_mesh_destroy(mesh_out);
  F90_p8est_ghost_destroy(ghost_out);

  //create ghost layer and mesh  
  switch (k_ghost_cells)
  {
      case 0:
          ghost = p8est_ghost_new (p8est, P8EST_CONNECT_FULL);
          mesh = p8est_mesh_new (p8est,ghost,P8EST_CONNECT_FULL);
          break;
      case 1:
          ghost = p8est_ghost_new (p8est, P8EST_CONNECT_EDGE);
          mesh = p8est_mesh_new (p8est,ghost,P8EST_CONNECT_EDGE);
          break;
      case 2:
          ghost = p8est_ghost_new (p8est, P8EST_CONNECT_FACE);
          mesh = p8est_mesh_new (p8est,ghost,P8EST_CONNECT_FACE);
          break;
  }
  
  //return mesh and ghost as pointer address;
  *mesh_out=(p8est_mesh_t *)mesh;
  *ghost_out=(p8est_ghost_t *)ghost;
}

void F90_p4est_connectivity_destroy(p4est_connectivity_t **p4est_connectivity)
{
    if (*p4est_connectivity) p4est_connectivity_destroy(*p4est_connectivity);
    *p4est_connectivity = NULL;
}

void F90_p8est_connectivity_destroy(p8est_connectivity_t **p8est_connectivity)
{
    if (*p8est_connectivity) p8est_connectivity_destroy(*p8est_connectivity);
    *p8est_connectivity = NULL;
}

void F90_p4est_destroy(p4est_t **p4est)
{
    if (*p4est) p4est_destroy(*p4est);
    *p4est = NULL;
}

void F90_p8est_destroy(p8est_t **p8est)
{
    if (*p8est) p8est_destroy(*p8est);
    *p8est = NULL;
}

void F90_p4est_mesh_destroy(p4est_mesh_t **p4est_mesh)
{
    if (*p4est_mesh) 
    {    
      p4est_mesh_destroy(*p4est_mesh);
    }   
    *p4est_mesh = NULL;
}

void F90_p8est_mesh_destroy(p8est_mesh_t **p8est_mesh)
{
    if (*p8est_mesh) 
    {    
      p8est_mesh_destroy(*p8est_mesh);
    }   
    *p8est_mesh = NULL;
}

void F90_p4est_ghost_destroy(p4est_ghost_t **p4est_ghost)
{
    if (*p4est_ghost) 
    {    
        p4est_ghost_destroy(*p4est_ghost);
    }
    *p4est_ghost = NULL;
}

void F90_p8est_ghost_destroy(p8est_ghost_t **p8est_ghost)
{
    if (*p8est_ghost) 
    {    
        p8est_ghost_destroy(*p8est_ghost);
    }   
    *p8est_ghost = NULL;
}

void F90_p4est_locidx_buffer_destroy(p4est_locidx_t **buffer)
{
  if (*buffer) free(*buffer);
  *buffer = NULL;
}

void F90_p4est_int8_buffer_destroy(int8_t **buffer)
{
  if (*buffer) free(*buffer);
  *buffer = NULL;
}

void F90_p4est_get_mesh_info (p4est_t        *p4est,
                              p4est_mesh_t   *mesh,
                              p4est_locidx_t *local_num_quadrants,
                              p4est_locidx_t *ghost_num_quadrants,
                              p4est_gloidx_t *global_num_quadrants,
                              p4est_gloidx_t *global_first_quadrant,
                              p4est_locidx_t *num_half_faces)
{
    int i;
    SC_CHECK_ABORTF (mesh->local_num_quadrants == p4est->local_num_quadrants,
                     "mesh->local_num_quadrants [%d] and p4est->local_num_quadrants mismatch [%d]!",
                     mesh->local_num_quadrants,  p4est->local_num_quadrants);
    
    SC_CHECK_ABORTF (p4est->trees->elem_count == 1,
                     "p4est with more [%ld] than one tree!", p4est->trees->elem_count);
    
    *local_num_quadrants   = p4est->local_num_quadrants;
    *ghost_num_quadrants   = mesh->ghost_num_quadrants;
    *global_num_quadrants  = p4est->global_num_quadrants;
    
    for (i=0; i <= p4est->mpisize; i++ ) 
    {
      global_first_quadrant[i] = p4est->global_first_quadrant[i];
    }
    *num_half_faces        = mesh->quad_to_half->elem_count;
}

void F90_p8est_get_mesh_info (p8est_t        *p8est,
                              p8est_mesh_t   *mesh,
                              p4est_locidx_t *local_num_quadrants,
                              p4est_locidx_t *ghost_num_quadrants,
                              p4est_gloidx_t *global_num_quadrants,
                              p4est_gloidx_t *global_first_quadrant,
                              p4est_locidx_t *num_half_faces)
{
    int i;
    SC_CHECK_ABORTF (mesh->local_num_quadrants == p8est->local_num_quadrants,
                     "mesh->local_num_quadrants [%d] and p8est->local_num_quadrants mismatch [%d]!",
                     mesh->local_num_quadrants,  p8est->local_num_quadrants); 
    
    SC_CHECK_ABORTF (p8est->trees->elem_count == 1,
                     "p8est with more [%ld] than one tree!", p8est->trees->elem_count);
    
    *local_num_quadrants   = p8est->local_num_quadrants;
    *ghost_num_quadrants   = mesh->ghost_num_quadrants;
    *global_num_quadrants  = p8est->global_num_quadrants;
    for (i=0; i <= p8est->mpisize; i++ ) 
    {
      global_first_quadrant[i] = p8est->global_first_quadrant[i];
    }
    *num_half_faces        = mesh->quad_to_half->elem_count;
}


void F90_p4est_get_mesh_topology_arrays( p4est_t        *p4est,
                                         p4est_mesh_t   *mesh,
                                         p4est_ghost_t   *ghost,
                                         p4est_locidx_t **quad_to_quad,
                                         int8_t         **quad_to_face, 
                                         p4est_locidx_t **quad_to_half, 
                                         p4est_locidx_t **quad_to_corner,
                                         p4est_qcoord_t *quadcoords,
                                         int8_t         *quadlevel ) 
{
  int iquad,iquadloc;
  p4est_tree_t       *tree;
  p4est_quadrant_t   *q;
  sc_array_t         *quadrants;
  
  if ( *quad_to_quad ) free(*quad_to_quad);
  if ( *quad_to_face ) free(*quad_to_face);
  if ( *quad_to_half ) free(*quad_to_half);
  if ( *quad_to_corner ) free(*quad_to_corner);
  
  // Extract a reference to the first (and uniquely allowed) tree
  tree = p4est_tree_array_index (p4est->trees,0);
  for (iquad = 0; iquad < mesh->local_num_quadrants; iquad++) {  
    quadrants = &(tree->quadrants);
    iquadloc = iquad - tree->quadrants_offset;
    q = p4est_quadrant_array_index(quadrants, iquadloc);
    quadlevel [iquad    ] = q->level;
    quadcoords[iquad*2  ] = q->x;
    quadcoords[iquad*2+1] = q->y;
  }

  *quad_to_quad=mesh->quad_to_quad;
  *quad_to_face=mesh->quad_to_face;
  *quad_to_half = NULL;
  if(mesh->quad_to_half->elem_count>0) *quad_to_half = (p4est_locidx_t *) mesh->quad_to_half->array;
  *quad_to_corner=mesh->quad_to_corner;
  
  quadrants = &(ghost->ghosts);
  for (iquad = 0; iquad < ghost->ghosts.elem_count; iquad++) {  
    iquadloc =  mesh->local_num_quadrants+iquad;
    q = p4est_quadrant_array_index(quadrants, iquad);
    quadlevel [iquadloc]     = q->level;
    quadcoords[iquadloc*2  ] = q->x;
    quadcoords[iquadloc*2+1] = q->y;
  }
}

void F90_p8est_get_mesh_topology_arrays( p8est_t        *p8est,
                                         p8est_mesh_t   *mesh,
                                         p8est_ghost_t  *ghost,
                                         p4est_locidx_t **quad_to_quad,
                                         int8_t         **quad_to_face, 
                                         p4est_locidx_t **quad_to_half, 
                                         p4est_locidx_t *quad_to_quad_by_edge,
                                         int8_t         *quad_to_edge,
                                         p4est_locidx_t *num_half_edges,
                                         p4est_locidx_t **quad_to_half_by_edge,
                                         p4est_locidx_t **quad_to_corner,
                                         p4est_qcoord_t *quadcoords,
                                         int8_t         *quadlevel ) 
{
  int i,iquad,iquadloc;
  p8est_tree_t       *tree;
  p8est_quadrant_t   *q;
  sc_array_t         *quadrants;
  edge_info_t edge_info;
  p4est_locidx_t *aux_quad_to_half_by_edge;
  
  if ( *quad_to_quad ) free(*quad_to_quad);
  if ( *quad_to_face ) free(*quad_to_face);
  if ( *quad_to_half ) free(*quad_to_half);
  if ( *quad_to_corner ) free(*quad_to_corner);
  if ( *quad_to_half_by_edge ) free(*quad_to_half_by_edge);
  
  // Extract a reference to the first (and uniquely allowed) tree
  tree = p8est_tree_array_index (p8est->trees,0);
  for (iquad = 0; iquad < mesh->local_num_quadrants; iquad++) {  
    quadrants = &(tree->quadrants);
    iquadloc = iquad - tree->quadrants_offset;
    q = p8est_quadrant_array_index(quadrants, iquadloc);
    quadlevel [iquad    ] = q->level;
    quadcoords[iquad*3  ] = q->x;
    quadcoords[iquad*3+1] = q->y;
    quadcoords[iquad*3+2] = q->z;
  }

  // Extract the neighbor info for edges. Initialize it to -1 (like in quad_to_corner)
  for(i=0;i<12*(mesh->local_num_quadrants);i++)
  {
    quad_to_quad_by_edge[i] = -1;
    quad_to_edge[i] = -1;
  }
  // Allocate to maximum possible size. All edges are half-size edge
  aux_quad_to_half_by_edge = (p4est_locidx_t *) malloc( (size_t) 2*12*mesh->local_num_quadrants*sizeof(p4est_locidx_t) );
  
  edge_info.local_num_quadrants       = mesh->local_num_quadrants;
  edge_info.quad_to_quad_by_edge      = quad_to_quad_by_edge;
  edge_info.quad_to_edge              = quad_to_edge;
  edge_info.quad_to_half_by_edge      = aux_quad_to_half_by_edge;
  edge_info.quad_to_half_by_edge_size = 0;
  p8est_iterate(p8est, ghost, &edge_info, NULL, NULL,edge_callback, NULL);

  *quad_to_quad=mesh->quad_to_quad;
  *quad_to_face=mesh->quad_to_face;
  *quad_to_half = NULL;
  if(mesh->quad_to_half->elem_count>0) *quad_to_half = (p4est_locidx_t *) mesh->quad_to_half->array;
  *quad_to_corner=mesh->quad_to_corner;
  
  *quad_to_half_by_edge = (p4est_locidx_t *) malloc( (size_t) 2*edge_info.quad_to_half_by_edge_size*sizeof(p4est_locidx_t) );  
  for(i=0;i<2*edge_info.quad_to_half_by_edge_size;i++)
  {
    (*quad_to_half_by_edge)[i] = aux_quad_to_half_by_edge[i];
  }
  free(aux_quad_to_half_by_edge);
  *num_half_edges = edge_info.quad_to_half_by_edge_size;
  
  quadrants = &(ghost->ghosts);
  for (iquad = 0; iquad < ghost->ghosts.elem_count; iquad++) {  
      iquadloc =  mesh->local_num_quadrants+iquad;
      q = p8est_quadrant_array_index(quadrants, iquad);
      quadlevel [iquadloc]     = q->level;
      quadcoords[iquadloc*3  ] = q->x;
      quadcoords[iquadloc*3+1] = q->y;
      quadcoords[iquadloc*3+2] = q->z;
  }
}

void edge_callback(p8est_iter_edge_info_t * info, void * user_data)
{
  p8est_iter_edge_side_t * cells_around;
  edge_info_t *edge_info;
  p4est_locidx_t *quad_to_quad_by_edge;
  int8_t         *quad_to_edge;
  p4est_locidx_t *quad_to_half_by_edge;

  int i,j,k;
  p4est_locidx_t ineig[4], jneig[4];
  int8_t ineig_iedge[4], jneig_jedge[4];
  int8_t i_is_ghost[4], j_is_ghost[4];
  
  for(i=0;i<2;i++) ineig[i]   = -1;
  for(i=0;i<2;i++) jneig[i]   = -1;

  P4EST_ASSERT( (info->sides.elem_count) <= 4 );

  edge_info = (edge_info_t *) user_data;
  quad_to_quad_by_edge = edge_info->quad_to_quad_by_edge;
  quad_to_edge = edge_info->quad_to_edge;
  quad_to_half_by_edge = edge_info->quad_to_half_by_edge;
  
  cells_around = (p8est_iter_edge_side_t *) info->sides.array;
  
  // First treat boundary edges
  if ( info->sides.elem_count == 1 || info->sides.elem_count == 2 )
  {
      for(i=0;i<(info->sides.elem_count);i++)
      {
          if (cells_around[i].is_hanging)
          {
              ineig[0]       = cells_around[i].is.hanging.quadid[0];
              ineig[1]       = cells_around[i].is.hanging.quadid[1];
              ineig_iedge[0] = cells_around[i].edge;
              i_is_ghost[0]  = cells_around[i].is.hanging.is_ghost[0];
              i_is_ghost[1]  = cells_around[i].is.hanging.is_ghost[1];
              
              if ( i_is_ghost[0] ) ineig[0]+=edge_info->local_num_quadrants;
              if ( i_is_ghost[1] ) ineig[1]+=edge_info->local_num_quadrants;
              
              if ( ! i_is_ghost[0] ) {
                quad_to_quad_by_edge[ 12*ineig[0] + ineig_iedge[0] ] = ineig[0];
                quad_to_edge        [ 12*ineig[0] + ineig_iedge[0] ] = ineig_iedge[0];
              }
              if ( ! i_is_ghost[1] ) {
                quad_to_quad_by_edge[ 12*ineig[1] + ineig_iedge[0] ] = ineig[1];
                quad_to_edge        [ 12*ineig[1] + ineig_iedge[0] ] = ineig_iedge[0];
              }  
          }
          else
          {
              i_is_ghost[0]  = cells_around[i].is.full.is_ghost;
              ineig[0]       = cells_around[i].is.full.quadid;
              ineig_iedge[0] = cells_around[i].edge;
              if ( i_is_ghost[0] ) ineig[0]+=edge_info->local_num_quadrants;
              if ( ! i_is_ghost[0]  ) {
               quad_to_quad_by_edge[ 12*ineig[0] + ineig_iedge[0] ] = ineig[0];
               quad_to_edge        [ 12*ineig[0] + ineig_iedge[0] ] = ineig_iedge[0];  
              }  
          } 
      }
      return;
  }
  
  k=0;
  for(i=0;i<(info->sides.elem_count);i++)
  {
    if (cells_around[i].is_hanging)
    {
      ineig[2*k]         = cells_around[i].is.hanging.quadid[0];
      ineig[2*k+1]       = cells_around[i].is.hanging.quadid[1];
      ineig_iedge[2*k]   = cells_around[i].edge;
      i_is_ghost[2*k]    = cells_around[i].is.hanging.is_ghost[0];
      i_is_ghost[2*k+1]  = cells_around[i].is.hanging.is_ghost[1];
      if ( i_is_ghost[2*k] )   ineig[2*k]   += edge_info->local_num_quadrants;
      if ( i_is_ghost[2*k+1] ) ineig[2*k+1] += edge_info->local_num_quadrants;
    }
    else
    {
      ineig[2*k]       = cells_around[i].is.full.quadid;
      ineig_iedge[2*k] = cells_around[i].edge;
      i_is_ghost[2*k]  = cells_around[i].is.full.is_ghost;
      if ( i_is_ghost[2*k] ) ineig[2*k]   += edge_info->local_num_quadrants;
    } 

    for(j=i;j<(info->sides.elem_count);j++)
    {
        if ( (cells_around[i].faces[0] != cells_around[j].faces[0]) &&
             (cells_around[i].faces[0] != cells_around[j].faces[1]) &&
             (cells_around[i].faces[1] != cells_around[j].faces[0]) &&
             (cells_around[i].faces[1] != cells_around[j].faces[1]) )
        {
          P4EST_ASSERT(k<2);
          if (cells_around[j].is_hanging)
          {
            jneig[2*k]        = cells_around[j].is.hanging.quadid[0];
            jneig[2*k+1]      = cells_around[j].is.hanging.quadid[1];
            jneig_jedge[2*k]  = cells_around[j].edge;
            j_is_ghost[2*k]   = cells_around[j].is.hanging.is_ghost[0];
            j_is_ghost[2*k+1] = cells_around[j].is.hanging.is_ghost[1];     
            if ( j_is_ghost[2*k] )   jneig[2*k]   += edge_info->local_num_quadrants;
            if ( j_is_ghost[2*k+1] ) jneig[2*k+1] += edge_info->local_num_quadrants;
          }
          else
          {
            jneig[2*k]       = cells_around[j].is.full.quadid;
            jneig_jedge[2*k] = cells_around[j].edge;
            j_is_ghost[2*k]  = cells_around[j].is.full.is_ghost;
            if ( j_is_ghost[2*k] )   jneig[2*k]   += edge_info->local_num_quadrants;
          } 
          
          if (cells_around[i].is_hanging && cells_around[j].is_hanging) 
          {
              // i side
              if ( ! i_is_ghost[2*k] ) 
              {
                quad_to_quad_by_edge[ 12*ineig[2*k]   + ineig_iedge[2*k] ] = jneig[2*k];
                quad_to_edge        [ 12*ineig[2*k]   + ineig_iedge[2*k] ] = jneig_jedge[2*k];
              }
              if ( ! i_is_ghost[2*k+1] ) 
              {
                quad_to_quad_by_edge[ 12*ineig[2*k+1] + ineig_iedge[2*k] ] = jneig[2*k+1];
                quad_to_edge        [ 12*ineig[2*k+1] + ineig_iedge[2*k] ] = jneig_jedge[2*k];
              }  
              
              //j side
              if ( ! j_is_ghost[2*k] )
              {    
                quad_to_quad_by_edge[ 12*jneig[2*k]   + jneig_jedge[2*k] ] = ineig[2*k];
                quad_to_edge        [ 12*jneig[2*k]   + jneig_jedge[2*k] ] = ineig_iedge[2*k];
              }
              
              if ( ! j_is_ghost[2*k+1] )
              {    
                quad_to_quad_by_edge[ 12*jneig[2*k+1] + jneig_jedge[2*k] ] = ineig[2*k+1];
                quad_to_edge        [ 12*jneig[2*k+1] + jneig_jedge[2*k] ] = ineig_iedge[2*k];
              }  
          }
          else if (! cells_around[i].is_hanging && cells_around[j].is_hanging) 
          {
              // i side
              if ( ! i_is_ghost[2*k] ) 
              {
                quad_to_quad_by_edge[ 12*ineig[2*k] + ineig_iedge[2*k] ] = edge_info->quad_to_half_by_edge_size;
                quad_to_edge        [ 12*ineig[2*k] + ineig_iedge[2*k] ] = jneig_jedge[2*k]-24;
                quad_to_half_by_edge[ 2*edge_info->quad_to_half_by_edge_size     ] = jneig[2*k];
                quad_to_half_by_edge[ 2*edge_info->quad_to_half_by_edge_size + 1 ] = jneig[2*k+1];
                edge_info->quad_to_half_by_edge_size++;
              }  
              
              //j side
              if ( ! j_is_ghost[2*k] ) 
              {
                quad_to_quad_by_edge[ 12*jneig[2*k]   + jneig_jedge[2*k] ] = ineig[2*k];
                quad_to_edge        [ 12*jneig[2*k]   + jneig_jedge[2*k] ] = 24+ineig_iedge[2*k];
              }
              
              if ( ! j_is_ghost[2*k+1] ) 
              {
                quad_to_quad_by_edge[ 12*jneig[2*k+1] + jneig_jedge[2*k] ] = ineig[2*k];
                quad_to_edge        [ 12*jneig[2*k+1] + jneig_jedge[2*k] ] = 48+ineig_iedge[2*k];
              }
          }
          else if (cells_around[i].is_hanging && !cells_around[j].is_hanging) 
          {
              // i side
              if ( ! i_is_ghost[2*k] ) 
              {
                quad_to_quad_by_edge[ 12*ineig[2*k]   + ineig_iedge[2*k] ] = jneig[2*k];
                quad_to_edge        [ 12*ineig[2*k]   + ineig_iedge[2*k] ] = 24+jneig_jedge[2*k];
              }
              if ( ! i_is_ghost[2*k+1] ) 
              {
                quad_to_quad_by_edge[ 12*ineig[2*k+1] + ineig_iedge[2*k] ] = jneig[2*k];
                quad_to_edge        [ 12*ineig[2*k+1] + ineig_iedge[2*k] ] = 48+jneig_jedge[2*k];
              }
             
              //j side
              if ( ! j_is_ghost[2*k] ) 
              {    
                quad_to_quad_by_edge[ 12*jneig[2*k] + jneig_jedge[2*k] ] = edge_info->quad_to_half_by_edge_size;
                quad_to_edge        [ 12*jneig[2*k] + jneig_jedge[2*k] ] = ineig_iedge[2*k]-24;
                quad_to_half_by_edge[ 2*edge_info->quad_to_half_by_edge_size ] = ineig[2*k];
                quad_to_half_by_edge[ 2*edge_info->quad_to_half_by_edge_size + 1 ] = ineig[2*k+1];
                edge_info->quad_to_half_by_edge_size++;
              }  
          }   
          else // !cells_around[i].is_hanging && !cells_around[j].is_hanging
          {
              if ( ! i_is_ghost[2*k] ) 
              {    
                quad_to_quad_by_edge[ 12*ineig[2*k] + ineig_iedge[2*k] ] = jneig[2*k];
                quad_to_edge[ 12*ineig[2*k] + ineig_iedge[2*k] ] = jneig_jedge[2*k];
              }  
              if ( ! j_is_ghost[2*k] ) 
              {    
                quad_to_quad_by_edge[ 12*jneig[2*k] + jneig_jedge[2*k] ] = ineig[2*k];
                quad_to_edge[ 12*jneig[2*k] + jneig_jedge[2*k] ] = ineig_iedge[2*k];
              }  
          }
          k++;
          if (k==2) return;
        }
    }
  }
}

int refine_callback_2d(p4est_t * p4est,
                    p4est_topidx_t which_tree,
                    p4est_quadrant_t * quadrant)
{
    P4EST_ASSERT(which_tree == 0);
    return (*((int *)quadrant->p.user_data) ==  FEMPAR_refinement_flag);
}

int refine_callback_3d(p8est_t * p8est,
                    p4est_topidx_t which_tree,
                    p8est_quadrant_t * quadrant)
{
    P4EST_ASSERT(which_tree == 0);
    return (*((int *)quadrant->p.user_data) ==  FEMPAR_refinement_flag);
}


void  refine_replace_callback_2d (p4est_t * p4est,
                               p4est_topidx_t which_tree,
                               int num_outgoing,
                               p4est_quadrant_t * outgoing[],
                               int num_incoming,
                               p4est_quadrant_t * incoming[])
 {
    int quadrant_index;
    int *quadrant_data;
    P4EST_ASSERT(which_tree   == 0);
    P4EST_ASSERT(num_outgoing == 1);
    P4EST_ASSERT(num_incoming == P4EST_CHILDREN);
    for (quadrant_index=0; quadrant_index < P4EST_CHILDREN; quadrant_index++)
    {
      quadrant_data = (int *) incoming[quadrant_index]->p.user_data;
      *quadrant_data = FEMPAR_do_nothing_flag;
    }
 }

void  refine_replace_callback_3d (p8est_t * p8est,
                               p4est_topidx_t which_tree,
                               int num_outgoing,
                               p8est_quadrant_t * outgoing[],
                               int num_incoming,
                               p8est_quadrant_t * incoming[])
 {
    int quadrant_index;
    int *quadrant_data;
    P4EST_ASSERT(which_tree   == 0);
    P4EST_ASSERT(num_outgoing == 1);
    P4EST_ASSERT(num_incoming == P8EST_CHILDREN);
    for (quadrant_index=0; quadrant_index < P8EST_CHILDREN; quadrant_index++)
    {
      quadrant_data = (int *) incoming[quadrant_index]->p.user_data;
      *quadrant_data = FEMPAR_do_nothing_flag;
    }
 }

void F90_p4est_refine( p4est_t * p4est )
{
    p4est_refine_ext(p4est, 0, -1, refine_callback_2d, NULL, refine_replace_callback_2d);
}

void F90_p8est_refine( p8est_t * p8est )
{
    p8est_refine_ext(p8est, 0, -1, refine_callback_3d, NULL, refine_replace_callback_3d);
}

int coarsen_callback_2d (p4est_t * p4est,
                      p4est_topidx_t which_tree,
                      p4est_quadrant_t * quadrants[])
{
    int quadrant_index;
    int coarsen;
    P4EST_ASSERT(which_tree == 0);
    
    coarsen = 1;
    for (quadrant_index=0; quadrant_index < P4EST_CHILDREN; quadrant_index++)
    {
      coarsen = (*((int *)(quadrants[quadrant_index]->p.user_data)) ==  FEMPAR_coarsening_flag);
      if (!coarsen) return coarsen;
    }
    return coarsen;
}

int coarsen_callback_3d (p8est_t * p8est,
                      p4est_topidx_t which_tree,
                      p8est_quadrant_t * quadrants[])
{
    int quadrant_index;
    int coarsen;
    P4EST_ASSERT(which_tree == 0);
    
    coarsen = 1;
    for (quadrant_index=0; quadrant_index < P8EST_CHILDREN; quadrant_index++)
    {
      coarsen = (*((int *)(quadrants[quadrant_index]->p.user_data)) ==  FEMPAR_coarsening_flag);
      if (!coarsen) return coarsen;
    }
    return coarsen;
}

void F90_p4est_coarsen( p4est_t * p4est )
{
    p4est_coarsen(p4est, 0, coarsen_callback_2d, NULL);
}

void F90_p8est_coarsen( p8est_t * p8est )
{
    p8est_coarsen(p8est, 0, coarsen_callback_3d, NULL);
}

void F90_p4est_copy( p4est_t * p4est_input, p4est_t ** p4est_output )
{
   F90_p4est_destroy(p4est_output);
   *p4est_output = p4est_copy(p4est_input,0);
}

void F90_p8est_copy( p8est_t * p8est_input, p8est_t ** p8est_output )
{
   F90_p8est_destroy(p8est_output);
   *p8est_output = p8est_copy(p8est_input,0);
}

void F90_p4est_balance( const int k_2_1_balance, p4est_t * p4est )
{
  P4EST_ASSERT(k_2_1_balance >= 0 &&  k_2_1_balance <= 1);
  switch (k_2_1_balance)
   {
    case 0:
       p4est_balance(p4est, P4EST_CONNECT_FULL, NULL);
       break;
    case 1:
       p4est_balance(p4est, P4EST_CONNECT_FACE, NULL);
       break;
    }
}

void F90_p8est_balance( const int k_2_1_balance, p8est_t * p8est )
{
  P4EST_ASSERT(k_2_1_balance >= 0 &&  k_2_1_balance <= 2);
  switch (k_2_1_balance)
  {
      case 0:
          p8est_balance(p8est, P8EST_CONNECT_FULL, NULL);
          break;
      case 1:
          p8est_balance(p8est, P8EST_CONNECT_EDGE, NULL);
          break;
      case 2:
          p8est_balance(p8est, P8EST_CONNECT_FACE, NULL);
          break;    
  }
}

int weight_callback_2d(p4est_t * p4est,
                       p4est_topidx_t which_tree,
                       p4est_quadrant_t * quadrant)
{
    P4EST_ASSERT(which_tree == 0);
    return (*((int *)quadrant->p.user_data));
}

int weight_callback_3d(p8est_t * p8est,
                       p4est_topidx_t which_tree,
                       p8est_quadrant_t * quadrant)
{
    P4EST_ASSERT(which_tree == 0);
    return (*((int *)quadrant->p.user_data));
}

void F90_p4est_partition ( p4est_t * p4est )
{
    /*
    * \param [in,out] p4est      The forest that will be partitioned.
    * \param [in]     allow_for_coarsening Slightly modify partition such that
    *                            quadrant families are not split between ranks.
    * \param [in]     weight_fn  A weighting function or NULL
    *                            for uniform partitioning.
    */
    p4est_partition(p4est, 1, weight_callback_2d);
}

void F90_p8est_partition ( p8est_t * p8est )
{
    /*
    * \param [in,out] p4est      The forest that will be partitioned.
    * \param [in]     allow_for_coarsening Slightly modify partition such that
    *                            quadrant families are not split between ranks.
    * \param [in]     weight_fn  A weighting function or NULL
    *                            for uniform partitioning.
    */
    p8est_partition(p8est, 1, weight_callback_3d);
}


void F90_p4est_update_refinement_and_coarsening_flags(p4est_t * p4est_old, p4est_t * p4est_new)
{
    p4est_tree_t       *tree_old;
    p4est_quadrant_t   *q_old;
    sc_array_t         *quadrants_old;
    int                old_quadrant_index;
    
    p4est_tree_t       *tree_new;
    p4est_quadrant_t   *q_new;
    sc_array_t         *quadrants_new;
    int                i, new_quadrant_index;
    
    int * user_pointer;
   
    P4EST_ASSERT(p4est_old->user_pointer == p4est_new->user_pointer);
    
    user_pointer = (int *) p4est_old->user_pointer;
    
    // Extract references to the first (and uniquely allowed) trees
    tree_old = p4est_tree_array_index (p4est_old->trees,0);
    tree_new = p4est_tree_array_index (p4est_new->trees,0);
    
    quadrants_old = &(tree_old->quadrants);
    quadrants_new = &(tree_new->quadrants);
    
    new_quadrant_index = 0;
    for (old_quadrant_index=0; old_quadrant_index < quadrants_old->elem_count;)
    {
       q_old = p4est_quadrant_array_index(quadrants_old, old_quadrant_index);
       q_new = p4est_quadrant_array_index(quadrants_new, new_quadrant_index);
       if ( p4est_quadrant_compare(q_old,q_new) == 0 ) //q_old was not refined nor coarsened
       {
           user_pointer[old_quadrant_index] = FEMPAR_do_nothing_flag;
           old_quadrant_index++;
           new_quadrant_index++;
       }
       else if ( p4est_quadrant_is_parent(q_old,q_new)  )  //q_old was refined
       { 
           user_pointer[old_quadrant_index] = FEMPAR_refinement_flag;
           old_quadrant_index++;
           new_quadrant_index = new_quadrant_index + P4EST_CHILDREN;
       }
       else if ( p4est_quadrant_is_parent(q_new,q_old) ) //q_old and its siblings were coarsened 
       {
           for (i=0; i < P4EST_CHILDREN; i++)
           {
               user_pointer[old_quadrant_index] = FEMPAR_coarsening_flag;
               old_quadrant_index++;
           }
           new_quadrant_index++;
       }
       else
       {
         P4EST_ASSERT(0);
       }
    }
}

void F90_p8est_update_refinement_and_coarsening_flags(p8est_t * p8est_old, p8est_t * p8est_new)
{
    p8est_tree_t       *tree_old;
    p8est_quadrant_t   *q_old;
    sc_array_t         *quadrants_old;
    int                old_quadrant_index;
    
    p8est_tree_t       *tree_new;
    p8est_quadrant_t   *q_new;
    sc_array_t         *quadrants_new;
    int                i, new_quadrant_index;
    
    int * user_pointer;
   
    P4EST_ASSERT(p8est_old->user_pointer == p8est_new->user_pointer);
    
    user_pointer = (int *) p8est_old->user_pointer;
    
    // Extract references to the first (and uniquely allowed) trees
    tree_old = p8est_tree_array_index (p8est_old->trees,0);
    tree_new = p8est_tree_array_index (p8est_new->trees,0);
    
    quadrants_old = &(tree_old->quadrants);
    quadrants_new = &(tree_new->quadrants);
    
    new_quadrant_index = 0;
    for (old_quadrant_index=0; old_quadrant_index < quadrants_old->elem_count;)
    {
       q_old = p8est_quadrant_array_index(quadrants_old, old_quadrant_index);
       q_new = p8est_quadrant_array_index(quadrants_new, new_quadrant_index);
       if ( p8est_quadrant_compare(q_old,q_new) == 0 ) //q_old was not refined nor coarsened
       {
           user_pointer[old_quadrant_index] = FEMPAR_do_nothing_flag;
           old_quadrant_index++;
           new_quadrant_index++;
       }
       else if ( p8est_quadrant_is_parent(q_old,q_new)  )  //q_old was refined
       { 
           user_pointer[old_quadrant_index] = FEMPAR_refinement_flag;
           old_quadrant_index++;
           new_quadrant_index = new_quadrant_index + P8EST_CHILDREN;
       }
       else if ( p8est_quadrant_is_parent(q_new,q_old) ) //q_old and its siblings were coarsened 
       {
           for (i=0; i < P8EST_CHILDREN; i++)
           {
               user_pointer[old_quadrant_index] = FEMPAR_coarsening_flag;
               old_quadrant_index++;
           }
           new_quadrant_index++;
       }
       else
       {
         P4EST_ASSERT(0);
       }
    }

}

void F90_p4est_get_quadrant_vertex_coordinates(p4est_connectivity_t * connectivity,
                                               p4est_topidx_t treeid,
                                               p4est_qcoord_t x,
                                               p4est_qcoord_t y, 
                                               int8_t level,
                                               int   corner,
                                               double vxyz[3])
{
    P4EST_ASSERT(treeid == 0);
    p4est_quadrant_t myself;
    p4est_quadrant_t neighbour;
    
    // Create myself
    myself.x     = x;
    myself.y     = y; 
    myself.level = level;
    
    if ( corner == 0 ) {
          neighbour = myself;
      }      
    else if ( corner == 1 ) {
       p4est_quadrant_face_neighbor(&myself, 
                                    corner, 
                                    &neighbour);
    }
    else if ( corner == 2 ) { 
       p4est_quadrant_face_neighbor(&myself, 
                                    corner+1, 
                                    &neighbour); 
   }
    else if ( corner == 3 ) {   
       p4est_quadrant_corner_neighbor(&myself, 
                                    corner, 
                                    &neighbour); 
   }
   
    // Extract numerical coordinates of lower_left corner of my corner neighbour
    p4est_qcoord_to_vertex (connectivity, 
                            treeid, 
                            neighbour.x, 
                            neighbour.y, 
                            vxyz);
    
    // IMPORTANT NOTE: this initialization to zero is absolutely necessary in the case
    // of 2D domains (num_dims=2) with SPACE_DIM == 3 (FEMPAR global parameter). It is 
    // necessary to  guarantee that the third component is initialized to zero in order
    // to avoid polluting uninitialized data across the whole system. In any case, this
    // subroutine is highly tangled to its client (thus immobile). It will only work if the preconditions
    // established in its current's client are fullfilled. Thus, it might be needed to revisit
    // the way both cooperate with each other for cleanliness arguments.
    vxyz[2] = 0.0;
}

void F90_p8est_get_quadrant_vertex_coordinates(p8est_connectivity_t * connectivity,
                                               p4est_topidx_t treeid,
                                               p4est_qcoord_t x,
                                               p4est_qcoord_t y, 
                                               p4est_qcoord_t z, 
                                               int8_t level,
                                               int   corner,
                                               double vxyz[3])
{
    P4EST_ASSERT(treeid == 0);
    p8est_quadrant_t myself;
    p8est_quadrant_t neighbour;
    
    // Create myself
    myself.x     = x;
    myself.y     = y; 
    myself.z     = z; 
    myself.level = level;
    
    if ( corner == 0 ) {
          neighbour = myself;
      }      
    else if ( corner == 1 ) {
       p8est_quadrant_face_neighbor(&myself, 
                                    1, 
                                    &neighbour);
    }
    else if ( corner == 2 ) { 
       p8est_quadrant_face_neighbor(&myself, 
                                    3, 
                                    &neighbour); 
   }
    else if ( corner == 3 ) {   
       p8est_quadrant_edge_neighbor(&myself, 
                                    11, 
                                    &neighbour); 
    }
    else if ( corner == 4 ) {   
       p8est_quadrant_face_neighbor(&myself, 
                                    5, 
                                    &neighbour); 
   }
    else if ( corner == 5 ) {   
       p8est_quadrant_edge_neighbor(&myself, 
                                    7, 
                                    &neighbour); 
   }
    else if ( corner == 6 ) {   
       p8est_quadrant_edge_neighbor(&myself, 
                                    3, 
                                    &neighbour); 
   }
    else if ( corner == 7 ) {   
       p8est_quadrant_corner_neighbor(&myself, 
                                    7, 
                                    &neighbour); 
   }
   
    // Extract numerical coordinates of lower_left corner of my corner neighbour
    p8est_qcoord_to_vertex (connectivity, 
                            treeid, 
                            neighbour.x, 
                            neighbour.y, 
                            neighbour.z, 
                            vxyz);
}

int F90_p4est_is_ancestor ( p4est_qcoord_t q1_x,
                            p4est_qcoord_t q1_y,
                            int8_t q1_level,
                            p4est_qcoord_t q2_x,
                            p4est_qcoord_t q2_y,
                            int8_t q2_level )
{
    p4est_quadrant_t q1;
    p4est_quadrant_t q2;
    
    q1.x = q1_x;
    q1.y = q1_y;
    q1.level = q1_level;
    
    q2.x = q2_x;
    q2.y = q2_y;
    q2.level = q2_level;
    
    return p4est_quadrant_is_ancestor ( &q1, &q2 );
    
}

int F90_p4est_is_equal ( p4est_qcoord_t q1_x,
                         p4est_qcoord_t q1_y,
                         int8_t q1_level,
                         p4est_qcoord_t q2_x,
                         p4est_qcoord_t q2_y,
                         int8_t q2_level )
{
    p4est_quadrant_t q1;
    p4est_quadrant_t q2;
    
    q1.x = q1_x;
    q1.y = q1_y;
    q1.level = q1_level;
    
    q2.x = q2_x;
    q2.y = q2_y;
    q2.level = q2_level;
    
    return p4est_quadrant_is_equal ( &q1, &q2 );
    
}

void F90_p4est_quadrant_set_morton ( int level,
                                     int64_t id,
                                     p4est_qcoord_t *q_x,
                                     p4est_qcoord_t *q_y )
{
    p4est_quadrant_t q;
    p4est_quadrant_set_morton( &q, level, id );
    *q_x = q.x;
    *q_y = q.y;
}

int F90_p4est_quadrant_child_id ( p4est_qcoord_t q_x,
                                  p4est_qcoord_t q_y,
                                  int8_t q_level )
{
    p4est_quadrant_t q;
    q.x     = q_x;
    q.y     = q_y;
    q.level = q_level;
    return p4est_quadrant_child_id ( &q );
}

int F90_p8est_quadrant_child_id ( p4est_qcoord_t q_x,
                                  p4est_qcoord_t q_y,
                                  p4est_qcoord_t q_z,
                                  int8_t q_level )
{
    p8est_quadrant_t q;
    q.x     = q_x;
    q.y     = q_y;
    q.z     = q_z;
    q.level = q_level;
    return p8est_quadrant_child_id ( &q );
}

void F90_p4est_fill_ghost_procs ( p4est_ghost_t  * p4est_ghost,
                                  p4est_locidx_t * ghost_procs )
                                   
{
  int i,j;  
  for (i=0; i < p4est_ghost->mpisize; i++)
  {
    for (j=p4est_ghost->proc_offsets[i]; j<p4est_ghost->proc_offsets[i+1]; j++)
    {
       ghost_procs[j] = i+1;
    }
  }  
}

void F90_p8est_fill_ghost_procs ( p8est_ghost_t  * p8est_ghost,
                                  p4est_locidx_t * ghost_procs )

{
    int i,j;  
    for (i=0; i < p8est_ghost->mpisize; i++)
    {
        for (j=p8est_ghost->proc_offsets[i]; j<p8est_ghost->proc_offsets[i+1]; j++)
        {
            ghost_procs[j] = i+1;
        }
    }  
}

void F90_p4est_fill_ghost_ggids( p4est_ghost_t  * p4est_ghost,
                                 p4est_gloidx_t * first_global_quadrant,
                                 p4est_gloidx_t * ghost_ggids )
{
    int i,j;  
    p4est_quadrant_t * ghost_quadrants = (p4est_quadrant_t *) p4est_ghost->ghosts.array;
    for (i=0; i < p4est_ghost->mpisize; i++)
    {
        for (j=p4est_ghost->proc_offsets[i]; j<p4est_ghost->proc_offsets[i+1]; j++)
        {
            ghost_ggids[j] = first_global_quadrant[i] + (p4est_gloidx_t) (ghost_quadrants[j].p.piggy3.local_num+1) ;
        }
    }   
}

void F90_p8est_fill_ghost_ggids( p8est_ghost_t  * p8est_ghost,
                                 p4est_gloidx_t * first_global_quadrant,
                                 p4est_gloidx_t * ghost_ggids )
{
    int i,j;  
    p8est_quadrant_t * ghost_quadrants = (p8est_quadrant_t *) p8est_ghost->ghosts.array;
    for (i=0; i < p8est_ghost->mpisize; i++)
    {
        for (j=p8est_ghost->proc_offsets[i]; j<p8est_ghost->proc_offsets[i+1]; j++)
        {
            ghost_ggids[j] = first_global_quadrant[i] + (p4est_gloidx_t) (ghost_quadrants[j].p.piggy3.local_num+1) ;
        }
    }   
}

void F90_p4est_allocate_and_fill_cell_import_raw_arrays( p4est_t        * p4est,
                                                         p4est_ghost_t  * p4est_ghost,
                                                         p4est_locidx_t * num_neighbours,
                                                         p4est_locidx_t ** neighbour_ids,
                                                         p4est_locidx_t ** rcv_ptrs,
                                                         p4est_locidx_t ** rcv_leids,
                                                         p4est_locidx_t ** snd_ptrs,
                                                         p4est_locidx_t ** snd_leids)
{
    int i, j;
    p4est_tree_t * tree;
    sc_array_t * quadrants;
    ssize_t result;
    p4est_quadrant_t   *q;
    
    if ( *neighbour_ids ) free(*neighbour_ids);
    if ( *rcv_ptrs ) free(*rcv_ptrs);
    if ( *rcv_leids ) free(*rcv_leids);
    if ( *snd_ptrs ) free(*snd_ptrs);
    if ( *snd_leids ) free(*snd_leids);
    
    *num_neighbours = 0;
    for (i=0; i < p4est_ghost->mpisize; i++)
    {
        if ( p4est_ghost->proc_offsets[i+1]        - p4est_ghost->proc_offsets[i]        > 0 || 
                p4est_ghost->mirror_proc_offsets[i+1] - p4est_ghost->mirror_proc_offsets[i] > 0 )
        {
            (*num_neighbours)++;
        }
    }   
    *neighbour_ids = (p4est_locidx_t *) malloc( (size_t) (*num_neighbours)   * sizeof(p4est_locidx_t) ); P4EST_ASSERT((*neighbour_ids) != NULL);
    *rcv_ptrs      = (p4est_locidx_t *) malloc( (size_t) (*num_neighbours+1) * sizeof(p4est_locidx_t) ); P4EST_ASSERT((*rcv_ptrs)      != NULL);
    *snd_ptrs      = (p4est_locidx_t *) malloc( (size_t) (*num_neighbours+1) * sizeof(p4est_locidx_t) ); P4EST_ASSERT((*snd_ptrs)  != NULL);
    
    //Fill neighbour_ids, rcv_ptrs, snd_ptrs
    j=0;
    for (i=0; i < p4est_ghost->mpisize; i++)
    {
        if ( p4est_ghost->proc_offsets[i+1]        - p4est_ghost->proc_offsets[i]        > 0 || 
                p4est_ghost->mirror_proc_offsets[i+1] - p4est_ghost->mirror_proc_offsets[i] > 0 )
        {
            (*neighbour_ids)[j]= i+1;
            (*rcv_ptrs)[j]     = p4est_ghost->proc_offsets[i]+1;
            (*snd_ptrs)[j]     = p4est_ghost->mirror_proc_offsets[i]+1;
            j++;
        }
    }
    (*rcv_ptrs)[j] = p4est_ghost->proc_offsets[i]+1;
    (*snd_ptrs)[j] = p4est_ghost->mirror_proc_offsets[i]+1;
    
    *rcv_leids     = (p4est_locidx_t *) malloc( (size_t) (p4est_ghost->proc_offsets[p4est_ghost->mpisize]) * sizeof(p4est_locidx_t) ); P4EST_ASSERT((*rcv_leids) != NULL);
    *snd_leids     = (p4est_locidx_t *) malloc( (size_t) (p4est_ghost->mirror_proc_offsets[p4est_ghost->mpisize]) * sizeof(p4est_locidx_t) ); P4EST_ASSERT((*snd_leids) != NULL);
    for (j=0; j < p4est_ghost->proc_offsets[p4est_ghost->mpisize]; j++)
    {
        (*rcv_leids)[j] = p4est->local_num_quadrants + j + 1;
    }
    
    tree             = p4est_tree_array_index (p4est->trees,0);
    quadrants        = &(tree->quadrants);
    for (j=0; j < p4est_ghost->mirror_proc_offsets[p4est_ghost->mpisize]; j++)
    {
        q = p4est_quadrant_array_index(&p4est_ghost->mirrors, p4est_ghost->mirror_proc_mirrors[j]);    
        result = sc_array_bsearch (quadrants, q, p4est_quadrant_compare);    
        (*snd_leids)[j] = result + 1;
    }   
}

void F90_p8est_allocate_and_fill_cell_import_raw_arrays ( p8est_t        * p8est,
        p8est_ghost_t  * p8est_ghost,
        p4est_locidx_t * num_neighbours,
        p4est_locidx_t ** neighbour_ids,
        p4est_locidx_t ** rcv_ptrs,
        p4est_locidx_t ** rcv_leids,
        p4est_locidx_t ** snd_ptrs,
        p4est_locidx_t ** snd_leids)
{
    int i, j;
    p8est_tree_t * tree;
    sc_array_t * quadrants;
    ssize_t result;
    p8est_quadrant_t   *q;
    
    if ( *neighbour_ids ) free(*neighbour_ids);
    if ( *rcv_ptrs ) free(*rcv_ptrs);
    if ( *rcv_leids ) free(*rcv_leids);
    if ( *snd_ptrs ) free(*snd_ptrs);
    if ( *snd_leids ) free(*snd_leids);
    
    *num_neighbours = 0;
    for (i=0; i < p8est_ghost->mpisize; i++)
    {
        if ( p8est_ghost->proc_offsets[i+1]        - p8est_ghost->proc_offsets[i]        > 0 || 
                p8est_ghost->mirror_proc_offsets[i+1] - p8est_ghost->mirror_proc_offsets[i] > 0 )
        {
            (*num_neighbours)++;
        }
    }   
    *neighbour_ids = (p4est_locidx_t *) malloc( (size_t) (*num_neighbours)   * sizeof(p4est_locidx_t) ); P4EST_ASSERT((*neighbour_ids) != NULL);
    *rcv_ptrs      = (p4est_locidx_t *) malloc( (size_t) (*num_neighbours+1) * sizeof(p4est_locidx_t) ); P4EST_ASSERT((*rcv_ptrs)      != NULL);
    *snd_ptrs      = (p4est_locidx_t *) malloc( (size_t) (*num_neighbours+1) * sizeof(p4est_locidx_t) ); P4EST_ASSERT((*snd_ptrs)  != NULL);
    
    //Fill neighbour_ids, rcv_ptrs, snd_ptrs
    j=0;
    for (i=0; i < p8est_ghost->mpisize; i++)
    {
        if ( p8est_ghost->proc_offsets[i+1]        - p8est_ghost->proc_offsets[i]        > 0 || 
                p8est_ghost->mirror_proc_offsets[i+1] - p8est_ghost->mirror_proc_offsets[i] > 0 )
        {
            (*neighbour_ids)[j]= i+1;
            (*rcv_ptrs)[j]     = p8est_ghost->proc_offsets[i]+1;
            (*snd_ptrs)[j]     = p8est_ghost->mirror_proc_offsets[i]+1;
            j++;
        }
    }
    (*rcv_ptrs)[j] = p8est_ghost->proc_offsets[i]+1;
    (*snd_ptrs)[j] = p8est_ghost->mirror_proc_offsets[i]+1;
    
    *rcv_leids     = (p4est_locidx_t *) malloc( (size_t) (p8est_ghost->proc_offsets[p8est_ghost->mpisize]) * sizeof(p4est_locidx_t) ); P4EST_ASSERT((*rcv_leids) != NULL);
    *snd_leids     = (p4est_locidx_t *) malloc( (size_t) (p8est_ghost->mirror_proc_offsets[p8est_ghost->mpisize]) * sizeof(p4est_locidx_t) ); P4EST_ASSERT((*snd_leids) != NULL);
    for (j=0; j < p8est_ghost->proc_offsets[p8est_ghost->mpisize]; j++)
    {
        (*rcv_leids)[j] = p8est->local_num_quadrants + j + 1;
    }
    
    tree             = p8est_tree_array_index (p8est->trees,0);
    quadrants        = &(tree->quadrants);
    for (j=0; j < p8est_ghost->mirror_proc_offsets[p8est_ghost->mpisize]; j++)
    {
        q = p8est_quadrant_array_index(&p8est_ghost->mirrors, p8est_ghost->mirror_proc_mirrors[j]);    
        result = sc_array_bsearch (quadrants, q, p8est_quadrant_compare);    
        (*snd_leids)[j] = result + 1;
    }   
}

void F90_p4est_compute_migration_control_data (p4est_t   * p4est_old, 
                                               p4est_t   * p4est_new,
                                               int             * num_ranks, // How many processors involved?
                                               p4est_locidx_t ** lst_ranks, // Identifiers of processors involved from 1..P
                                               int            ** ptr_ranks, // Pointers to [start,end] of local_ids for each P in num_ranks
                                               p4est_locidx_t ** local_ids,
                                               p4est_locidx_t ** old2new)
{
    p4est_tree_t       *tree_old, *tree_new;
    p4est_quadrant_t   *q_old, *q_new;
    sc_array_t         *quadrants_old, *quadrants_new;
    int                old_quadrant_index, 
                       new_quadrant_index;
    
    p4est_locidx_t     my_rank;
    p4est_locidx_t     new_rank;
    
    p4est_locidx_t   * ranks_visited;
    p4est_locidx_t   * ranks_count;
    p4est_locidx_t   * ranks_lids;

            
    // Extract references to the first (and uniquely allowed) trees
    tree_old = p4est_tree_array_index (p4est_old->trees,0);
    tree_new = p4est_tree_array_index (p4est_new->trees,0);
    quadrants_old = &(tree_old->quadrants);
    quadrants_new = &(tree_new->quadrants);
    
    ranks_count   = (p4est_locidx_t *) malloc( (size_t) p4est_old->mpisize*sizeof(p4est_locidx_t) ); P4EST_ASSERT(ranks_count != NULL);
    ranks_visited = (p4est_locidx_t *) malloc( (size_t) p4est_old->mpisize*sizeof(p4est_locidx_t) ); P4EST_ASSERT(ranks_visited != NULL);
    ranks_lids    = (p4est_locidx_t *) malloc( (size_t) p4est_old->mpisize*sizeof(p4est_locidx_t) ); P4EST_ASSERT(ranks_lids != NULL);
    for (my_rank=0; my_rank < p4est_old->mpisize; my_rank++)
    {
      ranks_count[my_rank] = 0;
    }
    
    if ( *old2new ) free(*old2new);
    *old2new = (p4est_locidx_t *) malloc( (size_t) quadrants_old->elem_count*sizeof(p4est_locidx_t) ); P4EST_ASSERT((*old2new) != NULL);
    old_quadrant_index=0;
    while (old_quadrant_index < quadrants_old->elem_count)
    {
       (*old2new)[old_quadrant_index] = -1;    
       old_quadrant_index++;
    }
    
    // Calculate num_ranks
    *num_ranks = 0;
    my_rank    = p4est_old->mpirank;
    new_quadrant_index = 0;
    for (old_quadrant_index=0; old_quadrant_index < quadrants_old->elem_count;old_quadrant_index++)
    {
        q_old    = p4est_quadrant_array_index(quadrants_old, old_quadrant_index);        
        new_rank = p4est_comm_find_owner (p4est_new,0,q_old,0);
        if ( new_rank != my_rank ) 
        {
            if (ranks_count[new_rank] == 0)
            {
              ranks_visited[*num_ranks] = new_rank;
              ranks_lids[new_rank]   = *num_ranks;
              (*num_ranks)++;
            }
            ranks_count[new_rank]++;
            (*old2new)[old_quadrant_index]=0;
        }
        else {
            q_new    = p4est_quadrant_array_index(quadrants_new, new_quadrant_index);        
            while ( ! p4est_quadrant_is_equal(q_old,q_new) ) {
               new_quadrant_index++; 
               q_new    = p4est_quadrant_array_index(quadrants_new, new_quadrant_index);        
            }     
            (*old2new)[old_quadrant_index]=new_quadrant_index+1;
            new_quadrant_index++;
        }
    }
    
    if ( *lst_ranks ) free(*lst_ranks);
    *lst_ranks = (p4est_locidx_t *) malloc( (size_t) (*num_ranks)*sizeof(p4est_locidx_t) ); P4EST_ASSERT((*lst_ranks) != NULL);
    
    if ( *ptr_ranks ) free(*ptr_ranks);
    *ptr_ranks = (p4est_locidx_t *) malloc( (size_t) (*num_ranks+1)*sizeof(p4est_locidx_t) ); P4EST_ASSERT((*ptr_ranks) != NULL);
    
    
    (*ptr_ranks)[0]=1;
    for (my_rank=0; my_rank < *num_ranks; my_rank++)
    {
        (*lst_ranks)[my_rank]   = ranks_visited[my_rank]+1;
        (*ptr_ranks)[my_rank+1] = (*ptr_ranks)[my_rank] + ranks_count[ranks_visited[my_rank]] ;
    }

    free(ranks_count);
    free(ranks_visited);
    
    if ( *local_ids ) free(*local_ids);
    *local_ids = (p4est_locidx_t *) malloc( (size_t) ((*ptr_ranks)[(*num_ranks)]-1)*sizeof(p4est_locidx_t) );
        
    my_rank = p4est_old->mpirank;
    for (old_quadrant_index=0; old_quadrant_index < quadrants_old->elem_count; old_quadrant_index++)
    {
        q_old = p4est_quadrant_array_index(quadrants_old, old_quadrant_index);        
        new_rank = p4est_comm_find_owner(p4est_new,0,q_old,0);
        if ( new_rank != my_rank ) 
        {
            (*local_ids)[(*ptr_ranks)[ranks_lids[new_rank]]-1] = old_quadrant_index+1;
            (*ptr_ranks)[ranks_lids[new_rank]] = (*ptr_ranks)[ranks_lids[new_rank]] + 1;
        }
    }
    free(ranks_lids);
    
    for (my_rank=*num_ranks; my_rank >= 1; my_rank--) 
    {
        (*ptr_ranks)[my_rank] = (*ptr_ranks)[my_rank-1];
    }
    (*ptr_ranks)[0] = 1;
}

void F90_p8est_compute_migration_control_data (p8est_t   * p8est_old, 
        p8est_t   * p8est_new,
        int             * num_ranks, // How many processors involved?
        p4est_locidx_t ** lst_ranks, // Identifiers of processors involved from 1..P
        int            ** ptr_ranks, // Pointers to [start,end] of local_ids for each P in num_ranks
        p4est_locidx_t ** local_ids,
        p4est_locidx_t ** old2new)
{
    p8est_tree_t       *tree_old, *tree_new;
    p8est_quadrant_t   *q_old, *q_new;
    sc_array_t         *quadrants_old, *quadrants_new;
    int                old_quadrant_index, 
                       new_quadrant_index;
    
    p4est_locidx_t     my_rank;
    p4est_locidx_t     new_rank;
    
    p4est_locidx_t   * ranks_visited;
    p4est_locidx_t   * ranks_count;
    p4est_locidx_t   * ranks_lids;

    
    // Extract references to the first (and uniquely allowed) trees
    tree_old = p8est_tree_array_index (p8est_old->trees,0);
    tree_new = p8est_tree_array_index (p8est_new->trees,0);
    quadrants_old = &(tree_old->quadrants);
    quadrants_new = &(tree_new->quadrants);
    
    ranks_count   = (p4est_locidx_t *) malloc( (size_t) p8est_old->mpisize*sizeof(p4est_locidx_t) ); P4EST_ASSERT(ranks_count != NULL);
    ranks_visited = (p4est_locidx_t *) malloc( (size_t) p8est_old->mpisize*sizeof(p4est_locidx_t) ); P4EST_ASSERT(ranks_visited != NULL);
    ranks_lids    = (p4est_locidx_t *) malloc( (size_t) p8est_old->mpisize*sizeof(p4est_locidx_t) ); P4EST_ASSERT(ranks_lids != NULL);
    for (my_rank=0; my_rank < p8est_old->mpisize; my_rank++)
    {
        ranks_count[my_rank] = 0;
    }
    
    if ( *old2new ) free(*old2new);
    *old2new = (p4est_locidx_t *) malloc( (size_t) quadrants_old->elem_count*sizeof(p4est_locidx_t) ); P4EST_ASSERT((*old2new) != NULL);
    old_quadrant_index=0;
    while (old_quadrant_index < quadrants_old->elem_count)
    {
        (*old2new)[old_quadrant_index] = -1;    
        old_quadrant_index++;
    }
    
    // Calculate num_ranks
    *num_ranks = 0;
    my_rank    = p8est_old->mpirank;
    new_quadrant_index = 0;
    for (old_quadrant_index=0; old_quadrant_index < quadrants_old->elem_count;old_quadrant_index++)
    {
        q_old    = p8est_quadrant_array_index(quadrants_old, old_quadrant_index);        
        new_rank = p8est_comm_find_owner (p8est_new,0,q_old,0);
        if ( new_rank != my_rank ) 
        {
            if (ranks_count[new_rank] == 0)
            {
                ranks_visited[*num_ranks] = new_rank;
                ranks_lids[new_rank]   = *num_ranks;
                (*num_ranks)++;
            }
            ranks_count[new_rank]++;
            (*old2new)[old_quadrant_index]=0;
        }
        else {
            q_new    = p8est_quadrant_array_index(quadrants_new, new_quadrant_index);        
            while ( ! p8est_quadrant_is_equal(q_old,q_new) ) {
                new_quadrant_index++; 
                q_new    = p8est_quadrant_array_index(quadrants_new, new_quadrant_index);        
            }     
            (*old2new)[old_quadrant_index]=new_quadrant_index+1;
            new_quadrant_index++;
        }
    }
    
    if ( *lst_ranks ) free(*lst_ranks);
    *lst_ranks = (p4est_locidx_t *) malloc( (size_t) (*num_ranks)*sizeof(p4est_locidx_t) ); P4EST_ASSERT((*lst_ranks) != NULL);
    
    if ( *ptr_ranks ) free(*ptr_ranks);
    *ptr_ranks = (p4est_locidx_t *) malloc( (size_t) (*num_ranks+1)*sizeof(p4est_locidx_t) ); P4EST_ASSERT((*ptr_ranks) != NULL);
    
    
    (*ptr_ranks)[0]=1;
    for (my_rank=0; my_rank < *num_ranks; my_rank++)
    {
        (*lst_ranks)[my_rank]   = ranks_visited[my_rank]+1;
        (*ptr_ranks)[my_rank+1] = (*ptr_ranks)[my_rank] + ranks_count[ranks_visited[my_rank]] ;
    }

    free(ranks_count);
    free(ranks_visited);
    
    if ( *local_ids ) free(*local_ids);
    *local_ids = (p4est_locidx_t *) malloc( (size_t) ((*ptr_ranks)[(*num_ranks)]-1)*sizeof(p4est_locidx_t) );
    
    my_rank = p8est_old->mpirank;
    for (old_quadrant_index=0; old_quadrant_index < quadrants_old->elem_count; old_quadrant_index++)
    {
        q_old = p8est_quadrant_array_index(quadrants_old, old_quadrant_index);        
        new_rank = p8est_comm_find_owner(p8est_new,0,q_old,0);
        if ( new_rank != my_rank ) 
        {
            (*local_ids)[(*ptr_ranks)[ranks_lids[new_rank]]-1] = old_quadrant_index+1;
            (*ptr_ranks)[ranks_lids[new_rank]] = (*ptr_ranks)[ranks_lids[new_rank]] + 1;
        }
    }
    free(ranks_lids);
    
    for (my_rank=*num_ranks; my_rank >= 1; my_rank--) 
    {
        (*ptr_ranks)[my_rank] = (*ptr_ranks)[my_rank-1];
    }
    (*ptr_ranks)[0] = 1;
}




void F90_p4est_fill_proc_offsets_and_ghost_gids_remote_neighbours( p4est_ghost_t  * p4est_ghost,
                                                                   p4est_locidx_t * proc_offsets, 
                                                                   p4est_locidx_t * ghost_gids_remote_neighbours )
{
  int i;
    p4est_quadrant_t * ghost_quadrants = (p4est_quadrant_t *) p4est_ghost->ghosts.array;
    for (i=0; i < p4est_ghost->ghosts.elem_count; i++)
    {
      ghost_gids_remote_neighbours[i] = (ghost_quadrants[i].p.piggy3.local_num+1) ;
    }
    for (i=0; i <= p4est_ghost->mpisize; i++)
    {
        proc_offsets[i] = p4est_ghost->proc_offsets[i]+1; 
    } 
}

void F90_p8est_fill_proc_offsets_and_ghost_gids_remote_neighbours( p8est_ghost_t  * p8est_ghost,
        p4est_locidx_t * proc_offsets, 
        p4est_locidx_t * ghost_gids_remote_neighbours )
{
  int i; 
    p8est_quadrant_t * ghost_quadrants = (p8est_quadrant_t *) p8est_ghost->ghosts.array;
    for (i=0; i < p8est_ghost->ghosts.elem_count; i++)
    {
        ghost_gids_remote_neighbours[i] = (ghost_quadrants[i].p.piggy3.local_num+1) ;
    }
    for (i=0; i <= p8est_ghost->mpisize; i++)
    {
        proc_offsets[i] = p8est_ghost->proc_offsets[i]+1; 
    } 
}

void F90_p4est_quadrant_face_neighbor(p4est_qcoord_t   q_x,
                                      p4est_qcoord_t   q_y,
                                      int8_t       q_level,
                                      int             face,
                                      p4est_qcoord_t * n_x,
                                      p4est_qcoord_t * n_y,
                                      int8_t         * n_level)
{
    p4est_quadrant_t q;
    p4est_quadrant_t r;
    q.x      = q_x;
    q.y      = q_y;
    q.level  = q_level;
    p4est_quadrant_face_neighbor(&q,face,&r);
    *n_x     = r.x;
    *n_y     = r.y;
    *n_level = r.level;
}

void F90_p8est_quadrant_face_neighbor(p4est_qcoord_t   q_x,
                                      p4est_qcoord_t   q_y,
                                      p4est_qcoord_t   q_z,
                                      int8_t       q_level,
                                      int             face,
                                      p4est_qcoord_t * n_x,
                                      p4est_qcoord_t * n_y,
                                      p4est_qcoord_t * n_z,
                                      int8_t         * n_level)
{
    p8est_quadrant_t q;
    p8est_quadrant_t r;
    q.x      = q_x;
    q.y      = q_y;
    q.z      = q_z;
    q.level  = q_level;
    p8est_quadrant_face_neighbor(&q,face,&r);
    *n_x     = r.x;
    *n_y     = r.y;
    *n_z     = r.z;
    *n_level = r.level;
}

void F90_p8est_quadrant_edge_neighbor(p4est_qcoord_t   q_x,
                                      p4est_qcoord_t   q_y,
                                      p4est_qcoord_t   q_z,
                                      int8_t       q_level,
                                      int             edge,
                                      p4est_qcoord_t * n_x,
                                      p4est_qcoord_t * n_y,
                                      p4est_qcoord_t * n_z,
                                      int8_t         * n_level)
{
    p8est_quadrant_t q;
    p8est_quadrant_t r;
    q.x      = q_x;
    q.y      = q_y;
    q.z      = q_z;
    q.level  = q_level;
    p8est_quadrant_edge_neighbor(&q,edge,&r);
    *n_x     = r.x;
    *n_y     = r.y;
    *n_z     = r.z;
    *n_level = r.level;
}

int F90_p4est_bsearch (p4est_t * p4est, 
                       p4est_qcoord_t q_x,
                       p4est_qcoord_t q_y,
                       int8_t q_level)
{
    p4est_quadrant_t q;
    ssize_t result;
    p4est_tree_t * tree;
    sc_array_t * quadrants;
    
    tree = p4est_tree_array_index (p4est->trees,0);
    quadrants = &(tree->quadrants);
    
    q.x      = q_x;
    q.y      = q_y;
    q.level  = q_level;
    result = sc_array_bsearch (quadrants, &q, p4est_quadrant_compare);
    return (result < 0) ? ((int) (-1)) : ((int) result);
}

int F90_p8est_bsearch (p8est_t * p8est, 
                       p4est_qcoord_t q_x,
                       p4est_qcoord_t q_y,
                       p4est_qcoord_t q_z,
                       int8_t q_level)
{
    p8est_quadrant_t q;
    ssize_t result;
    p8est_tree_t * tree;
    sc_array_t * quadrants;
    
    tree = p8est_tree_array_index (p8est->trees,0);
    quadrants = &(tree->quadrants);
    
    q.x      = q_x;
    q.y      = q_y;
    q.z      = q_z;
    q.level  = q_level;
    result = sc_array_bsearch (quadrants, &q, p8est_quadrant_compare);
    return (result < 0) ? ((int) (-1)) : ((int) result);
}

int F90_p4est_ghost_bsearch (p4est_ghost_t * ghost, 
                             p4est_qcoord_t   q_x,
                             p4est_qcoord_t   q_y,
                             int8_t       q_level)
{
    p4est_quadrant_t q;
    q.x      = q_x;
    q.y      = q_y;
    q.level  = q_level;
    return (int) p4est_ghost_bsearch (ghost,
                                      (int) -1,
                                      (p4est_topidx_t) -1, 
                                      &q);
}

int F90_p8est_ghost_bsearch (p8est_ghost_t * ghost, 
                             p4est_qcoord_t   q_x,
                             p4est_qcoord_t   q_y,
                             p4est_qcoord_t   q_z,
                             int8_t       q_level)
{
   p8est_quadrant_t q;
   q.x      = q_x;
   q.y      = q_y;
   q.z      = q_z;
   q.level  = q_level;
   return (int) p8est_ghost_bsearch (ghost,
                                     (int) -1,
                                     (p4est_topidx_t) -1, 
                                     &q);
}

//void p4_savemesh ( char    filename[],
//                   p4est_t *p4est)
//{
//  p4est_t              *p4est2;
//  p4est_connectivity_t *conn2 = NULL;
//  int ip,ic;
//  
//  p4est_save(filename,p4est,0);
//  p4est2=p4est_load_ext(filename,mpicomm,0,0,1,0,NULL,&conn2);
//  // TODO: optional check
//  ic = p4est_connectivity_is_equal(p4est->connectivity,conn2);
//  ip = p4est_is_equal(p4est,p4est2,0);
//  printf("Conn, p4est %i %i \n",ic,ip);
//  p4est_destroy(p4est2);
//  p4est_connectivity_destroy(conn2);
//}

#endif
