function fc = write_conversion_i90_file(file_name, num_quad_faces, face_in_quad_to_trian, face_in_quad_to_face_in_trian )

% Falta el num d'intersection points

% Open file
fid = fopen(file_name,'w');


fprintf(fid,'! Copyright (C) 2014 Santiago Badia, Alberto F. Martín and Javier Principe\n');
fprintf(fid,'!\n');
fprintf(fid,'! This file is part of FEMPAR (Finite Element Multiphysics PARallel library)\n');
fprintf(fid,'!\n');
fprintf(fid,'! FEMPAR is free software: you can redistribute it and/or modify\n');
fprintf(fid,'! it under the terms of the GNU General Public License as published by\n');
fprintf(fid,'! the Free Software Foundation, either version 3 of the License, or\n');
fprintf(fid,'! (at your option) any later version.\n');
fprintf(fid,'!\n');
fprintf(fid,'! FEMPAR is distributed in the hope that it will be useful,\n');
fprintf(fid,'! but WITHOUT ANY WARRANTY; without even the implied warranty of\n');
fprintf(fid,'! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\n');
fprintf(fid,'! GNU General Public License for more details.\n');
fprintf(fid,'!\n');
fprintf(fid,'! You should have received a copy of the GNU General Public License\n');
fprintf(fid,'! along with FEMPAR. If not, see <http://www.gnu.org/licenses/>.\n');
fprintf(fid,'!\n');
fprintf(fid,'! Additional permission under GNU GPL version 3 section 7\n');
fprintf(fid,'!\n');
fprintf(fid,'! If you modify this Program, or any covered work, by linking or combining it\n');
fprintf(fid,'! with the Intel Math Kernel Library and/or the Watson Sparse Matrix Package\n');
fprintf(fid,'! and/or the HSL Mathematical Software Library (or a modified version of them),\n');
fprintf(fid,'! containing parts covered by the terms of their respective licenses, the\n');
fprintf(fid,'! licensors of this Program grant you additional permission to convey the\n');
fprintf(fid,'! resulting work.\n');
fprintf(fid,'!\n');
fprintf(fid,'!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');


fprintf(fid,'\n');

fprintf(fid,'! Look up tables for QUA4 to TRI3 conversion');
fprintf(fid,'! This file has been automatically generated in Matlab using the script:\n');

aux = pwd;
k = strfind(aux,'Driver');
aux = aux(k:end);
fprintf(fid,'! %s/do_tables.sh\n',aux);
fprintf(fid,'! Do not modify this file by hand! Modify and use the script!\n');

fprintf(fid,'\n');

% fprintf(fid,'integer(ip), parameter :: MC_%s_NUM_CASES = %d\n',elem_type,mc_ncases);
% fprintf(fid,'integer(ip), parameter :: MC_%s_MAX_NUM_SUBCELLS = %d\n',elem_type,mc_max_sub_cells);
% fprintf(fid,'integer(ip), parameter :: MC_%s_MAX_NUM_SUBFACES = %d\n',elem_type,mc_max_sub_faces);
% fprintf(fid,'integer(ip), parameter :: MC_%s_NUM_FACETS = %d\n',elem_type,mc_num_facets);
% fprintf(fid,'integer(ip), parameter :: MC_%s_MAX_NUM_FITTED_SUB_FACETS_IN_FACET = %d\n',elem_type,mc_max_sub_vefs);
% fprintf(fid,'integer(ip), parameter :: MC_%s_MAX_NUM_CUT_EDGES = %d\n',elem_type,mc_max_num_cut_edges);
% fprintf(fid,'integer(ip), parameter :: MC_%s_NUM_NODES_PER_SUBCELL = %d\n',elem_type,mc_num_nodes_per_subcell);
% fprintf(fid,'integer(ip), parameter :: MC_%s_NUM_NODES_PER_SUBFACE = %d\n',elem_type,mc_num_nodes_per_subface);


% fprintf(fid,['integer(ip), parameter :: MC_%s_NUM_SUBCELLS_PER_CASE(%d) = ' endaux],elem_type,mc_ncases);



% switch elem_type
%     case 'HEX8'
%         width = 16;
%     otherwise
%         width = round(mc_ncases/2);
% end

% write_long_vector(fid,mc_num_sub_cells_per_case,width,0);
% fprintf(fid,'\n');
width = round(num_quad_faces/2);

fprintf(fid,['integer(ip), parameter :: MC_FACE_IN_QUAD_TO_TRIAN(%d) = '], num_quad_faces);

write_long_vector(fid,face_in_quad_to_trian,width,0);
fprintf(fid,'\n');

fprintf(fid,['integer(ip), parameter :: MC_FACE_IN_QUAD_TO_FACE_IN_TRIAN(%d) = '], num_quad_faces);

write_long_vector(fid,face_in_quad_to_face_in_trian,width,0);
fprintf(fid,'\n');

fc = fclose(fid);

function write_long_variable_3D(fid,mc_data,width,varname,d1,d2,d3)


if d3 == 256
    if d1 == 4
        aux = 9;
    else
        aux= 9*5;
    end
    
    bunch_cases = AUX_compute_cell_bunch(256,aux);
    
    disp(' ')
    
    for ibunch = 1:length(bunch_cases)
        d3bunch = length(bunch_cases{ibunch});
        fprintf(fid,'integer(ip), parameter :: %s_BL%d(%d,%d,%d) = &\nreshape( ',varname,ibunch,d1,d2,d3bunch);
        data = permute(mc_data(bunch_cases{ibunch},:,:),[3 2 1]);
        write_long_vector(fid,data,width,10);
        fprintf(fid,' , [%d,%d,%d] )\n',d1,d2,d3bunch);
        varname_fempar = lower(strrep(varname,'MC_HEX8','MC_TABLE'));
        fprintf('this%%%s(:,:,%d:%d) = %s_BL%d(:,:,:)\n',varname_fempar,bunch_cases{ibunch}(1),bunch_cases{ibunch}(end),varname,ibunch)
    end
    
else
    fprintf(fid,'integer(ip), parameter :: %s(%d,%d,%d) = &\nreshape( ',varname,d1,d2,d3);
    data = permute(mc_data,[3 2 1]);
    write_long_vector(fid,data,width,10);
    fprintf(fid,' , [%d,%d,%d] )\n',d1,d2,d3);
end


function write_long_variable_4D(fid,mc_data,width,varname,d1,d2,d3,d4)

if d4 == 256
    aux = 9;
    bunch_cases = AUX_compute_cell_bunch(256,aux);
    disp(' ')
    
    for ibunch = 1:length(bunch_cases)
        d4bunch = length(bunch_cases{ibunch});
        fprintf(fid,'integer(ip), parameter :: %s_BL%d(%d,%d,%d,%d) = &\nreshape( ',varname,ibunch,d1,d2,d3,d4bunch);
        data = permute(mc_data(bunch_cases{ibunch},:,:,:),[4 3 2 1]);
        write_long_vector(fid,data,width,10);
        fprintf(fid,' , [%d,%d,%d,%d] )\n',d1,d2,d3,d4bunch);
        varname_fempar = lower(strrep(varname,'MC_HEX8','MC_TABLE'));
        fprintf('this%%%s(:,:,:,%d:%d) = %s_BL%d(:,:,:,:)\n',varname_fempar,bunch_cases{ibunch}(1),bunch_cases{ibunch}(end),varname,ibunch)
        
    end
    
else
    
    
    fprintf(fid,'integer(ip), parameter :: %s(%d,%d,%d,%d) = &\nreshape( ',varname,d1,d2,d3,d4);
    data = permute(mc_data,[4 3 2 1]);
    write_long_vector(fid,data,width,10);
    fprintf(fid,' , [%d,%d,%d,%d] )\n',d1,d2,d3,d4);
    
end



function write_long_variable_2D(fid,mc_data,width,varname,d1,d2)


if d2 == 256
    bunch_cases = AUX_compute_cell_bunch(256,9*4);
    
    disp(' ')
    
    for ibunch = 1:length(bunch_cases)
        d2bunch = length(bunch_cases{ibunch});
        fprintf(fid,'integer(ip), parameter :: %s_BL%d(%d,%d) = &\nreshape( ',varname,ibunch,d1,d2bunch);
        data = (mc_data(bunch_cases{ibunch},:)).';
        write_long_vector(fid,data,width,10);
        fprintf(fid,' , [%d,%d] )\n',d1,d2bunch);
        varname_fempar = lower(strrep(varname,'MC_HEX8','MC_TABLE'));
        fprintf('this%%%s(:,%d:%d) = %s_BL%d(:,:)\n',varname_fempar,bunch_cases{ibunch}(1),bunch_cases{ibunch}(end),varname,ibunch)
    end
    
else
    fprintf(fid,'integer(ip), parameter :: %s(%d,%d) = &\nreshape( ',varname,d1,d2);
    data = mc_data.';
    write_long_vector(fid,data,width,10);
    fprintf(fid,' , [%d,%d] )\n',d1,d2);
    
end







function write_long_vector(fid,data,width,skip)



cell_bunch = AUX_compute_cell_bunch(numel(data),width);

if isempty(cell_bunch{end})
    cell_bunch = cell_bunch(1:end-1);
end

for ic = 1:length(cell_bunch)
    
    if ic > 1
        fprintf(fid,['%' num2str(skip) 's'],' ');
    else
        fprintf(fid,'[');
    end
    
    for jc = 1:length(cell_bunch{ic})
        if ic == length(cell_bunch) &&  jc == length(cell_bunch{ic})
            str_aux = '%2d';
        else
            str_aux = '%2d,';
        end
        fprintf(fid,str_aux,data(cell_bunch{ic}(jc)));
    end
    
    if ic == length(cell_bunch)
        fprintf(fid,' ]');
    else
        fprintf(fid,' &\n');
    end
end

function cell_bunch = AUX_compute_cell_bunch(nbel,nbel_bunch)

n = floor(nbel/nbel_bunch);
cell_bunch = cell(n+1,1);
aux_1 = 1:nbel_bunch;
for i = 1:n+1
    if i <=n
        cell_bunch{i} =  aux_1+nbel_bunch*(i-1);
    else
        cell_bunch{i} = nbel_bunch*n+1:nbel;
    end
end
